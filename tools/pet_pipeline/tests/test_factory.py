"""Destructive cleanup and process safety tested with synthetic owned fixtures."""
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).parents[1]))
import pet_pipeline as p
import factory_storage as s
import factory as f

GIB = 1024**3
HEALTHY = {'free_physical':8*GIB, 'free_commit':20*GIB,
           'free_disk_bytes':100*GIB, 'gpu_probe_exit_code':0, 'gpu':'RTX 3060, 12288, 10000'}


class StorageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.run_id, self.job = s.new_job(self.root, 'JungleCoati')
        for relative in s.DISPOSABLE | {'work/review/pet.glb', 'work/review/pet.blend', 'tmp/owned.tmp'}:
            path = self.job/relative; path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(relative.encode())
        self.record = s.inventory(self.root, self.run_id)
    def tearDown(self): self.temp.cleanup()
    def mock_verified(self):
        return patch.object(s, 'validate_receipt', return_value=(self.job, self.record))
    def test_unverified_work_cannot_be_deleted(self):
        with self.assertRaises(ValueError): s.cleanup(self.root, self.run_id, {})
        self.assertTrue((self.job/'work/generated/raw.glb').exists())
    def test_upload_only_does_not_authorize_cleanup(self):
        receipt = {'run_id':self.run_id, 'pet_id':'JungleCoati', 'roblox_assets':[{'mesh_id':123,'texture_id':456}]}
        with self.assertRaisesRegex(ValueError, 'complete Studio QA'):
            s.cleanup(self.root, self.run_id, receipt)
    def test_only_inventoried_disposables_deleted_and_restart_safe(self):
        (self.job/'tmp/later.tmp').write_bytes(b'not inventoried')
        with self.mock_verified():
            first = s.cleanup(self.root, self.run_id, {'commit':'a'*40})
            second = s.cleanup(self.root, self.run_id, {'commit':'a'*40})
        self.assertEqual(first, second)
        self.assertGreater(first['deleted_bytes'], 0)
        self.assertTrue((self.job/'work/review/pet.glb').exists())
        self.assertTrue((self.job/'work/review/pet.blend').exists())
        self.assertTrue((self.job/'tmp/later.tmp').exists())
        self.assertFalse((self.job/'work/generated/raw.glb').exists())
    def test_changed_disposable_preserves_entire_batch(self):
        (self.job/'work/generated/raw.glb').write_bytes(b'changed')
        with self.mock_verified(), self.assertRaisesRegex(ValueError, 'changed'):
            s.cleanup(self.root, self.run_id, {'commit':'a'*40})
        self.assertTrue((self.job/'tmp/owned.tmp').exists())
    def test_manifest_cannot_nominate_approved_files(self):
        self.record['disposable']['work/review/pet.glb'] = {'sha256':p.sha(self.job/'work/review/pet.glb'), 'bytes':1}
        with self.mock_verified(), self.assertRaisesRegex(ValueError, 'non-disposable'):
            s.cleanup(self.root, self.run_id, {'commit':'a'*40})
    def test_traversal_absolute_and_git_paths_refused(self):
        for relative in ('../escape', str(self.root.resolve())):
            with self.assertRaises(ValueError): s.safe_path(self.job, relative)
        (self.job/'.git').write_text('gitdir: elsewhere')
        with self.assertRaisesRegex(ValueError, 'Git checkout'): s.safe_path(self.job, 'work/review/pet.glb')
    def test_hardlink_refused(self):
        os.link(self.job/'work/review/pet.glb', self.job/'tmp/linked.glb')
        with self.assertRaisesRegex(ValueError, 'Hard-linked'): s.inventory(self.root, self.run_id)
    def test_junction_refused(self):
        if os.name != 'nt': self.skipTest('Windows junction fixture')
        target = self.root/'outside'; target.mkdir()
        link = self.job/'tmp/junction'
        # No deletion/move is composed across shells. Remove only the junction
        # itself through pathlib after the path guard refuses it.
        result = subprocess.run(['cmd','/c','mklink','/J',str(link),str(target)], capture_output=True)
        if result.returncode: self.skipTest('Junction creation unavailable')
        try:
            with self.assertRaisesRegex(ValueError, 'reparse'): s.safe_path(self.job, 'tmp/junction/file')
        finally: link.rmdir()
    def test_unknown_legacy_job_is_never_adopted(self):
        with self.assertRaises(ValueError): s.owner(self.root, 'legacy-output')
    def test_low_disk_only_attempts_verified_reclaim(self):
        usage = type('Usage', (), {'free':1})()
        with patch.object(s.shutil, 'disk_usage', return_value=usage), patch.object(s, 'reclaim_verified', return_value=[]) as clean:
            with self.assertRaisesRegex(RuntimeError, 'Disk gate'): s.disk_gate(self.root)
            clean.assert_called_once()
    def test_missing_archive_or_missing_qa_blocks(self):
        receipt = {'run_id':self.run_id, 'pet_id':'JungleCoati',
                   'checks':{name:True for name in s.QA_CHECKS},
                   'roblox_assets':[{'mesh_id':123,'texture_id':456}]}
        with self.assertRaises(FileNotFoundError): s.cleanup(self.root, self.run_id, receipt)
        for check in s.QA_CHECKS:
            bad = dict(receipt, checks={name:True for name in s.QA_CHECKS if name != check})
            with self.assertRaises(ValueError): s.cleanup(self.root, self.run_id, bad)

    def receipt_fixture(self):
        texture=self.job/'work/projected/basecolor.png'; texture.write_bytes(b'final texture')
        reference=self.root/'reference.png'; reference.write_bytes(b'reference')
        p.write(self.job/'work/effective-config.json', {'concept_image':str(reference), 'style_references':[str(reference)]})
        p.write(self.job/'work/validation.json', {'passed':True})
        p.write(self.job/'work/visual-review.json', {'decision':'accepted'})
        p.write(self.job/'work/manifest.json', {'visual_qa':'accepted'})
        # Unit fixtures must not depend on the host temp volume's free space.
        with patch.object(s.shutil, 'disk_usage', return_value=type('Usage', (), {'free':100*GIB})()):
            preservation=s.archive(self.root, self.run_id)
        receipt={'run_id':self.run_id, 'pet_id':'JungleCoati',
                 'checks':{name:True for name in s.QA_CHECKS}, 'roblox_assets':[{'mesh_id':123,'texture_id':456}],
                 'preservation_sha256':p.sha(preservation), 'glb_sha256':p.sha(self.job/'work/review/pet.glb'),
                 'commit':'a'*40, 'receipt_path':'qa/receipt.json',
                 'evidence_files':{'qa/studio.json':__import__('hashlib').sha256(b'studio evidence fixture').hexdigest()}}
        def git(command, **kwargs):
            args=command[3:]
            if args[0]=='remote':return b'https://github.com/wardmaciah-web/Animal-Kingdom.git\n'
            if args[0]=='ls-remote':return ('a'*40+'\trefs/heads/main\n').encode()
            if args[0]=='merge-base':return b''
            if args[1].endswith('qa/studio.json'):return b'studio evidence fixture'
            return json.dumps({k:v for k,v in receipt.items() if k!='commit'}).encode()
        return receipt, preservation.parent, git

    def test_complete_receipt_and_archive_allow_cleanup(self):
        receipt, destination, git=self.receipt_fixture()
        with patch.object(s.subprocess, 'check_output', side_effect=git):
            result=s.cleanup(self.root, self.run_id, receipt)
        self.assertEqual(result['status'], 'complete')
        for relative in s.REQUIRED: self.assertTrue((destination/relative).is_file())
        self.assertTrue((self.job/'work/review/pet.glb').is_file())

    def test_corrupt_archive_blocks_deletion(self):
        receipt, destination, _=self.receipt_fixture()
        (destination/'work/review/pet.glb').write_bytes(b'corrupt')
        with self.assertRaisesRegex(ValueError, 'Preserved file changed'):
            s.cleanup(self.root, self.run_id, receipt)
        self.assertTrue((self.job/'work/generated/raw.glb').exists())

    def test_unpushed_checkpoint_blocks_deletion(self):
        receipt, _, git=self.receipt_fixture()
        def not_pushed(command, **kwargs):
            if 'merge-base' in command: raise subprocess.CalledProcessError(1, command)
            return git(command, **kwargs)
        with patch.object(s.subprocess, 'check_output', side_effect=not_pushed), self.assertRaises(subprocess.CalledProcessError):
            s.cleanup(self.root, self.run_id, receipt)
        self.assertTrue((self.job/'work/generated/raw.glb').exists())


class WatchdogTests(unittest.TestCase):
    def run_worker(self, memory, command=None):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            with (root/'log').open('w') as log, patch.object(p, 'preflight', return_value=HEALTHY), patch.object(p, 'system_memory', side_effect=memory):
                return p.supervise_worker(command or [sys.executable,'-c','import time; time.sleep(30)'], root, log, root/'memory.jsonl', interval=.01)
    def test_low_memory_terminates_only_owned_child(self):
        launched = []
        original = subprocess.Popen
        def capture(*args, **kwargs):
            process = original(*args, **kwargs); launched.append(process); return process
        unrelated = original([sys.executable,'-c','import time; time.sleep(30)'])
        try:
            with patch.object(p.subprocess, 'Popen', side_effect=capture):
                with self.assertRaisesRegex(RuntimeError, 'watchdog'):
                    self.run_worker(lambda:dict(HEALTHY, free_commit=3*GIB))
            self.assertIsNotNone(launched[0].poll())
            self.assertIsNone(unrelated.poll())
        finally: unrelated.terminate(); unrelated.wait(timeout=10)
    def test_telemetry_failure_reaps_owned_child(self):
        with self.assertRaisesRegex(RuntimeError, 'probe failed'):
            self.run_worker(lambda:(_ for _ in ()).throw(RuntimeError('probe failed')))
    def test_normal_completion_returns_exit_code(self):
        self.assertEqual(self.run_worker(lambda:dict(HEALTHY), [sys.executable,'-c','pass']), 0)
    def test_failed_admission_launches_nothing(self):
        with patch.object(p, 'preflight', return_value=dict(HEALTHY, free_commit=8*GIB)), patch.object(p.subprocess, 'Popen') as launch:
            with self.assertRaises(RuntimeError): p.supervise_worker([], Path('.'), io.StringIO(), Path('unused'))
            launch.assert_not_called()


class QueueTests(unittest.TestCase):
    def test_seed_excludes_approved_pets_and_prioritizes_coati(self):
        queue = f.seed_queue(); ids = [r['pet_id'] for r in queue['pets']]
        self.assertEqual(ids[0], 'JungleCoati')
        self.assertEqual(len(ids), 248)
        self.assertNotIn('JungleOcelot', ids); self.assertNotIn('JungleRedPanda', ids)
    def test_repeated_candidate_refused_even_after_renaming_recipe(self):
        queue = f.seed_queue(); row = queue['pets'][0]
        config = p.HERE/'concept_coati_anatomy.json'
        f.assign_recipe(queue, row['pet_id'], config, 'concept', '')
        row['attempts'].append({'fingerprint':row['fingerprint']}); row['state']='failed'
        with self.assertRaisesRegex(ValueError, 'already attempted'):
            f.assign_recipe(queue, row['pet_id'], config, 'concept', 'retry')
    def test_failed_hardware_keeps_recipe_ready_without_attempt(self):
        queue = f.seed_queue(); row = queue['pets'][0]
        f.assign_recipe(queue, row['pet_id'], p.HERE/'concept_coati_anatomy.json', 'concept', '')
        with tempfile.TemporaryDirectory() as folder:
            root=Path(folder); (root/'factory').mkdir()
            with patch.object(f, 'preflight', return_value=dict(HEALTHY, free_commit=8*GIB)):
                self.assertEqual(f.run_ready(root, queue, root/'factory/queue.json'), 'resource_blocked')
            self.assertEqual(row['state'], 'ready'); self.assertEqual(row['attempts'], [])
    def test_pending_review_prevents_next_pet(self):
        queue=f.seed_queue(); queue['pets'][0]['state']='awaiting_visual'
        self.assertEqual(f.run_ready(Path('.'), queue, Path('unused')), 'awaiting_visual')


if __name__=='__main__': unittest.main()
