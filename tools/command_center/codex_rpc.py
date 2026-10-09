"""Deterministic Notion connector calls through the authenticated Codex app server.

No model turn is started. Task prose cannot select tools or supply tool arguments.
The child transport is owned by a Windows job and denied unsolicited approvals.
"""
import json
import queue
import subprocess
import threading
import time
import os
import re
import tomllib
from pathlib import Path
try:
    from .windows_job import Job
except ImportError:
    from windows_job import Job


class ConnectorError(Exception):
    pass


class NotionRPC:
    def __init__(self, codex, cwd, pages, environment):
        self.pages = set(pages)
        self.counter = 0
        self.incoming = queue.Queue()
        self.job = Job()
        self.process = None
        try:
            command = [codex, '--no-daemon', 'app-server', '--stdio', '--enable', 'apps', '--disable', 'plugins', '--disable', 'remote_plugin', '--disable', 'hooks']
            config_file = Path.home() / '.codex/config.toml'
            if config_file.exists():
                configuration = tomllib.loads(config_file.read_text(encoding='utf-8'))
                for server in configuration.get('mcp_servers', {}):
                    # Enumerate names only; never log headers or credentials.
                    if not re.fullmatch(r'[A-Za-z0-9_-]+', server):
                        raise ConnectorError('Noncanonical MCP server name requires configuration review')
                    command += ['-c', 'mcp_servers.' + server + '.enabled=false']
            self.process = subprocess.Popen(command, cwd=cwd,
                stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                text=True, encoding='utf-8', env=environment,
                creationflags=0x4 if os.name == 'nt' else 0)
            self.job.assign_and_resume(self.process)
            threading.Thread(target=self._read, daemon=True).start()
            self.call('initialize', {'clientInfo': {'name': 'animal_kingdom_bridge', 'version': '1.0'}, 'capabilities': {'experimentalApi': True, 'explicitGatewayOauth': True}})
            self._send({'method': 'initialized', 'params': {}})
            thread = self.call('thread/start', {'cwd': str(cwd), 'ephemeral': True, 'sandbox': 'read-only', 'approvalPolicy': 'never', 'config': {'features.apps': True, 'features.plugins': False, 'features.hooks': False}})
            self.thread_id = thread['thread']['id']
        except Exception:
            self.close()
            raise

    def _read(self):
        try:
            for line in self.process.stdout:
                try:
                    self.incoming.put(json.loads(line))
                except ValueError:
                    continue
        finally:
            self.incoming.put(None)

    def _send(self, value):
        self.process.stdin.write(json.dumps(value) + '\n')
        self.process.stdin.flush()

    def call(self, method, params):
        self.counter += 1
        request_id = self.counter
        self._send({'id': request_id, 'method': method, 'params': params})
        deadline = time.monotonic() + 60
        while time.monotonic() < deadline:
            try:
                message = self.incoming.get(timeout=max(.1, deadline - time.monotonic()))
            except queue.Empty:
                break
            if message is None:
                raise ConnectorError('Codex connector transport disconnected')
            if 'method' in message and 'id' in message:
                self._send({'id': message['id'], 'error': {'code': -32601, 'message': 'Unattended approval/elicitation denied; user action required'}})
                continue
            if message.get('id') == request_id:
                if 'error' in message:
                    raise ConnectorError('Codex connector request rejected: ' + str(message['error'].get('code')))
                return message['result']
        raise ConnectorError('Codex connector request timed out')

    def tool(self, name, arguments):
        if name not in {'notion.fetch', 'notion.notion-update-page'}:
            raise ConnectorError('Tool is not on the broker allowlist')
        page = arguments.get('page_id', arguments.get('id'))
        if page not in self.pages:
            raise ConnectorError('Notion page is not on the broker allowlist')
        if name.endswith('notion-update-page'):
            allowed = {'Codex Handoff', 'GitHub / Commit', 'Studio Evidence', 'Stage', 'QA Result', 'Next Action'}
            if arguments.get('command') != 'update_properties' or not set(arguments.get('properties', {})).issubset(allowed):
                raise ConnectorError('Only approved handoff properties can be updated')
        result = self.call('mcpServer/tool/call', {'threadId': self.thread_id, 'server': 'codex_apps', 'tool': name, 'arguments': arguments})
        if result.get('isError'):
            raise ConnectorError('Notion connector reported an error')
        return result

    def close(self):
        if self.process:
            try:
                self.process.stdin.close()
            except OSError:
                pass
        self.job.close()
        if self.process:
            if self.process.poll() is None:
                self.process.kill()
            self.process.wait(timeout=10)
            self.process.stdout.close()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        self.close()
