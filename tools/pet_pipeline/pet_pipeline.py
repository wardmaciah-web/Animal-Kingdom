"""Animal Kingdom's free, versioned TripoSR/Blender production entry point."""
from __future__ import annotations
import argparse, datetime as dt, hashlib, json, os, re, shutil, subprocess, sys, time
from pathlib import Path
from contextlib import contextmanager

@contextmanager
def generation_lock(runtime):
    """One concept/reconstruction worker per runtime; OS releases on process exit."""
    path = Path(runtime) / 'generation.lock'
    with path.open('a+b') as stream:
        if path.stat().st_size == 0:
            stream.write(b'0'); stream.flush()
        stream.seek(0)
        try:
            if os.name == 'nt':
                import msvcrt
                msvcrt.locking(stream.fileno(), msvcrt.LK_NBLCK, 1)
            else:
                import fcntl
                fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except OSError as exc:
            raise RuntimeError('Another generation owns this runtime; inspect it before retrying') from exc
        try:
            yield
        finally:
            stream.seek(0)
            if os.name == 'nt':
                msvcrt.locking(stream.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(stream, fcntl.LOCK_UN)

VERSION = '1.0.0'
HERE = Path(__file__).resolve().parent
CHECKS = ('original_species', 'large_expressive_eyes', 'rounded_head', 'chubby_body',
          'appropriate_surface_detail', 'matte_body', 'sitting_pose', 'two_front_paws_grounded',
          'four_view_comparison', 'no_visible_texture_failure', 'no_duplicated_limbs',
          'well_formed_paws', 'stylized_proportions')

def sha(path):
    h = hashlib.sha256()
    with Path(path).open('rb') as f:
        for block in iter(lambda: f.read(1024*1024), b''): h.update(block)
    return h.hexdigest()

def read(path):
    return json.loads(Path(path).read_text(encoding='utf-8-sig'))

def write(path, value):
    path = Path(path)
    temp = path.with_suffix(path.suffix + '.tmp')
    temp.write_text(json.dumps(value, indent=2), encoding='utf-8')
    temp.replace(path)

def python_in(root, name):
    for rel in (f'tools/{name}/Scripts/python.exe', f'tools/{name}/bin/python'):
        path = root / rel
        if path.is_file(): return path
    raise ValueError(f'Missing {name} environment beneath {root}; see INSTALL.md')


def runtime_environment(runtime, scratch=None):
    """Set paths in Python too: direct CLI launches must not fall back to C:."""
    runtime = Path(runtime).resolve()
    from factory_storage import safe_path
    if os.name == 'nt' and runtime != Path('D:/AnimalKingdom3D').resolve():
        raise ValueError('Production runtime must be D:/AnimalKingdom3D')
    scratch = Path(scratch or os.environ.get('AK_JOB_SCRATCH') or runtime/'scratch/session-temp').absolute()
    if not scratch.is_relative_to(runtime/'scratch'):
        raise ValueError('Temporary files must stay in the runtime scratch directory')
    safe_path(runtime, scratch.relative_to(runtime))
    env = os.environ.copy()
    locations = {'TEMP':scratch, 'TMP':scratch, 'HF_HOME':runtime/'cache/huggingface',
        'HF_HUB_CACHE':runtime/'cache/huggingface/hub',
        'HUGGINGFACE_HUB_CACHE':runtime/'cache/huggingface/hub',
        'TORCH_HOME':runtime/'cache/torch', 'U2NET_HOME':runtime/'cache/u2net',
        'TORCH_EXTENSIONS_DIR':runtime/'cache/torch-extensions',
        'PIP_CACHE_DIR':runtime/'cache/pip', 'UV_CACHE_DIR':runtime/'cache/uv',
        'XDG_CACHE_HOME':runtime/'cache', 'NUMBA_CACHE_DIR':runtime/'cache/numba',
        'CUDA_CACHE_PATH':runtime/'cache/cuda', 'MPLCONFIGDIR':runtime/'cache/matplotlib',
        'BLENDER_USER_CONFIG':runtime/'cache/blender/config',
        'BLENDER_USER_SCRIPTS':runtime/'cache/blender/scripts',
        'BLENDER_USER_DATAFILES':runtime/'cache/blender/datafiles'}
    for key, path in locations.items():
        safe_path(runtime, path.relative_to(runtime))
        path.mkdir(parents=True, exist_ok=True); env[key] = str(path)
    env.update(PYTHONUNBUFFERED='1', PYTHONDONTWRITEBYTECODE='1', PYTHONNOUSERSITE='1',
        AK_3D_ROOT=str(runtime), CUDA_MODULE_LOADING='LAZY', HF_HUB_DISABLE_SYMLINKS_WARNING='1',
        HF_HUB_OFFLINE='1', TRANSFORMERS_OFFLINE='1')
    return env

def system_memory():
    """System-wide commit, not GlobalMemoryStatusEx's process commit allowance.

    GetPerformanceInfo returns page counts; convert using its actual PageSize.
    Missing/failed telemetry must never permit model loading.
    """
    if os.name != 'nt':
        raise RuntimeError('Windows system memory telemetry is required')
    import ctypes
    from ctypes import wintypes
    class Performance(ctypes.Structure):
        _fields_ = [('cb', wintypes.DWORD)] + [(name, ctypes.c_size_t) for name in (
            'CommitTotal', 'CommitLimit', 'CommitPeak', 'PhysicalTotal',
            'PhysicalAvailable', 'SystemCache', 'KernelTotal', 'KernelPaged',
            'KernelNonpaged', 'PageSize')] + [(name, wintypes.DWORD) for name in (
            'HandleCount', 'ProcessCount', 'ThreadCount')]
    info = Performance(); info.cb = ctypes.sizeof(info)
    probe = ctypes.WinDLL('psapi', use_last_error=True).GetPerformanceInfo
    probe.argtypes = [ctypes.POINTER(Performance), wintypes.DWORD]
    probe.restype = wintypes.BOOL
    if not probe(ctypes.byref(info), info.cb) or not info.PageSize:
        raise RuntimeError('GetPerformanceInfo failed; generation not started')
    page = info.PageSize
    return {'memory_source': 'GetPerformanceInfo',
            'total_physical': info.PhysicalTotal * page,
            'free_physical': info.PhysicalAvailable * page,
            'total_commit': info.CommitLimit * page,
            'used_commit': info.CommitTotal * page,
            'peak_commit': info.CommitPeak * page,
            'free_commit': (info.CommitLimit - info.CommitTotal) * page}


def resource_policy():
    return read(HERE/'resource-policy.json')


def supervise_worker(command, runtime, log, telemetry, env=None, interval=0.5):
    """Monitor only the child we launch; never terminate unrelated processes.

    Admission uses resource-policy.json. Runtime reserves are emergency stop limits,
    not permission to start with less memory. Native allocations can outrun a
    sampling watchdog, so this supplements rather than replaces admission.
    """
    policy = resource_policy()
    before = preflight(runtime)
    check_hardware(before)
    if before['free_disk_bytes'] < policy['disk_gib']*1024**3:
        raise RuntimeError('At least 10 GiB free D: storage required; use factory run for verified reclamation')
    with Path(telemetry).open('x', encoding='utf-8') as evidence:
        evidence.write(json.dumps({'event':'before', **before}) + '\n'); evidence.flush()
        process = subprocess.Popen(command, env=env, stdout=log, stderr=subprocess.STDOUT)
        try:
            while process.poll() is None:
                sample = system_memory()
                sample.update(time_utc=dt.datetime.now(dt.timezone.utc).isoformat(), pid=process.pid)
                evidence.write(json.dumps(sample) + '\n'); evidence.flush()
                for field, reserve in (('free_commit', policy['stop_commit_gib']*1024**3),
                                       ('free_physical', policy['stop_ram_gib']*1024**3)):
                    if sample[field] < reserve:
                        raise RuntimeError(f'Memory watchdog stopped worker: {field}={sample[field]}, reserve={reserve}')
                try:
                    return process.wait(timeout=interval)
                except subprocess.TimeoutExpired:
                    pass
            return process.returncode
        finally:
            if process.poll() is None:
                process.terminate()
                try:
                    process.wait(timeout=10)
                except subprocess.TimeoutExpired:
                    process.kill(); process.wait(timeout=10)
            # Process exit releases native/Python/CUDA/Blender allocations even
            # after a native crash; telemetry does not assume immediate recovery.
            try:
                after = preflight(runtime)
                evidence.write(json.dumps({'event':'after', 'exit_code':process.returncode, **after}) + '\n')
            except Exception as error:
                evidence.write(json.dumps({'event':'after_probe_failed', 'error':str(error)}) + '\n')


def preflight(runtime):
    result={'runtime_root':str(runtime),'free_disk_bytes':shutil.disk_usage(runtime).free}
    probe=subprocess.run(['nvidia-smi','--query-gpu=name,memory.total,memory.free',
                          '--format=csv,noheader,nounits'],capture_output=True,text=True,check=False,timeout=10)
    result['gpu']=probe.stdout.strip();result['gpu_probe_exit_code']=probe.returncode
    result.update(system_memory())
    return result

def configure(path, runtime, output):
    path = Path(path).resolve(); cfg = read(path)
    if cfg.get('schema_version') != 1: raise ValueError('Expected schema_version 1')
    for field in ('pet_id', 'pet_name', 'biome', 'species', 'concept_image', 'style_references',
                  'target_dimensions', 'texture', 'generation', 'refinement', 'validation'):
        if not cfg.get(field): raise ValueError(f'Missing {field}')
    if not re.fullmatch(r'[A-Za-z][A-Za-z0-9_]{2,79}', cfg['pet_id']):
        raise ValueError('pet_id must be a stable identifier, not a path')
    if cfg['target_dimensions']['height'] <= 0: raise ValueError('height must be positive')
    if cfg['texture']['resolution'] not in (1024, 2048, 4096): raise ValueError('Invalid atlas size')
    if not 64 <= cfg['generation']['mc_resolution'] <= 512: raise ValueError('Invalid extraction resolution')
    if cfg['refinement']['body_triangle_budget'] > 20000: raise ValueError('Mesh budget exceeds 20k')
    if cfg['refinement']['fur']['count'] * 8 > 20000: raise ValueError('Fur mesh budget exceeds 20k')
    for field in ('concept_image', 'approved_model', 'approved_front_render'):
        if cfg.get(field):
            p = (path.parent / cfg[field]).resolve()
            if not p.is_file(): raise ValueError(f'Missing {field}: {p}')
            cfg[field] = str(p)
    cfg['style_references'] = [str((path.parent / p).resolve()) for p in cfg['style_references']]
    if len(cfg['style_references']) < 2 or not all(Path(p).is_file() for p in cfg['style_references']):
        raise ValueError('Both black-bear and approved-Ocelot style references must be present')
    cfg['runtime_root'] = str(runtime.resolve())
    cfg['pipeline_root'] = str(HERE)
    cfg['output_directory'] = str(output.resolve())
    cfg['pipeline_version'] = VERSION
    return cfg

def check_hardware(hardware):
    """Reject a run before loading model weights; retain the measured preflight."""
    # System commit is independent of VRAM. User-authorized trial and any
    # evidence-based restoration share this policy across all entry points.
    policy = resource_policy()
    for field, minimum in (('free_physical', policy['ram_gib']*1024**3),
                           ('free_commit', policy['commit_gib']*1024**3)):
        if field not in hardware:
            raise RuntimeError(f'Missing {field} measurement; generation not started')
        if hardware[field] < minimum:
            raise RuntimeError(f'Insufficient {field}: {hardware[field]} bytes; need {minimum}. See preflight.json')
    if hardware['gpu_probe_exit_code'] != 0:
        raise RuntimeError('NVIDIA preflight failed; generation not started')
    gpu_free = [int(row.rsplit(',', 1)[-1].strip()) for row in hardware['gpu'].splitlines()]
    if not gpu_free or gpu_free[0] < policy['vram_gib']*1024:
        raise RuntimeError('At least 7 GiB free VRAM on the first GPU is required')

def check_attempt_budget(cfg, runtime, policy):
    pet_id=cfg['pet_id']
    if pet_id in policy.get('deferred_species',{}):
        raise RuntimeError('Species deferred: '+policy['deferred_species'][pet_id])
    attempts=0
    configs = list((Path(runtime)/'outputs').glob('*/effective-config.json'))
    configs += list((Path(runtime)/'scratch/jobs').glob('*/work/effective-config.json'))
    for config in configs:
        previous=read(config)
        if previous.get('pet_id')!=pet_id:continue
        # Count actual fresh inference, not downstream saved-mesh diagnostics.
        report=config.parent/'generated/generation.json'
        if ((report.is_file() and read(report).get('fresh_inference') is True)
                or (config.parent/'generate.log').exists()):
            attempts+=1
    limit=policy['max_fresh_inferences_per_unapproved_species']
    override=policy.get('inference_budget_overrides',{}).get(pet_id)
    if override:
        if not override.get('reason'):raise ValueError('Inference override needs an evidence-based reason')
        limit=override['limit']
    if attempts>=limit:
        raise RuntimeError(f'{pet_id} reached {attempts}/{limit} fresh attempts; defer it and choose another species')

def generate(args):
    with generation_lock(Path(args.runtime_root).resolve()):
        return _generate(args)

def _generate(args):
    runtime = Path(args.runtime_root).resolve(); output = Path(args.output).resolve()
    if not output.is_relative_to(runtime) or output.is_relative_to(HERE.parents[1]):
        raise ValueError('Generation output must stay in D: runtime outside the Git checkout')
    cfg = configure(args.config, runtime, output)
    check_attempt_budget(cfg,runtime,read(HERE/'production-policy.json'))
    if output.exists(): raise ValueError('Output already exists; select a NEW run directory. Approved assets are never overwritten.')
    if shutil.disk_usage(output.parent if output.parent.exists() else runtime).free < 2*1024**3:
        raise ValueError('At least 2 GiB free output space is required')
    inference = python_in(runtime, 'deps-stage'); blender = python_in(runtime, 'blender-env')
    lock = read(HERE/'pipeline-lock.json')
    for name, expected in lock['weights'].items():
        if sha(runtime/'tools/TripoSR-weights'/name) != expected: raise ValueError(f'Unrecognized weights/config: {name}')
    for relative, expected in lock['vendor_files'].items():
        if sha(HERE/relative) != expected: raise ValueError(f'Vendored source changed: {relative}')
    output.mkdir(parents=True)
    effective = output/'effective-config.json'; write(effective, cfg)
    hardware = preflight(runtime)
    write(output/'preflight.json', hardware)
    try:
        check_hardware(hardware)
    except Exception as exc:
        write(output/'manifest.json', {'status':'preflight_blocked', 'failure':str(exc),
              'pet_id':cfg['pet_id'], 'credits_used':0, 'stages':[], 'visual_qa':'pending',
              'studio_qa':'pending', 'roblox_asset_ids':[]})
        raise
    manifest = {'pipeline_version': VERSION, 'pet_id': cfg['pet_id'], 'species': cfg['species'],
                'biome': cfg['biome'], 'started_utc': dt.datetime.now(dt.timezone.utc).isoformat(),
                'status': 'running', 'credits_used': 0, 'roblox_asset_ids': [], 'stages': [],
                'concept_sha256': sha(cfg['concept_image']), 'config_sha256': sha(effective),
                'style_references': {p: sha(p) for p in cfg['style_references']},
                'approved_model_sha256': sha(cfg['approved_model']) if cfg.get('approved_model') else None,
                'original_geometry_source': 'fresh TripoSR inference; no prior mesh input',
                'visual_qa': 'pending', 'studio_qa': 'pending'}
    write(output/'manifest.json', manifest)
    env = runtime_environment(runtime)
    stages = [('prepare', inference), ('generate', inference), ('project', inference),
              ('refine', blender), ('validate', inference)]
    try:
        for name, interpreter in stages:
            started = time.time()
            print(f'[{cfg["pet_id"]}] {name}', flush=True)
            with (output/f'{name}.log').open('w', encoding='utf-8') as log:
                code = supervise_worker([str(interpreter), str(HERE/'workers'/f'{name}.py'),
                                         '--config', str(effective)], runtime, log,
                                        output/f'{name}-memory.jsonl', env=env)
            manifest['stages'].append({'name': name, 'seconds': time.time()-started, 'exit_code': code})
            write(output/'manifest.json', manifest)
            if code: raise RuntimeError(f'{name} failed; see {output/name}.log')
        manifest['status'] = 'technical_pass_pending_visual'
        manifest['artifacts'] = {str(p.relative_to(output)): {'sha256': sha(p), 'bytes': p.stat().st_size}
                                 for p in output.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    except Exception as exc:
        manifest['status'] = 'failed'; manifest['failure'] = str(exc)
        write(output/'manifest.json', manifest)
        raise
    write(output/'manifest.json', manifest)
    print(json.dumps({'status': manifest['status'], 'glb': str(output/'review/pet.glb')}), flush=True)

def review(args):
    run = Path(args.run).resolve(); manifest = read(run/'manifest.json'); evidence = read(args.evidence)
    if evidence.get('glb_sha256') != sha(run/'review/pet.glb'): raise ValueError('Review is for a different GLB')
    if not evidence.get('reviewer') or not evidence.get('notes'): raise ValueError('Reviewer and observations required')
    passed = all(evidence.get('checks', {}).get(k) is True for k in CHECKS)
    if args.accept and (not passed or not read(run/'validation.json')['passed']):
        raise ValueError('Cannot accept without all visual checks and technical validation')
    evidence['decision'] = 'accepted' if args.accept else 'rejected'
    evidence['reviewed_utc'] = dt.datetime.now(dt.timezone.utc).isoformat()
    write(run/'visual-review.json', evidence)
    manifest['visual_qa'] = evidence['decision']
    manifest['status'] = 'qa_accepted_awaiting_studio' if args.accept else 'qa_rejected'
    write(run/'manifest.json', manifest)
    print(manifest['status'])

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    sub=parser.add_subparsers(dest='command',required=True)
    p=sub.add_parser('generate')
    p.add_argument('--config',required=True)
    p.add_argument('--runtime-root',default=os.environ.get('AK_3D_ROOT','D:/AnimalKingdom3D'))
    p.add_argument('--output',required=True);p.set_defaults(func=generate)
    p=sub.add_parser('review')
    p.add_argument('--run',required=True);p.add_argument('--evidence',required=True)
    p.add_argument('--accept',action='store_true');p.set_defaults(func=review)
    args=parser.parse_args();args.func(args)

if __name__=='__main__': main()
