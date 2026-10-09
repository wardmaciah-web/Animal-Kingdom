import copy
import json
from pathlib import Path
import tempfile
import unittest
import os
import sys
import urllib.request
import urllib.error
from types import SimpleNamespace
from unittest.mock import patch

from tools.command_center.bridge import (ApprovalRequired, Blocked, Lock, State,
    Worker, Connectors, apply_proposal, clean_environment, dashboard, dashboard_token, git, handoff_prefix, parse_task, run_command, run_tests, safe_path)
from tools.command_center.codex_rpc import NotionRPC, ConnectorError

HERE = Path(__file__).parent


class FakeRemote:
    def __init__(self, issue):
        self.issue = issue
        self.comments = []
        self.fail = False

    def authenticate(self):
        if self.fail:
            raise Blocked('authentication failed')

    def issues(self):
        return [self.issue]

    def gh(self, route):
        return self.issue

    def verify_dispatch(self, issue, task):
        pass

    def reviewer_decision(self, task, report):
        return 'pending'

    def comment(self, issue=None, marker=None, body=None, **payload):
        if self.fail:
            raise Blocked('network failed')
        self.comments.append(dict(issue=issue, marker=marker, body=body))

    def sync_notion(self, payload):
        if self.fail:
            raise Blocked('network failed')


class BridgeTests(unittest.TestCase):
    def setUp(self):
        scratch = Path('D:/AnimalKingdom3D/command-center-tests')
        scratch.mkdir(parents=True, exist_ok=True)
        self.temp = tempfile.TemporaryDirectory(dir=scratch)
        self.root = Path(self.temp.name)
        self.cfg = json.loads((HERE / 'config.example.json').read_text())
        self.cfg.update(runtime=str(self.root / 'runtime'), checkout=str(self.root), require_notion=False)
        self.task = json.loads((HERE / 'task.example.json').read_text())
        self.issue = self.make_issue()

    def tearDown(self):
        self.temp.cleanup()

    def make_issue(self):
        return {'number': 2, 'state': 'open', 'user': {'login': 'wardmaciah-web'}, 'body': '```ak-task\n' + json.dumps(self.task) + '\n```'}

    def test_dispatch_and_duplicate(self):
        task = parse_task(self.issue, self.cfg)
        state = State(self.root)
        self.assertTrue(state.add(task))
        self.assertFalse(state.add(task))
        self.assertEqual(len(state.rows()), 1)
        state.db.close()

    def test_untrusted_author(self):
        self.issue['user']['login'] = 'attacker'
        with self.assertRaises(Blocked):
            parse_task(self.issue, self.cfg)

    def test_approval_cannot_be_self_granted(self):
        for value in ['purchase', 'publish', 'destructive', 'security', 'paid-generation']:
            self.task['approval_class'] = value
            with self.assertRaises(ApprovalRequired):
                parse_task(self.make_issue(), self.cfg)

    def test_protected_paths_and_windows_escapes(self):
        for name in ['src/Pets.lua', '../escape.txt', 'C:/secret.txt', 'documentations/command-center-tasks/../../secret.txt', 'documentations/command-center-tasks/CON.txt', 'documentations/command-center-tasks/a.txt:stream', 'documentations/command-center-tasks/.git/config', 'tools/pet_pipeline/roster.json', 'assets/pet.glb']:
            with self.subTest(name=name), self.assertRaises(ApprovalRequired):
                safe_path(name, self.cfg['allowed_roots'])

    def test_arbitrary_shell_test_rejected(self):
        self.task['tests'] = ['powershell Remove-Item']
        with self.assertRaises(Blocked):
            parse_task(self.make_issue(), self.cfg)

    def test_duplicate_lock(self):
        with Lock(self.root / 'lock'):
            with self.assertRaises(Blocked):
                with Lock(self.root / 'lock'):
                    self.fail('overlapping worker entered')
        with Lock(self.root / 'lock'):
            pass

    def test_crash_recovery_preserves_and_does_not_rerun(self):
        task = parse_task(self.issue, self.cfg)
        state = State(self.root)
        state.add(task)
        state.update(task, 'implementing')
        state.recover()
        self.assertEqual(state.rows()[0]['state'], 'blocked')
        self.assertFalse(state.add(task))
        state.db.close()

    def test_changed_body_requires_revision(self):
        task = parse_task(self.issue, self.cfg)
        state = State(self.root)
        state.add(task)
        task['body_hash'] = 'changed'
        with self.assertRaises(Blocked):
            state.add(task)
        state.db.close()

    def test_dedupe_does_not_cross_issue(self):
        task = parse_task(self.issue, self.cfg)
        state = State(self.root)
        state.add(task)
        task['issue'] = 900
        with self.assertRaises(Blocked):
            state.add(task)
        state.db.close()

    def test_studio_disconnected_stops_before_codex(self):
        self.task['requires_studio'] = True
        issue = self.make_issue()
        remote = FakeRemote(issue)
        with patch('tools.command_center.bridge.codex_proposal') as codex:
            worker = Worker(self.cfg, remote, proposer=codex)
            task = parse_task(issue, self.cfg)
            worker.state.add(task)
            report = worker.execute(task)
            self.assertEqual(report['state'], 'blocked')
            self.assertEqual(report['studio_status'], 'unavailable')
            codex.assert_not_called()
            worker.state.db.close()

    def test_outbox_retry_is_bounded_and_deduped(self):
        remote = FakeRemote(self.issue)
        worker = Worker(self.cfg, remote)
        payload = {'issue': 2, 'marker': 'test', 'body': 'result'}
        worker.state.enqueue('one', 'github', payload)
        worker.state.enqueue('one', 'github', payload)
        remote.fail = True
        worker.deliver()
        row = worker.state.db.execute('SELECT * FROM outbox').fetchone()
        self.assertEqual(row['attempts'], 1)
        remote.fail = False
        worker.state.db.execute('UPDATE outbox SET due=0')
        worker.state.db.commit()
        worker.deliver()
        self.assertEqual(len(remote.comments), 1)
        self.assertEqual(worker.state.db.execute('SELECT COUNT(*) FROM outbox').fetchone()[0], 0)
        worker.state.enqueue('one', 'github', payload)
        worker.deliver()
        self.assertEqual(len(remote.comments), 1)
        worker.state.db.close()

    def test_auth_failure_never_dispatches(self):
        remote = FakeRemote(self.issue)
        remote.fail = True
        worker = Worker(self.cfg, remote)
        with self.assertRaises(Blocked):
            worker.poll()
        self.assertEqual(worker.state.rows(), [])
        worker.state.db.close()

    def test_stale_issue_stops_before_git(self):
        remote = FakeRemote(self.issue)
        worker = Worker(self.cfg, remote)
        task = parse_task(self.issue, self.cfg)
        worker.state.add(task)
        remote.issue = {**self.issue, 'body': 'changed'}
        with patch('tools.command_center.bridge.git') as git:
            self.assertEqual(worker.execute(task)['state'], 'blocked')
            git.assert_not_called()
        worker.state.db.close()

    def test_edit_set_validated_before_any_write(self):
        task = parse_task(self.issue, self.cfg)
        proposal = {'edits': [{'path': task['allowed_paths'][0], 'content': 'safe'}, {'path': 'src/Pet.lua', 'content': 'unsafe'}]}
        with self.assertRaises(ApprovalRequired):
            apply_proposal(proposal, task, self.root, self.cfg)
        self.assertFalse((self.root / task['allowed_paths'][0]).exists())

    def test_real_contract_failure(self):
        task = parse_task(self.issue, self.cfg)
        task['tests'] = ['text-contract']
        apply_proposal({'edits': [{'path': task['allowed_paths'][0], 'content': 'wrong'}]}, task, self.root, self.cfg)
        self.assertFalse(run_tests(task, self.root)[0]['passed'])

    def test_broker_secrets_not_in_agent_environment(self):
        with patch.dict('os.environ', {'AK_GITHUB_TOKEN': 'SECRET', 'AK_NOTION_TOKEN': 'SECRET', 'OPENAI_API_KEY': 'SECRET'}):
            self.assertNotIn('AK_GITHUB_TOKEN', clean_environment())
            self.assertNotIn('AK_NOTION_TOKEN', clean_environment())
            self.assertNotIn('OPENAI_API_KEY', clean_environment())

    def test_changed_controller_allows_new_revision_after_failure(self):
        task = parse_task(self.issue, self.cfg)
        state = State(self.root)
        try:
            state.add(task)
            state.update(task, 'blocked')
            task['revision'] = 2
            with self.assertRaises(Blocked):
                state.add(task)
            task['controller_hash'] = 'verified-new-controller'
            self.assertTrue(state.add(task))
        finally:
            state.db.close()

    def test_trusted_dispatch_digest_required(self):
        remote = Connectors({**self.cfg, 'github_auth': 'environment'})
        task = parse_task(self.issue, self.cfg)
        for author, body, accepted in [('attacker', 'ak-dispatch ' + task['body_hash'], False), ('wardmaciah-web', 'ak-dispatch wrong', False), ('wardmaciah-web', 'ak-dispatch ' + task['body_hash'], True)]:
            with patch.object(remote, 'gh', return_value=[{'user': {'login': author}, 'body': body}]):
                if accepted:
                    remote.verify_dispatch(self.issue, task)
                else:
                    with self.assertRaises(ApprovalRequired):
                        remote.verify_dispatch(self.issue, task)

    def test_notion_rpc_rejects_unrelated_tools_pages_and_fields(self):
        rpc = NotionRPC.__new__(NotionRPC)
        rpc.pages = set(self.cfg['notion_pages'])
        cases = [('github.create_issue', {'id': self.task['notion_page']}), ('notion.fetch', {'id': 'other'}), ('notion.notion-update-page', {'page_id': self.task['notion_page'], 'command': 'replace_content'}), ('notion.notion-update-page', {'page_id': self.task['notion_page'], 'command': 'update_properties', 'properties': {'Task': 'overwrite title'}})]
        for name, arguments in cases:
            with self.assertRaises(ConnectorError):
                rpc.tool(name, arguments)

    def test_dashboard_auth_and_csrf(self):
        self.cfg['port'] = 0
        worker = Worker(self.cfg, FakeRemote(self.issue))
        server = dashboard(worker)
        self.cfg['port'] = server.server_address[1]
        base = f'http://127.0.0.1:{self.cfg["port"]}'
        token = dashboard_token(worker.root)
        self.assertNotIn(token.encode(), (worker.root / 'dashboard-token.dpapi').read_bytes())
        try:
            with self.assertRaises(urllib.error.HTTPError) as error:
                urllib.request.urlopen(base + '/api/status')
            self.assertEqual(error.exception.code, 401)
            headers = {'Authorization': 'Bearer ' + token}
            with urllib.request.urlopen(urllib.request.Request(base + '/api/status', headers=headers)) as response:
                self.assertEqual(json.load(response)['paused'], 'true')
            with self.assertRaises(urllib.error.HTTPError) as error:
                urllib.request.urlopen(urllib.request.Request(base + '/api/resume', method='POST', headers={**headers, 'Origin': 'https://attacker.invalid'}))
            self.assertEqual(error.exception.code, 403)
            with urllib.request.urlopen(urllib.request.Request(base + '/api/resume', method='POST', headers={**headers, 'Origin': base})) as response:
                self.assertEqual(response.status, 204)
            self.assertEqual(worker.state.setting('paused'), 'false')
        finally:
            server.shutdown()
            server.server_close()
            worker.state.db.close()

    @unittest.skipUnless(os.name == 'nt', 'Windows job containment')
    def test_timeout_terminates_owned_descendants(self):
        pid_file = self.root / 'child.pid'
        code = "import subprocess,sys,time; from pathlib import Path; p=subprocess.Popen([sys.executable,'-c','import time; time.sleep(60)']); Path(sys.argv[1]).write_text(str(p.pid)); time.sleep(60)"
        with self.assertRaises(Blocked):
            run_command([sys.executable, '-c', code, str(pid_file)], self.root, timeout=1)
        self.assertTrue(pid_file.exists())
        import ctypes
        from ctypes import wintypes
        kernel = ctypes.WinDLL('kernel32', use_last_error=True)
        kernel.OpenProcess.argtypes = [wintypes.DWORD, wintypes.BOOL, wintypes.DWORD]
        kernel.OpenProcess.restype = wintypes.HANDLE
        kernel.WaitForSingleObject.argtypes = [wintypes.HANDLE, wintypes.DWORD]
        kernel.CloseHandle.argtypes = [wintypes.HANDLE]
        handle = kernel.OpenProcess(0x100000, False, int(pid_file.read_text()))
        if handle:
            try:
                self.assertEqual(kernel.WaitForSingleObject(handle, 3000), 0)
            finally:
                kernel.CloseHandle(handle)

    def test_git_conflict_preserves_candidate_and_never_publishes(self):
        task = parse_task(self.issue, self.cfg)
        worker = Worker(self.cfg, FakeRemote(self.issue), proposer=lambda *args: {'edits': [{'path': task['allowed_paths'][0], 'content': task['acceptance'][0]['equals']}]})
        worker.state.add(task)
        commands = []
        def git_stub(root, *args, **kwargs):
            commands.append(args)
            if args[:3] == ('remote', 'get-url', 'origin'):
                return 'https://github.com/wardmaciah-web/Animal-Kingdom.git'
            if args[:3] == ('diff', '--cached', '--name-only'):
                return task['allowed_paths'][0]
            if args[0] in {'status', 'ls-remote'}:
                return ''
            if args[0] == 'push':
                raise Blocked('Simulated non-fast-forward conflict')
            return 'abc123'
        try:
            with patch('tools.command_center.bridge.git', side_effect=git_stub), patch('tools.command_center.bridge.run_command'):
                report = worker.execute(task)
            self.assertEqual(report['state'], 'blocked')
            self.assertIsNotNone(report['commit'])
            self.assertFalse(any('merge' in command or '--force' in command for command in commands))
            self.assertTrue(any('HEAD:refs/heads/akcc/command-center-smoke/r1' in command for command in commands))
        finally:
            worker.state.db.close()

    def test_actual_sparse_clone_initializes_clean_index(self):
        origin = self.root / 'origin'
        origin.mkdir()
        git(origin, 'init', '-b', 'main')
        (origin / 'AGENTS.md').write_text('Local test contract\n')
        (origin / 'protected.txt').write_text('Must not be hydrated\n')
        git(origin, 'add', '--', 'AGENTS.md', 'protected.txt')
        git(origin, '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid', 'commit', '-m', 'fixture')
        clone = self.root / 'clone'
        run_command(['git', 'clone', '--no-checkout', str(origin), str(clone)], self.root)
        run_command(['git', 'sparse-checkout', 'set', '--no-cone', '--stdin'], clone, stdin='/AGENTS.md\n/documentations/command-center-tasks/smoke.txt\n')
        git(clone, 'read-tree', '-mu', 'HEAD')
        git(clone, 'checkout', '-b', 'akcc/test/r1')
        self.assertEqual(git(clone, 'status', '--porcelain'), '')
        self.assertTrue((clone / 'AGENTS.md').exists())
        self.assertFalse((clone / 'protected.txt').exists())

    def test_stale_notion_delivery_does_not_overwrite_new_revision(self):
        remote = FakeRemote(self.issue)
        worker = Worker(self.cfg, remote)
        task = parse_task(self.issue, self.cfg)
        worker.state.add(task)
        worker.state.update(task, 'blocked')
        worker.state.enqueue('old', 'notion', {'task_id': task['task_id'], 'revision': 1})
        task.update(revision=2, controller_hash='fixed')
        worker.state.add(task)
        try:
            with patch.object(remote, 'sync_notion') as sync:
                worker.deliver()
                sync.assert_not_called()
        finally:
            worker.state.db.close()

    def test_reviewer_decision_is_bound_to_commit(self):
        remote = Connectors({**self.cfg, 'github_auth': 'environment'})
        task = parse_task(self.issue, self.cfg)
        report = {'commit': '12345'}
        for author, sha, expected in [('attacker', '12345', 'pending'), ('wardmaciah-web', '99999', 'pending'), ('wardmaciah-web', '12345', 'approved')]:
            comments = [{'user': {'login': author}, 'body': f"ak-review {task['task_id']} 1 approve {sha}"}]
            with patch.object(remote, 'gh', return_value=comments):
                self.assertEqual(remote.reviewer_decision(task, report), expected)

    def test_fine_grained_token_mode_never_falls_back_to_gcm(self):
        controller = SimpleNamespace(cfg={'github_auth': 'environment'}, remote=SimpleNamespace(github_token='mock-not-a-real-secret'))
        with patch('tools.command_center.bridge.CONTROL', controller), patch('tools.command_center.bridge.run_command', return_value='') as command:
            git(self.root, 'push', 'origin', 'HEAD:refs/heads/akcc/test/r1')
            args = command.call_args.args[0]
            environment = command.call_args.kwargs['env']
            self.assertIn('credential.helper=', args)
            self.assertNotIn('mock-not-a-real-secret', ' '.join(args))
            self.assertEqual(environment['GIT_CONFIG_KEY_0'], 'http.https://github.com/wardmaciah-web/Animal-Kingdom.extraHeader')
            self.assertTrue(environment['GIT_CONFIG_VALUE_0'].startswith('Authorization: Basic '))

    def test_notion_rich_text_roundtrip_replaces_only_own_report(self):
        for value in ['Keep instructions.\n\n[Command Center report]\nold', r'Keep instructions.<br><br>\\[Command Center report\\]<br>old', 'Keep instructions.<br><br>AKCC_REPORT_V1<br>old<br><br>AKCC_REPORT_V1<br>duplicate']:
            self.assertEqual(handoff_prefix(value), 'Keep instructions.')
        self.assertEqual(handoff_prefix('Original [reference](https://example.com).'), 'Original [reference](https://example.com).')


if __name__ == '__main__':
    unittest.main()
