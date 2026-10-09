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
    def test_old_commit_admission_is_no_longer_sufficient(self):
        with self.assertRaisesRegex(RuntimeError, 'free_commit'):
            p.check_hardware({'free_physical':8*1024**3,'free_commit':8*1024**3,
                              'gpu_probe_exit_code':0,'gpu':'RTX 3060, 12288, 10000'})
    def test_missing_memory_measurements_fail_closed(self):
        with self.assertRaisesRegex(RuntimeError, 'Missing free_physical'):
            p.check_hardware({'gpu_probe_exit_code':0,'gpu':'RTX 3060, 12288, 10000'})
    def test_just_below_current_commit_admission_blocks(self):
        with self.assertRaisesRegex(RuntimeError, 'free_commit'):
            p.check_hardware({'free_physical':7239262208,'free_commit':p.resource_policy()['commit_gib']*1024**3-1,
                              'gpu_probe_exit_code':0,'gpu':'RTX 3060, 12288, 11922'})
    def test_sufficient_memory_admits(self):
        p.check_hardware({'free_physical':8*1024**3,'free_commit':p.resource_policy()['commit_gib']*1024**3,
                          'gpu_probe_exit_code':0,'gpu':'RTX 3060, 12288, 10000'})
    def test_authorized_ten_gib_trial_boundary_is_system_commit(self):
        from unittest.mock import patch
        policy=dict(p.resource_policy(),commit_gib=10)
        hardware={'free_physical':4*1024**3,'free_commit':10*1024**3,
                  'gpu_probe_exit_code':0,'gpu':'RTX 3060, 12288, 7168'}
        with patch.object(p,'resource_policy',return_value=policy):
            p.check_hardware(hardware)
            with self.assertRaisesRegex(RuntimeError,'free_commit'):
                p.check_hardware(dict(hardware,free_commit=10*1024**3-1))
            with self.assertRaisesRegex(RuntimeError,'VRAM'):
                p.check_hardware(dict(hardware,gpu='RTX 3060, 12288, 7167'))
    def test_trial_emergency_floor_is_below_admission(self):
        policy=p.resource_policy()
        self.assertEqual(policy['stop_commit_gib'],4)
        self.assertEqual(policy['stop_ram_gib'],1)
        self.assertGreater(policy['commit_gib'],policy['stop_commit_gib'])
    def test_generation_lock_excludes_another_process_and_recovers(self):
        import subprocess,sys
        command=[sys.executable,'-c',
                 'from pet_pipeline import generation_lock; import sys; '
                 'exec("with generation_lock(sys.argv[1]): pass")',str(self.root)]
        with p.generation_lock(self.root):
            blocked=subprocess.run(command,cwd=p.HERE,capture_output=True,text=True)
            self.assertNotEqual(blocked.returncode,0)
            self.assertIn('Another generation',blocked.stderr)
        allowed=subprocess.run(command,cwd=p.HERE,capture_output=True,text=True)
        self.assertEqual(allowed.returncode,0,allowed.stderr)
    def test_wrong_gpu_or_failed_probe_blocks(self):
        for hardware in ({'gpu_probe_exit_code':1,'gpu':''},
                         {'gpu_probe_exit_code':0,'gpu':'RTX 3060, 12288, 1000'}):
            hardware.update(free_physical=8*1024**3,free_commit=p.resource_policy()['commit_gib']*1024**3)
            with self.assertRaises(RuntimeError): p.check_hardware(hardware)
    def test_deferred_species_cannot_start_inference(self):
        with self.assertRaisesRegex(RuntimeError,'Species deferred'):
            p.check_attempt_budget({'pet_id':'JungleTapir'},self.root,
                {'deferred_species':{'JungleTapir':'Art QA failed'},'max_fresh_inferences_per_unapproved_species':3})
    def test_retry_limit_counts_inference_not_saved_mesh_trials(self):
        policy={'max_fresh_inferences_per_unapproved_species':2}
        for index,fresh in enumerate([True,False,True]):
            run=self.root/'outputs'/str(index);(run/'generated').mkdir(parents=True)
            p.write(run/'effective-config.json',{'pet_id':'JungleRedPanda'})
            p.write(run/'generated/generation.json',{'fresh_inference':fresh})
            if index==1:p.check_attempt_budget({'pet_id':'JungleRedPanda'},self.root,policy)
        with self.assertRaisesRegex(RuntimeError,'reached 2/2'):
            p.check_attempt_budget({'pet_id':'JungleRedPanda'},self.root,policy)
        p.check_attempt_budget({'pet_id':'JungleCoati'},self.root,policy)
    def test_failed_inference_worker_uses_retry_budget(self):
        run=self.root/'outputs/failed';run.mkdir(parents=True)
        p.write(run/'effective-config.json',{'pet_id':'JungleRedPanda'})
        (run/'generate.log').write_text('Loading model; process interrupted')
        with self.assertRaisesRegex(RuntimeError,'reached 1/1'):
            p.check_attempt_budget({'pet_id':'JungleRedPanda'},self.root,
                {'max_fresh_inferences_per_unapproved_species':1})

    def test_documented_preprocessing_retry_is_still_bounded(self):
        policy={'max_fresh_inferences_per_unapproved_species':3,
                'inference_budget_overrides':{'JungleRedPanda':{'limit':4,'reason':'Reviewed foreground lost tail'}}}
        for index in range(4):
            run=self.root/'outputs'/str(index);run.mkdir(parents=True)
            p.write(run/'effective-config.json',{'pet_id':'JungleRedPanda'})
            (run/'generate.log').write_text('fresh inference')
            if index==2:p.check_attempt_budget({'pet_id':'JungleRedPanda'},self.root,policy)
        with self.assertRaisesRegex(RuntimeError,'reached 4/4'):
            p.check_attempt_budget({'pet_id':'JungleRedPanda'},self.root,policy)

if __name__=='__main__':unittest.main()
