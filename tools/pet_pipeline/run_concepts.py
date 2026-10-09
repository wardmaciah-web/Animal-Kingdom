"""Supervise local concept generation, including native crashes and interruptions."""
import argparse
import os
from pathlib import Path
import sys
import time

from pet_pipeline import HERE, read, write, supervise_worker, runtime_environment


def record_exit(output, returncode, elapsed):
    path = output / 'manifest.json'
    manifest = read(path) if path.exists() else {'candidates': []}
    manifest.update(worker_exit_code=returncode, elapsed_seconds=elapsed)
    if returncode != 0:
        manifest.update(status='failed', failure=manifest.get('failure') or
                        f'Concept worker exited with code {returncode}; see worker.log')
    elif manifest.get('status') != 'concepts_pending_visual_qa':
        manifest.update(status='failed', failure='Worker exited without a completed concept manifest')
    write(path, manifest)
    return manifest


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--config', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    root = Path(os.environ.get('AK_3D_ROOT', 'D:/AnimalKingdom3D')).resolve()
    output = Path(args.output).resolve()
    if not output.is_relative_to(root) or output.exists():
        raise ValueError('Choose a new output directory beneath the runtime root')
    # The worker owns directory creation; a sibling log also captures preflight failures.
    output.parent.mkdir(parents=True, exist_ok=True)
    log = output.with_suffix('.worker.log')
    started = time.monotonic()
    failure = None
    telemetry = output.with_suffix('.memory.jsonl')
    with log.open('x', encoding='utf-8') as stream:
        try:
            code = supervise_worker([sys.executable, '-u', str(HERE/'generate_concepts.py'),
                                    '--config', args.config, '--output', str(output)],
                                    root, stream, telemetry, env=runtime_environment(root))
        except (Exception, KeyboardInterrupt) as error:
            failure = f'{type(error).__name__}: {error}'
            stream.write(failure + '\n')
            code = -1
    output.mkdir(exist_ok=True)
    log.replace(output/'worker.log')
    if telemetry.exists(): telemetry.replace(output/'memory.jsonl')
    manifest = record_exit(output, code, time.monotonic()-started)
    if failure:
        manifest.update(status='blocked', failure=failure)
        write(output/'manifest.json', manifest)
    print(manifest['status'], output, flush=True)
    return 0 if manifest['status'] == 'concepts_pending_visual_qa' else 1


if __name__ == '__main__':
    raise SystemExit(main())
