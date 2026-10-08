"""Production gates: protect assets and prevent false acceptance."""
import importlib.util,json,tempfile,unittest
from pathlib import Path
from types import SimpleNamespace
spec=importlib.util.spec_from_file_location('pipeline',Path(__file__).parents[1]/'pet_pipeline.py')
p=importlib.util.module_from_spec(spec);spec.loader.exec_module(p)

class ProductionGates(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
        (self.root/'review').mkdir();(self.root/'review/pet.glb').write_bytes(b'asset-fixture')
        p.write(self.root/'manifest.json',{'status':'technical_pass_pending_visual'})
        p.write(self.root/'validation.json',{'passed':True})
        self.evidence={'glb_sha256':p.sha(self.root/'review/pet.glb'),'reviewer':'test',
                       'notes':'Synthetic gate test, not an actual art approval.',
                       'checks':{k:True for k in p.CHECKS}}
    def tearDown(self):self.temp.cleanup()
    def accept(self):
        evidence=self.root/'evidence.json';p.write(evidence,self.evidence)
        p.review(SimpleNamespace(run=self.root,evidence=evidence,accept=True))
    def test_rejects_review_for_different_asset(self):
        self.evidence['glb_sha256']='wrong'
        with self.assertRaises(ValueError):self.accept()
    def test_rejects_missing_visual_check(self):
        del self.evidence['checks']['two_front_paws_grounded']
        with self.assertRaises(ValueError):self.accept()
    def test_rejects_failed_technical_validation(self):
        p.write(self.root/'validation.json',{'passed':False})
        with self.assertRaises(ValueError):self.accept()
    def test_acceptance_still_requires_studio(self):
        self.accept()
        self.assertEqual(p.read(self.root/'manifest.json')['status'],'qa_accepted_awaiting_studio')
    def test_valid_recipe_resolves_reference_paths(self):
        cfg=p.configure(p.HERE/'configs/ocelot.json',self.root,self.root/'new')
        self.assertTrue(Path(cfg['approved_front_render']).is_absolute())
        self.assertTrue(Path(cfg['approved_model']).is_file())
    def test_roster_has_unique_species_and_five_slots_per_family(self):
        rows=p.read(p.HERE/'roster.json')['pets']
        self.assertEqual(len(rows),250)
        self.assertEqual(len({r['species'] for r in rows}),250)
        self.assertEqual(len({r['pet_id'] for r in rows}),250)
        from collections import Counter
        self.assertEqual(set(Counter(r['biome'] for r in rows).values()),{25})
        self.assertEqual(set(Counter(r['proposed_family_id'] for r in rows).values()),{5})
        # Registration is now real; require evidence instead of freezing all
        # production slots in the original unregistered planning state.
        for row in rows:
            if not row['registered']:
                self.assertIsNone(row['model_asset_id'])
                continue
            self.assertTrue(row['production_template'].startswith('ReplicatedStorage.PetAssets.'))
            self.assertTrue(row['confirmed_family_id'].startswith(row['biome']+'_'))
            self.assertTrue(row['glb'])
            self.assertTrue(row['model_assets'])
            for asset in row['model_assets']:
                self.assertGreater(int(asset['mesh_id']),0)
                self.assertGreater(int(asset['texture_id']),0)
            evidence=p.read(p.HERE/row['registration_evidence'])
            self.assertTrue(evidence['passed'])
            self.assertEqual(evidence['pet'],row['pet_id'])
            self.assertEqual(evidence['family'],row['confirmed_family_id'])
            self.assertEqual(evidence['base_weight'],row['base_weight_kg'])
            self.assertEqual(evidence['base_income'],row['base_income'])
    def test_vendored_source_matches_lock(self):
        for name,digest in p.read(p.HERE/'pipeline-lock.json')['vendor_files'].items():
            self.assertEqual(p.sha(p.HERE/name),digest,name)
    def test_insufficient_commit_blocks_even_with_free_vram(self):
        with self.assertRaisesRegex(RuntimeError, 'free_commit'):
            p.check_hardware({'free_physical':8*1024**3,'free_commit':2*1024**3,
                              'gpu_probe_exit_code':0,'gpu':'RTX 3060, 12288, 10000'})
    def test_wrong_gpu_or_failed_probe_blocks(self):
        for hardware in ({'gpu_probe_exit_code':1,'gpu':''},
                         {'gpu_probe_exit_code':0,'gpu':'RTX 3060, 12288, 1000'}):
            with self.assertRaises(RuntimeError): p.check_hardware(hardware)

if __name__=='__main__':unittest.main()
