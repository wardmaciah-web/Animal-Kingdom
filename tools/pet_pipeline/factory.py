"""Resumable production queue; art and Studio gates are explicit, never inferred."""
import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import subprocess

from pet_pipeline import (HERE, read, write, sha, preflight, check_hardware,
                          generation_lock, python_in, runtime_environment)
from factory_storage import (new_job, job_path, inventory, archive, cleanup,
                             disk_gate, safe_path, validate_receipt)


def fingerprint(config):
    """Semantic recipe plus referenced image bytes, not its filename/formatting."""
    path = Path(config).resolve(); cfg = read(path)
    references = {}
    for field in ('concept_image', 'design_reference_image', 'approved_front_render'):
        if cfg.get(field): references[field] = sha((path.parent/cfg[field]).resolve())
    references['style_references'] = [sha((path.parent/p).resolve()) for p in cfg.get('style_references', [])]
    return hashlib.sha256(json.dumps({'config':cfg, 'references':references}, sort_keys=True).encode()).hexdigest()


def seed_queue():
    roster = read(HERE/'roster.json')['pets']; policy = read(HERE/'production-policy.json')
    # Roster order already follows the canonical biome order. Prioritize the
    # current Jungle species without changing reward definitions or unlocks.
    rows = [r for r in roster if not r['registered']]
    rows.sort(key=lambda r: r['pet_id'] != policy['next_species'])
    return {'schema_version':1, 'pets':[{'pet_id':r['pet_id'], 'biome':r['biome'],
        'state':'needs_recipe', 'attempts':[],
        'family':r['proposed_family_id']} for r in rows]}


def assign_recipe(queue, pet_id, config, kind, reason):
    row = next(r for r in queue['pets'] if r['pet_id'] == pet_id)
    if row['state'] in ('running', 'awaiting_visual', 'awaiting_studio', 'awaiting_save', 'complete'):
        raise ValueError('Resolve existing art/Studio work before assigning another recipe')
    cfg = read(config)
    if cfg['pet_id'] != pet_id: raise ValueError('Recipe belongs to another pet')
    digest = fingerprint(config)
    if any(a['fingerprint'] == digest for a in row['attempts']):
        raise ValueError('This candidate was already attempted; change its configuration')
    if row['attempts'] and not reason.strip(): raise ValueError('Changed recipe needs an evidence-based reason')
    policy = read(HERE/'production-policy.json')
    if pet_id in policy.get('deferred_species', {}):
        raise ValueError(policy['deferred_species'][pet_id])
    if kind == 'model' and cfg.get('concept_review', {}).get('decision') != 'approved_for_reconstruction':
        raise ValueError('Model recipe requires an explicitly reviewed concept')
    row.update(config=str(Path(config).resolve()), kind=kind, fingerprint=digest,
               change_reason=reason, state='ready')


def run_ready(root, queue, queue_path):
    """Run sequentially until review, hardware or the next biome gate blocks."""
    for row in queue['pets']:
        if row['state'] == 'running':
            # Never infer success after supervisor interruption. OS lock probe
            # prevents treating a surviving child as an exited worker.
            with generation_lock(root):
                row.update(state='interrupted', failure='Inspect preserved run before choosing a changed recipe')
                write(queue_path, queue)
        if row['state'] in ('awaiting_concept_review', 'awaiting_visual', 'awaiting_studio', 'awaiting_save'):
            return row['state']
        if row['state'] != 'ready': continue
        earlier_biomes = [p for p in queue['pets'] if p['biome'] != row['biome']]
        biome_order = list(dict.fromkeys(p['biome'] for p in queue['pets']))
        if any(p['state'] != 'complete' and biome_order.index(p['biome']) < biome_order.index(row['biome'])
               for p in earlier_biomes):
            return 'earlier_biome_incomplete'
        try:
            with generation_lock(root):
                hardware = preflight(root)
                write(root/'factory/preflight.json', hardware)
                check_hardware(hardware)
                row['disk_before'] = disk_gate(root)
        except Exception as error:
            queue['blocked'] = str(error); write(queue_path, queue)
            return 'resource_blocked'
        if fingerprint(row['config']) != row['fingerprint']:
            raise ValueError('Recipe changed after queue admission; assign it again')
        if any(a['fingerprint'] == row['fingerprint'] for a in row['attempts']):
            raise ValueError('Repeated unchanged candidate refused')
        run_id, job = new_job(root, row['pet_id'])
        row.update(state='running', run_id=run_id)
        attempt = {'run_id':run_id, 'fingerprint':row['fingerprint'],
                   'config':row['config'], 'started_utc':dt.datetime.now(dt.timezone.utc).isoformat()}
        row['attempts'].append(attempt); queue.pop('blocked', None); write(queue_path, queue)
        env = runtime_environment(root, job/'tmp'); env['AK_JOB_SCRATCH'] = str(job/'tmp')
        output = job/'work'
        command = ([str(python_in(root, 'concept-env')), str(HERE/'run_concepts.py')]
                   if row['kind'] == 'concept' else
                   [str(python_in(root, 'deps-stage')), str(HERE/'pet_pipeline.py'), 'generate', '--runtime-root', str(root)])
        command += ['--config', row['config'], '--output', str(output)]
        # Controllers supervise their direct workers. Never start a second job
        # until this controller and its worker have returned.
        with (job/'controller.log').open('x') as log:
            result = subprocess.run(command, env=env, stdout=log, stderr=subprocess.STDOUT)
        attempt['exit_code'] = result.returncode
        inventory(root, run_id)
        hardware = preflight(root); attempt['resources_after'] = hardware
        manifest = read(output/'manifest.json') if (output/'manifest.json').exists() else {}
        expected = 'concepts_pending_visual_qa' if row['kind']=='concept' else 'technical_pass_pending_visual'
        if result.returncode or manifest.get('status') != expected:
            row.update(state='failed', failure=manifest.get('failure', 'Worker did not complete'))
            write(queue_path, queue)
            try: check_hardware(hardware)
            except Exception as error:
                queue['blocked'] = str(error); write(queue_path, queue); return 'resource_blocked'
            continue
        row['state'] = 'awaiting_concept_review' if row['kind']=='concept' else 'awaiting_visual'
        write(queue_path, queue)
        return row['state']
    return 'no_ready_recipes'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--runtime-root', default='D:/AnimalKingdom3D')
    commands = parser.add_subparsers(dest='command', required=True)
    commands.add_parser('init'); commands.add_parser('run'); commands.add_parser('status')
    add = commands.add_parser('assign')
    add.add_argument('--pet', required=True); add.add_argument('--config', required=True)
    add.add_argument('--kind', choices=('concept','model'), required=True); add.add_argument('--reason', default='')
    for name in ('archive', 'verify', 'reject'):
        sub = commands.add_parser(name); sub.add_argument('--pet', required=True)
        if name == 'verify': sub.add_argument('--receipt', required=True)
        if name == 'reject': sub.add_argument('--reason', required=True)
    args = parser.parse_args(); root = Path(args.runtime_root).resolve()
    runtime_environment(root)
    state_dir = safe_path(root, 'factory'); state_dir.mkdir(exist_ok=True)
    queue_path = state_dir/'queue.json'
    with generation_lock(state_dir):
        if args.command == 'init':
            if queue_path.exists(): raise ValueError('Queue already exists; use status or run')
            write(queue_path, seed_queue()); print(queue_path); return
        queue = read(queue_path)
        if args.command == 'assign':
            assign_recipe(queue, args.pet, args.config, args.kind, args.reason)
            write(queue_path, queue)
        elif args.command == 'run':
            status = run_ready(root, queue, queue_path); print(status)
            return 3 if status == 'resource_blocked' else 0
        elif args.command == 'status':
            from collections import Counter
            print(json.dumps({'states':dict(Counter(p['state'] for p in queue['pets'])),
                              'blocked':queue.get('blocked')}, indent=2))
        else:
            row = next(p for p in queue['pets'] if p['pet_id']==args.pet)
            if args.command == 'reject':
                if row['state'] not in ('awaiting_concept_review','awaiting_visual','awaiting_studio'):
                    raise ValueError('No pending candidate to reject')
                row.update(state='failed', failure=args.reason)
            else:
                with generation_lock(root):
                    if args.command == 'archive':
                        if row['state'] not in ('awaiting_visual','awaiting_studio','awaiting_save'):
                            raise ValueError('No completed model to archive')
                        print(archive(root, row['run_id']))
                        row['state'] = 'awaiting_studio'
                    else:
                        if row['state'] not in ('awaiting_studio','awaiting_save','complete'):
                            raise ValueError('Archive and Studio verification must precede cleanup')
                        receipt = read(args.receipt)
                        validate_receipt(root, row['run_id'], receipt, HERE.parents[1])
                        # Persist verification before deletion so an interrupted
                        # cleanup can resume from the same immutable checkpoint.
                        write(job_path(root, row['run_id'])/'verification.json', receipt)
                        write(safe_path(root, f'approved/{row["run_id"]}/verification.json'), receipt)
                        row['state']='awaiting_save'; write(queue_path, queue)
                        result = cleanup(root, row['run_id'], receipt)
                        row.update(state='complete', cleanup=result, commit=receipt['commit'])
            write(queue_path, queue)
            if args.command == 'verify': print(run_ready(root, queue, queue_path))


if __name__ == '__main__': raise SystemExit(main())
