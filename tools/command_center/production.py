"""Disabled-by-default Coati capability. No candidate Python executes on the host.

The local operator seals the exact reviewed policy/controller, separately from
GitHub dispatch. A changed policy, controller, expired or spent grant fails closed.
"""
from __future__ import annotations
import argparse
import ast
import ctypes
from ctypes import wintypes
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import time

try:
    from .windows_job import protect_token
except ImportError:
    from windows_job import protect_token

HERE = Path(__file__).resolve().parent
POLICY = HERE / 'policies/production-coati-v1.json'
RUNTIME = Path('D:/AnimalKingdom3D')
SOURCE_PATHS = frozenset({'tools/pet_pipeline/generate_concepts.py', 'tools/pet_pipeline/run_concepts.py', 'tools/pet_pipeline/concept_coati_anatomy.json'})
READ_PATHS = frozenset({'tools/pet_pipeline/pet_pipeline.py', 'tools/pet_pipeline/resource-policy.json', 'tools/pet_pipeline/production-policy.json'})
CLASS = 'production-coati-v1'


class Denied(ValueError):
    pass


def file_hash(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def controller_hash():
    files = ['bridge.py', 'production.py', 'production_trial.py', 'windows_job.py', 'codex_rpc.py']
    return hashlib.sha256(''.join(name + file_hash(HERE / name) for name in files).encode()).hexdigest()


def policy():
    value = json.loads(POLICY.read_text(encoding='utf-8'))
    # Independent ceilings prevent a JSON-only policy edit from expanding scope.
    if value['id'] != CLASS or value['default_enabled'] is not False or value['issue'] != 2 or value['task_id'] != 'coati-sdxl-memory':
        raise Denied('Invalid production policy identity')
    if set(value['edit_paths']) != SOURCE_PATHS or set(value['read_only_paths']) != READ_PATHS:
        raise Denied('Production path ceiling changed')
    if value['actions'] != ['profile-resources', 'propose-source', 'static-qa'] or value['tests'] != ['text-contract', 'git-diff-check', 'syntax']:
        raise Denied('Production action ceiling changed')
    limits = value['resource_limits']
    expected = {'admit_commit_gib':16,'admit_ram_gib':4,'admit_vram_gib':7,'admit_disk_gib':10,'stop_commit_gib':4,'stop_ram_gib':1,'stop_vram_gib':.25,'max_seconds':900,'sample_seconds':.5,'max_trials':1,'max_width':1024,'max_height':1024,'max_steps':35}
    if limits != expected:
        raise Denied('Resource policy changed; separate review required')
    for kind, subdir in [('scratch', 'scratch'), ('output', 'outputs')]:
        if Path(value[kind+'_root']) != RUNTIME / subdir / 'command-center-coati-v1':
            raise Denied('Production storage boundary changed')
    return value


def regular_path(root, relative):
    """Canonical Windows spellings only; no links, ADS, case aliases or escapes."""
    from pathlib import PurePosixPath
    import re
    if not isinstance(relative, str) or not re.fullmatch(r'[A-Za-z0-9_./-]+', relative):
        raise Denied('Invalid relative path')
    p = PurePosixPath(relative)
    if p.is_absolute() or str(p) != relative or '..' in p.parts:
        raise Denied('Path escape')
    if any(part.startswith('.') or part.upper().split('.')[0] in {'CON','PRN','AUX','NUL',*[f'COM{i}' for i in range(10)],*[f'LPT{i}' for i in range(10)]} for part in p.parts):
        raise Denied('Reserved path')
    root = Path(root).absolute()
    result = root / relative
    if not result.resolve().is_relative_to(root.resolve()):
        raise Denied('Path leaves root')
    for item in [result, *result.parents]:
        if item.exists() and (item.is_symlink() or getattr(item.lstat(), 'st_file_attributes', 0) & 0x400 or (item.is_file() and item.stat().st_nlink > 1)):
            raise Denied('Linked/reparse path refused')
    return result


def receipt_path(runtime):
    return regular_path(Path(runtime), 'production-grant.dpapi')


def read_grant(runtime):
    try:
        raw = receipt_path(runtime).read_bytes()
        grant = json.loads(protect_token(raw, decrypt=True))
        if grant['policy_sha256'] != file_hash(POLICY) or grant['controller_sha256'] != controller_hash():
            raise Denied('Policy/controller differs from local approval')
        if not time.time() < grant['expires'] <= time.time() + 86401:
            raise Denied('Production approval expired or has invalid lifetime')
        if grant['mode'] != CLASS:
            raise Denied('Invalid production grant')
        policy()
        return grant
    except (OSError, ValueError, KeyError) as error:
        raise Denied('Production disabled: valid local approval is required') from error


def status(runtime):
    try:
        grant = read_grant(runtime)
        spent = regular_path(Path(runtime), 'production-workflow.spent').exists()
        return {'active': CLASS, 'expires': grant['expires'], 'workflow_spent': spent, 'trial': 'separate reviewed bundle required'}
    except Denied:
        return {'active': 'documentation-only', 'proposed': CLASS, 'enabled': False}


def activate(runtime, policy_sha, code_sha, confirmation):
    if confirmation != 'ENABLE production-coati-v1 FOR ISSUE 2':
        raise Denied('Explicit local operator confirmation required')
    policy()
    if policy_sha != file_hash(POLICY) or code_sha != controller_hash():
        raise Denied('Approval hashes do not match reviewed files')
    path = receipt_path(runtime)
    if path.exists() or regular_path(Path(runtime), 'production-workflow.spent').exists():
        raise Denied('Existing or spent grant preserved; no automatic renewal')
    grant = {'mode':CLASS,'policy_sha256':policy_sha,'controller_sha256':code_sha,'expires':time.time()+86400}
    with path.open('xb') as output:
        output.write(protect_token(json.dumps(grant).encode()))


def disable(runtime):
    # Revocation replaces only our credential receipt, never assets or jobs.
    path = receipt_path(runtime)
    with path.open('wb') as output:
        output.write(protect_token(b'{"mode":"disabled"}'))


def authorize(task, cfg, issue_number):
    p = policy()
    read_grant(cfg['runtime'])
    if issue_number != 2 or task['task_id'] != p['task_id'] or task['approval_class'] != CLASS:
        raise Denied('Only the first Coati task on issue #2 is eligible')
    if task['notion_page'] != p['notion_page'] or task['requires_studio'] is not False:
        raise Denied('Wrong handoff or unavailable/unauthorized Studio action')
    if task.get('actions') != p['actions'] or task.get('policy_sha256') != file_hash(POLICY):
        raise Denied('Unknown action or stale policy hash')
    if not task['allowed_paths'] or not set(task['allowed_paths']).issubset(SOURCE_PATHS) or len(set(task['allowed_paths'])) != len(task['allowed_paths']):
        raise Denied('Production source scope exceeded')
    if task['tests'] != p['tests']:
        raise Denied('Task-defined command/test refused')
    for path in task['allowed_paths']:
        regular_path(Path(cfg['runtime']), path)


def consume_workflow(runtime, task):
    read_grant(runtime)
    path = regular_path(Path(runtime), 'production-workflow.spent')
    try:
        with path.open('x', encoding='utf-8') as stream:
            json.dump({'task_id':task['task_id'],'revision':task['revision'],'body_hash':task['body_hash'],'time':time.time()},stream)
    except FileExistsError:
        raise Denied('One workflow already claimed; crash/retry requires a new reviewed policy') from None


def resource_gate(sample, running=False):
    limits = policy()['resource_limits']
    fields = {'commit_free_gib':limits['stop_commit_gib' if running else 'admit_commit_gib'],
              'ram_free_gib':limits['stop_ram_gib' if running else 'admit_ram_gib'],
              'vram_free_gib':limits['stop_vram_gib' if running else 'admit_vram_gib'],
              'disk_free_gib':limits['admit_disk_gib']}
    for field, threshold in fields.items():
        value = sample.get(field)
        if type(value) not in (int,float) or not math.isfinite(value) or value < threshold:
            raise Denied('Resource gate failed: ' + field)


def sample_resources():
    if os.name != 'nt':
        raise Denied('Windows resource telemetry required')
    class Performance(ctypes.Structure):
        _fields_ = [('cb',wintypes.DWORD)] + [(name,ctypes.c_size_t) for name in ('CommitTotal','CommitLimit','CommitPeak','PhysicalTotal','PhysicalAvailable','SystemCache','KernelTotal','KernelPaged','KernelNonpaged','PageSize')] + [(name,wintypes.DWORD) for name in ('HandleCount','ProcessCount','ThreadCount')]
    data = Performance(); data.cb = ctypes.sizeof(data)
    probe = ctypes.WinDLL('psapi',use_last_error=True).GetPerformanceInfo
    probe.argtypes = [ctypes.POINTER(Performance),wintypes.DWORD]
    probe.restype = wintypes.BOOL
    if not probe(ctypes.byref(data),data.cb) or not data.PageSize:
        raise Denied('System commit telemetry unavailable')
    smi = Path('C:/Windows/System32/nvidia-smi.exe')
    if not smi.is_file():
        raise Denied('Pinned NVIDIA telemetry executable unavailable')
    # Fixed read-only query; task data never enters argv or the environment.
    env = {'SystemRoot':'C:\\Windows','WINDIR':'C:\\Windows'}
    result = subprocess.run([str(smi),'--query-gpu=memory.total,memory.free','--format=csv,noheader,nounits'],capture_output=True,text=True,timeout=5,env=env)
    if result.returncode:
        raise Denied('GPU telemetry unavailable')
    total, free = map(float,result.stdout.splitlines()[0].split(','))
    unit = data.PageSize / 1024**3
    memory = {'time':time.time(),'commit_free_gib':(data.CommitLimit-data.CommitTotal)*unit,'commit_used_gib':data.CommitTotal*unit,'ram_free_gib':data.PhysicalAvailable*unit,'ram_used_gib':(data.PhysicalTotal-data.PhysicalAvailable)*unit,'vram_free_gib':free/1024,'vram_used_gib':(total-free)/1024,'disk_free_gib':shutil.disk_usage(RUNTIME).free/1024**3}
    command = "[ordered]@{automatic_pagefile=(Get-CimInstance Win32_ComputerSystem).AutomaticManagedPagefile; pagefiles=@(Get-CimInstance Win32_PageFileUsage | Select-Object Name,AllocatedBaseSize,CurrentUsage,PeakUsage); processes=@(Get-Process | Sort-Object PrivateMemorySize64 -Descending | Select-Object -First 15 Id,ProcessName,WorkingSet64,PrivateMemorySize64)} | ConvertTo-Json -Depth 4"
    probe = subprocess.run(['C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe','-NoProfile','-NonInteractive','-Command',command],capture_output=True,text=True,timeout=20,env=env)
    if probe.returncode:
        raise Denied('Read-only pagefile/process telemetry unavailable')
    memory['system'] = json.loads(probe.stdout)
    return memory


def validate_source(task, checkout):
    results = []
    for name in task['allowed_paths']:
        if name not in SOURCE_PATHS:
            raise Denied('Unauthorized candidate file')
        path = regular_path(checkout, name)
        if path.stat().st_size > 100000:
            raise Denied('Oversized candidate')
        text = path.read_text(encoding='utf-8-sig')
        if path.suffix == '.py':
            ast.parse(text)  # Never import/exec candidate code or candidate tests.
        else:
            recipe = json.loads(text)
            if recipe['pet_id'] != 'JungleCoati' or recipe['species'] != 'Coati' or len(recipe['seeds']) != 1:
                raise Denied('One original Coati seed required')
            if recipe['revision'] != '462165984030d82259a11f4367a4eed129e94a7b':
                raise Denied('Model revision changed')
            for key, ceiling in [('width',1024),('height',1024),('steps',35)]:
                if type(recipe[key]) is not int or not 1 <= recipe[key] <= ceiling:
                    raise Denied('Recipe bound exceeded')
            for key in ('style_references','design_reference_image'):
                values = recipe.get(key, [])
                values = [values] if isinstance(values,str) else values
                if any(v not in {'references/bear-front.jpg','references/approved-ocelot-front.png'} for v in values):
                    raise Denied('Reference path not authorized')
        results.append({'test':'production-static-qa','path':name,'passed':True,'runtime_execution':False})
    return results


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command',choices=['inspect','activate','disable'])
    parser.add_argument('--runtime',default='D:/AnimalKingdom3D/command-center')
    parser.add_argument('--policy-sha256')
    parser.add_argument('--controller-sha256')
    args = parser.parse_args()
    runtime = Path(args.runtime)
    if runtime.resolve() != RUNTIME / 'command-center':
        raise Denied('Operator command must target canonical controller runtime')
    if args.command == 'inspect':
        print(json.dumps({'status':status(runtime),'policy_sha256':file_hash(POLICY),'controller_sha256':controller_hash(),'permissions':policy()},indent=2))
    elif args.command == 'activate':
        confirmation = input('After user review, type ENABLE production-coati-v1 FOR ISSUE 2: ')
        activate(runtime,args.policy_sha256,args.controller_sha256,confirmation)
    else:
        disable(runtime)


if __name__ == '__main__':
    main()
