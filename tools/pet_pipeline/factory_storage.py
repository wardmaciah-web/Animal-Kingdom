"""Owned scratch lifecycle. No age-based, recursive, or legacy-output deletion."""
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import uuid

from pet_pipeline import HERE, read, write, sha

DISPOSABLE = {'work/generated/scene-code.pt', 'work/generated/source.ply',
              'work/generated/raw.glb', 'work/projected/projected.glb'}
QA_CHECKS = ('durable_import', 'registration', 'physical_tree_reward', 'rarity',
             'weight', 'income', 'inventory', 'held', 'followers', 'sanctuary',
             'index', 'save_rejoin', 'server_ownership', 'biome_locked')
REQUIRED = ('work/review/pet.glb', 'work/review/pet.blend',
            'work/projected/basecolor.png',
            'work/effective-config.json', 'work/validation.json',
            'work/visual-review.json', 'work/manifest.json', 'references/manifest.json')


def safe_path(root, relative):
    """Reject traversal, symlinks, junctions, reparse points and hard links."""
    root = Path(root).absolute()
    relative = Path(relative)
    if relative.is_absolute() or '..' in relative.parts:
        raise ValueError('Unsafe relative path')
    target = root / relative
    # Inspect ancestors too: a junction at scratch/jobs must not redirect writes.
    for part in [target, *target.parents]:
        if part.exists() or part.is_symlink():
            info = part.lstat()
            if stat.S_ISLNK(info.st_mode) or getattr(info, 'st_file_attributes', 0) & 0x400:
                raise ValueError(f'Linked/reparse path refused: {part}')
            if part.is_file() and info.st_nlink != 1:
                raise ValueError(f'Hard-linked file refused: {part}')
    if not target.resolve().is_relative_to(root.resolve()):
        raise ValueError('Path escapes designated directory')
    # Refuse any Git checkout, even a nested worktree with a .git file.
    if any((parent/'.git').exists() for parent in [target, *target.parents]):
        raise ValueError('Factory storage cannot be a Git checkout')
    return target


def job_path(root, run_id):
    if not re.fullmatch(r'[0-9a-f]{32}', run_id):
        raise ValueError('Invalid run ID')
    return safe_path(root, f'scratch/jobs/{run_id}')


def new_job(root, pet_id):
    run_id = uuid.uuid4().hex
    job = job_path(root, run_id)
    job.mkdir(parents=True, exist_ok=False)
    write(job/'owner.json', {'schema_version':1, 'owner':'animal-kingdom-pet-factory',
                            'run_id':run_id, 'pet_id':pet_id})
    (job/'tmp').mkdir()
    return run_id, job


def owner(root, run_id):
    job = job_path(root, run_id)
    record = read(safe_path(job, 'owner.json'))
    if record.get('owner') != 'animal-kingdom-pet-factory' or record.get('run_id') != run_id:
        raise ValueError('Not a factory-created scratch job')
    return job, record


def inventory(root, run_id):
    """Called only after the owned worker exits. Unknown later files stay put."""
    job, record = owner(root, run_id)
    entries = {}
    for path in job.rglob('*'):
        path = safe_path(job, path.relative_to(job))
        if not path.is_file(): continue
        relative = path.relative_to(job).as_posix()
        if relative in DISPOSABLE or relative.startswith('tmp/'):
            entries[relative] = {'sha256':sha(path), 'bytes':path.stat().st_size}
    record['disposable'] = entries
    write(job/'owner.json', record)
    return record


def archive(root, run_id):
    """Retain every non-disposable file, final textures, editable sources and refs."""
    job, record = owner(root, run_id)
    work = job/'work'
    manifest = read(work/'manifest.json')
    if manifest.get('visual_qa') != 'accepted' or not read(work/'validation.json').get('passed'):
        raise ValueError('Archive requires technical and visual approval')
    cfg = read(work/'effective-config.json')
    sources = [safe_path(job, path.relative_to(job)) for path in work.rglob('*')]
    required_space = sum(path.stat().st_size for path in sources if path.is_file())
    if shutil.disk_usage(root).free < required_space + 10*1024**3:
        raise RuntimeError('Insufficient storage to preserve archive plus 10 GiB reserve')
    refs = safe_path(job, 'references'); refs.mkdir(exist_ok=True)
    ref_manifest = {}
    for source in [cfg['concept_image'], *cfg['style_references']]:
        source = Path(source)
        digest = sha(source)
        target = safe_path(refs, digest + source.suffix)
        if not target.exists(): shutil.copy2(source, target)
        ref_manifest[str(source)] = {'file':target.name, 'sha256':digest}
    write(refs/'manifest.json', ref_manifest)
    record = inventory(root, run_id)
    destination = safe_path(root, f'approved/{run_id}')
    destination.mkdir(parents=True, exist_ok=True)
    kept = {}
    for source in job.rglob('*'):
        source = safe_path(job, source.relative_to(job))
        if not source.is_file(): continue
        relative = source.relative_to(job).as_posix()
        if relative in record['disposable']: continue
        target = safe_path(destination, relative)
        target.parent.mkdir(parents=True, exist_ok=True)
        digest = sha(source)
        if target.exists() and sha(target) != digest:
            raise ValueError(f'Archive conflict; approved files never overwritten: {relative}')
        if not target.exists(): shutil.copy2(source, target)
        if sha(target) != digest: raise ValueError('Archive copy verification failed')
        kept[relative] = digest
    if not all(name in kept for name in REQUIRED):
        raise ValueError('Archive lacks required editable source, final asset or QA')
    preservation = {'run_id':run_id, 'pet_id':record['pet_id'], 'files':kept}
    path = destination/'preservation.json'
    if path.exists() and read(path) != preservation:
        raise ValueError('Preservation manifest is immutable')
    write(path, preservation)
    template = destination/'verification.template.json'
    if not template.exists():
        write(template, {'run_id':run_id, 'pet_id':record['pet_id'],
            'glb_sha256':kept['work/review/pet.glb'], 'preservation_sha256':sha(path),
            'checks':{name:False for name in QA_CHECKS}, 'roblox_assets':[],
            'evidence_files':{}, 'receipt_path':'',
            'instructions':'Record actual Studio evidence and asset IDs; commit and push the filled receipt without a commit field. Add full commit SHA to a runtime copy only, then factory verify.'})
    return path


def validate_receipt(root, run_id, receipt, repo):
    """Require a pushed, immutable QA receipt for this exact archive/GLB."""
    job, record = owner(root, run_id)
    if receipt.get('run_id') != run_id or receipt.get('pet_id') != record['pet_id']:
        raise ValueError('Receipt belongs to another run/species')
    if not all(receipt.get('checks', {}).get(check) is True for check in QA_CHECKS):
        raise ValueError('Durable import, registration and complete Studio QA required')
    assets = receipt.get('roblox_assets', [])
    if not assets or not all(int(a.get('mesh_id', 0)) > 0 and int(a.get('texture_id', 0)) > 0 for a in assets):
        raise ValueError('Actual Roblox mesh and texture IDs required')
    archive_dir = safe_path(root, f'approved/{run_id}')
    preservation_path = safe_path(archive_dir, 'preservation.json')
    if sha(preservation_path) != receipt.get('preservation_sha256'):
        raise ValueError('Archive is not bound to this receipt')
    preservation = read(preservation_path)
    if not all(name in preservation['files'] for name in REQUIRED):
        raise ValueError('Required preserved files missing')
    for relative, digest in preservation['files'].items():
        if sha(safe_path(archive_dir, relative)) != digest:
            raise ValueError(f'Preserved file changed: {relative}')
    if receipt.get('glb_sha256') != preservation['files']['work/review/pet.glb']:
        raise ValueError('QA is for another GLB')
    if not receipt.get('evidence_files'):
        raise ValueError('Studio evidence files required')
    # The receipt and its evidence must already exist identically in a pushed
    # Git commit. Merely uploading a Roblox asset cannot authorize cleanup.
    commit = receipt.get('commit', '')
    if not re.fullmatch(r'[0-9a-f]{40}', commit): raise ValueError('Full Git commit required')
    def git(*args):
        return subprocess.check_output(['git','-C',str(repo),*args], timeout=30)
    remote = git('remote','get-url','origin').decode().strip()
    if remote not in ('https://github.com/wardmaciah-web/Animal-Kingdom.git',
                      'git@github.com:wardmaciah-web/Animal-Kingdom.git'):
        raise ValueError('Checkpoint must be in canonical repository')
    remote_head = git('ls-remote','origin','refs/heads/main').decode().split()[0]
    git('merge-base','--is-ancestor',commit,remote_head)
    # Checkpoint stores the receipt without its self-referential commit field.
    committed_receipt = dict(receipt); committed_receipt.pop('commit')
    import json
    saved = json.loads(git('show',f'{commit}:{receipt["receipt_path"]}'))
    if saved != committed_receipt: raise ValueError('Receipt differs from pushed checkpoint')
    import hashlib
    for relative, digest in receipt['evidence_files'].items():
        if hashlib.sha256(git('show',f'{commit}:{relative}')).hexdigest() != digest:
            raise ValueError('Studio evidence differs from checkpoint')
    return job, record


def cleanup(root, run_id, receipt, repo=HERE.parents[1]):
    job, record = validate_receipt(root, run_id, receipt, repo)
    targets = []
    for relative, entry in record.get('disposable', {}).items():
        if relative not in DISPOSABLE and not relative.startswith('tmp/'):
            raise ValueError('Manifest attempts to delete a non-disposable file')
        path = safe_path(job, relative)
        if not path.exists(): continue  # Crash-safe, idempotent restart.
        if sha(path) != entry['sha256'] or path.stat().st_size != entry['bytes']:
            raise ValueError('Disposable file changed after inventory; preserving it')
        targets.append((relative, path, entry))
    journal = safe_path(job, 'cleanup.json')
    result = {'run_id':run_id, 'commit':receipt['commit'], 'status':'deleting',
              'files':{rel:entry for rel, _, entry in targets}}
    if not journal.exists(): write(journal, result)
    for relative, _, entry in targets:
        path = safe_path(job, relative)  # Recheck immediately before each unlink.
        if sha(path) != entry['sha256']: raise ValueError('File changed during cleanup')
        path.unlink()  # No recursive delete, wildcard, or cross-shell operation.
    result.update(status='complete', deleted_bytes=sum(x[2]['bytes'] for x in targets))
    if targets or read(journal).get('status') != 'complete': write(journal, result)
    return read(journal)


def reclaim_verified(root):
    results = []
    jobs = safe_path(root, 'scratch/jobs')
    if not jobs.exists(): return results
    for job in jobs.iterdir():
        try:
            path = job_path(root, job.name)
            receipt = safe_path(path, 'verification.json')
            if receipt.is_file(): results.append(cleanup(root, job.name, read(receipt)))
        except Exception as error:
            results.append({'run_id':job.name, 'preserved':True, 'reason':str(error)})
    return results


def disk_gate(root, minimum=10*1024**3):
    before = shutil.disk_usage(root).free
    reclaimed = reclaim_verified(root) if before < minimum else []
    after = shutil.disk_usage(root).free
    report = {'free_before':before, 'free_after':after, 'minimum':minimum,
              'cleanup':reclaimed, 'passed':after >= minimum}
    if not report['passed']: raise RuntimeError(f'Disk gate blocked: {report}')
    return report
