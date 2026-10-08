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

if __name__=='__main__':unittest.main()
