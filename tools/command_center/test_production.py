"""Security tests use synthetic D: fixtures, never the live worker grant/config."""
import copy
import json
import math
import os
from pathlib import Path
import tempfile
import unittest
import sys
import threading
import time
from unittest.mock import patch
import xml.etree.ElementTree as ET

from tools.command_center import production as p
from tools.command_center import production_trial as trial
from tools.command_center import bridge as b
from tools.command_center.test_bridge import FakeRemote


class ProductionTests(unittest.TestCase):
    def setUp(self):
        base = Path('D:/AnimalKingdom3D/command-center-tests')
        base.mkdir(parents=True,exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=base)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.cfg = json.loads((p.HERE/'config.example.json').read_text())
        self.cfg['runtime'] = str(self.root)
        self.task = {
            'task_id':'coati-sdxl-memory','revision':1,'source':'chatgpt','priority':10,
            'approval_class':p.CLASS,'allowed_paths':['tools/pet_pipeline/generate_concepts.py'],
            'notion_page':p.policy()['notion_page'],'instructions':'Propose a memory fix; never execute candidate code.',
            'acceptance':[{'path':'tools/pet_pipeline/generate_concepts.py','contains':'safe'}],
            'tests':['text-contract','git-diff-check','syntax'],'requires_studio':False,
            'actions':['profile-resources','propose-source','static-qa'],'policy_sha256':p.file_hash(p.POLICY)}
        self.healthy = {'commit_free_gib':20,'ram_free_gib':8,'vram_free_gib':8,'disk_free_gib':20}

    def grant(self):
        p.activate(self.root,p.file_hash(p.POLICY),p.controller_hash(),'ENABLE production-coati-v1 FOR ISSUE 2')

    def issue(self):
        return {'number':2,'state':'open','user':{'login':'wardmaciah-web'},'body':'```ak-task\n'+json.dumps(self.task)+'\n```'}

    def parse(self):
        return b.parse_task(self.issue(),self.cfg)

    def test_default_is_disabled_even_with_config_switch(self):
        self.cfg['production_enabled'] = True
        self.assertEqual(p.status(self.root)['active'],'documentation-only')
        with self.assertRaises(b.ApprovalRequired): self.parse()

    def test_local_exact_hash_opt_in(self):
        self.grant()
        self.assertEqual(self.parse()['task_id'],'coati-sdxl-memory')
        self.assertEqual(p.status(self.root)['active'],p.CLASS)

    def test_confirmation_cannot_be_remote_flag(self):
        with self.assertRaises(p.Denied):
            p.activate(self.root,p.file_hash(p.POLICY),p.controller_hash(),'yes')
        self.task['activate'] = True
        with self.assertRaises(b.Blocked): self.parse()

    def test_wrong_review_hash_refused(self):
        with self.assertRaises(p.Denied): p.activate(self.root,'0'*64,p.controller_hash(),'ENABLE production-coati-v1 FOR ISSUE 2')

    def test_plaintext_forged_receipt_rejected(self):
        p.receipt_path(self.root).write_text(json.dumps({'mode':p.CLASS,'expires':1e20}))
        with self.assertRaises(p.Denied): p.read_grant(self.root)

    def test_expired_grant(self):
        self.grant()
        with patch.object(p.time,'time',return_value=p.time.time()+90000):
            with self.assertRaises(p.Denied): p.read_grant(self.root)

    def test_changed_controller_invalidates_grant(self):
        self.grant()
        with patch.object(p,'controller_hash',return_value='changed'):
            with self.assertRaises(p.Denied): p.read_grant(self.root)

    def test_changed_policy_invalidates_grant(self):
        self.grant()
        other = self.root/'policy.json'
        value = p.policy(); value['resource_limits']['admit_commit_gib']=10
        other.write_text(json.dumps(value))
        with patch.object(p,'POLICY',other):
            with self.assertRaises(p.Denied): p.read_grant(self.root)
            with self.assertRaises(p.Denied): p.policy()

    def test_task_cannot_expand_path_scope(self):
        self.grant()
        for name in ['src/ServerScriptService/Game.lua','tools/command_center/production.py','tools/command_center/policies/production-coati-v1.json','AGENTS.md','.git/config','tools/pet_pipeline/resource-policy.json','tools/pet_pipeline/references/approved-ocelot-front.png','tools/pet_pipeline/factory.py','tools/pet_pipeline/tests/test_safety.py','Tools/pet_pipeline/generate_concepts.py','tools/pet_pipeline/../command_center/bridge.py','C:/Users/Kenny/.codex/auth.json']:
            with self.subTest(path=name):
                self.task['allowed_paths']=[name]
                with self.assertRaises(b.ApprovalRequired): self.parse()

    def test_unknown_or_privileged_action_refused(self):
        self.grant()
        for action in ['powershell','cmd /c anything','studio-edit','publish','purchase','paid-credits','set-pagefile','unlock-biome','delete','coati-concept-once','full-queue','activate']:
            with self.subTest(action=action):
                self.task['actions']=[action]
                with self.assertRaises(b.ApprovalRequired): self.parse()

    def test_arbitrary_test_command_refused(self):
        self.grant(); self.task['tests']=['python -c arbitrary']
        with self.assertRaises(b.ApprovalRequired): self.parse()

    def test_untrusted_issuer(self):
        self.grant(); issue=self.issue(); issue['user']['login']='attacker'
        with self.assertRaises(b.Blocked): b.parse_task(issue,self.cfg)

    def test_other_issue_or_task_cannot_borrow_capability(self):
        self.grant(); issue=self.issue(); issue['number']=4
        with self.assertRaises(b.ApprovalRequired): b.parse_task(issue,self.cfg)
        self.task['task_id']='another-pet'
        with self.assertRaises(b.ApprovalRequired): self.parse()

    def test_forged_revision_or_policy_hash(self):
        self.grant(); self.task['revision']=True
        with self.assertRaises(b.Blocked): self.parse()
        self.task['revision']=1; self.task['policy_sha256']='old'
        with self.assertRaises(b.ApprovalRequired): self.parse()

    def test_studio_unavailable_and_unauthorized(self):
        self.grant(); self.task['requires_studio']=True
        with self.assertRaises(b.ApprovalRequired): self.parse()

    def test_notion_destination_cannot_be_changed(self):
        self.grant(); self.task['notion_page']='another-secret-page'
        with self.assertRaises(b.ApprovalRequired): self.parse()

    def test_duplicate_claim_and_crash_do_not_grant_retry(self):
        self.grant(); task=self.parse(); p.consume_workflow(self.root,task)
        task['revision']=2
        with self.assertRaises(p.Denied): p.consume_workflow(self.root,task)
        with self.assertRaises(p.Denied): self.grant()

    def test_rollback_revokes_before_next_action(self):
        self.grant(); task=self.parse(); p.disable(self.root)
        with self.assertRaises(p.Denied): p.authorize(task,self.cfg,2)
        self.assertEqual(p.status(self.root)['active'],'documentation-only')

    def test_documentation_contract_unchanged_before_and_after_grant(self):
        task=json.loads((p.HERE/'task.example.json').read_text())
        issue={'number':3,'user':{'login':'wardmaciah-web'},'body':'```ak-task\n'+json.dumps(task)+'\n```'}
        before=b.parse_task(issue,self.cfg)
        self.grant()
        after=b.parse_task(issue,self.cfg)
        self.assertEqual(before,after)

    def test_all_resource_gates_fail_closed(self):
        p.resource_gate(self.healthy)
        for field in self.healthy:
            for value in [None,float('nan'),float('inf'),-1,0,'100',True]:
                sample={**self.healthy,field:value}
                with self.subTest(field=field,value=value),self.assertRaises(p.Denied):
                    p.resource_gate(sample)

    def test_commit_is_not_vram_and_reserves_preserved(self):
        with self.assertRaises(p.Denied): p.resource_gate({**self.healthy,'commit_free_gib':10,'vram_free_gib':100})
        with self.assertRaises(p.Denied): p.resource_gate({**self.healthy,'commit_free_gib':3.99},running=True)
        with self.assertRaises(p.Denied): p.resource_gate({**self.healthy,'vram_free_gib':.24},running=True)

    def test_candidate_python_is_parsed_never_executed(self):
        marker=self.root/'should-not-exist.txt'
        path=p.regular_path(self.root,self.task['allowed_paths'][0]); path.parent.mkdir(parents=True)
        path.write_text("# safe\nfrom pathlib import Path\nPath("+repr(str(marker))+ ").write_text('bad')\n")
        self.assertTrue(p.validate_source(self.task,self.root)[0]['passed'])
        self.assertFalse(marker.exists())
        self.grant()
        with self.assertRaises(p.Denied): trial.request_trial(self.root,'coati-concept-once',{})
        self.assertFalse(marker.exists())

    def test_single_coati_recipe_only(self):
        self.task['allowed_paths']=['tools/pet_pipeline/concept_coati_anatomy.json']
        path=p.regular_path(self.root,self.task['allowed_paths'][0]); path.parent.mkdir(parents=True)
        recipe=json.loads((p.HERE.parent/'pet_pipeline/concept_coati_anatomy.json').read_text(encoding='utf-8-sig'))
        path.write_text(json.dumps(recipe))
        with self.assertRaises(p.Denied): p.validate_source(self.task,self.root)
        recipe['seeds']=[1071]; path.write_text(json.dumps(recipe))
        self.assertTrue(p.validate_source(self.task,self.root)[0]['passed'])
        recipe['species']='Red Panda'; path.write_text(json.dumps(recipe))
        with self.assertRaises(p.Denied): p.validate_source(self.task,self.root)

    def test_hardlink_alias_to_credentials_is_blocked(self):
        source=self.root/'secret.txt'; source.write_text('fixture')
        link=self.root/'alias.txt'; os.link(source,link)
        with self.assertRaises(p.Denied): p.regular_path(self.root,'alias.txt')

    def test_alternate_streams_reserved_and_absolute_paths_blocked(self):
        for name in ['../x','C:/x','CON.txt','a.txt:secret','dir/./x','/x','a\\x']:
            with self.subTest(path=name),self.assertRaises(p.Denied): p.regular_path(self.root,name)

    def test_task_cannot_choose_sandbox_mount_or_command(self):
        with self.assertRaises(TypeError):
            trial.plan_offline_sandbox('C:/Users/Kenny/.codex','C:/Windows')
        xml=trial.plan_offline_sandbox()
        tree=ET.fromstring(xml)
        self.assertEqual(tree.findtext('Networking'),'Disable')
        self.assertEqual(tree.findtext('ClipboardRedirection'),'Disable')
        self.assertIsNone(tree.find('LogonCommand'))
        hosts=[node.text for node in tree.findall('.//HostFolder')]
        self.assertTrue(all('AnimalKingdom3D' in host for host in hosts))
        self.assertFalse(any('Users' in host or 'Windows' in host for host in hosts))

    def test_missing_execution_boundary_never_falls_back_to_host(self):
        self.grant()
        with patch('subprocess.Popen') as launch:
            with self.assertRaises(p.Denied): trial.request_trial(self.root,'coati-concept-once',{})
            launch.assert_not_called()
        self.assertFalse(trial.execution_readiness()['ready'])

    def test_trial_cannot_accept_remote_arguments(self):
        self.grant()
        with self.assertRaises(p.Denied): trial.request_trial(self.root,'coati-concept-once',{'command':'anything'})

    def test_broker_still_strips_all_tokens(self):
        with patch.dict(os.environ,{'AK_GITHUB_TOKEN':'test','AK_NOTION_TOKEN':'test','OPENAI_API_KEY':'test','PYTHONPATH':'hostile'}):
            env=b.clean_environment()
            for key in ['AK_GITHUB_TOKEN','AK_NOTION_TOKEN','OPENAI_API_KEY','PYTHONPATH']:
                self.assertNotIn(key,env)

    def test_production_proposal_roundtrip_never_executes_candidate(self):
        self.grant(); issue=self.issue(); task=self.parse()
        marker=self.root/'candidate-executed'
        proposal={'edits':[{'path':self.task['allowed_paths'][0],'content':"# safe\nfrom pathlib import Path\nPath("+repr(str(marker))+").write_text('forbidden')\n"}]}
        remote=FakeRemote(issue)
        remote.notion=lambda route: {'last_edited_time':'fixture','properties':{'Codex Handoff':'Investigate Coati memory safely'}}
        worker=b.Worker(self.cfg,remote,proposer=lambda *args:proposal)
        worker.state.add(task)
        calls=[]
        def git_stub(root,*args,**kwargs):
            calls.append(args)
            if args[:3]==('remote','get-url','origin'): return 'https://github.com/wardmaciah-web/Animal-Kingdom.git'
            if args[0] in {'status','ls-remote'}: return ''
            if args[:3]==('diff','--cached','--name-only'): return task['allowed_paths'][0]
            return 'a'*40
        try:
            with patch.object(b,'git',side_effect=git_stub),patch.object(p,'sample_resources',return_value=self.healthy),patch('subprocess.Popen') as launch:
                report=worker.execute(task)
                launch.assert_not_called()
            self.assertEqual(report['state'],'review')
            self.assertFalse(marker.exists())
            self.assertTrue(any(args[0]=='push' and args[-1]=='HEAD:refs/heads/akcc/coati-sdxl-memory/r1' for args in calls))
            self.assertFalse(any('main' in args or 'merge' in args for args in calls if args[0]=='push'))
        finally:
            worker.state.db.close()
            b.CONTROL=None

    def test_revocation_stops_only_owned_child(self):
        from types import SimpleNamespace
        self.grant()
        state=b.State(self.root)
        controller=SimpleNamespace(root=self.root,active_production=True,heartbeat=lambda:None,state=state)
        def revoke():
            time.sleep(.2)
            p.disable(self.root)
        revoker=threading.Thread(target=revoke)
        revoker.start()
        try:
            with patch.object(b,'CONTROL',controller):
                with self.assertRaisesRegex(b.Blocked,'revoked'):
                    b.run_command([sys.executable,'-c','import time; time.sleep(30)'],self.root,timeout=5)
        finally:
            revoker.join()
            state.db.close()

    def test_dashboard_distinguishes_proposed_active_and_revoked(self):
        worker=b.Worker(self.cfg,FakeRemote(self.issue()))
        try:
            self.assertEqual(worker.snapshot()['permission_policy']['active'],'documentation-only')
            self.grant()
            self.assertEqual(worker.snapshot()['permission_policy']['active'],p.CLASS)
            p.disable(self.root)
            self.assertEqual(worker.snapshot()['permission_policy']['active'],'documentation-only')
        finally:
            worker.state.db.close()


if __name__=='__main__': unittest.main()
