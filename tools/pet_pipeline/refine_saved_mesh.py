"""Review a Blender repair without regenerating or overwriting the neural source."""
import argparse
from pathlib import Path
import shutil
import subprocess
from pet_pipeline import HERE, configure, python_in, read, sha, write


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--source',required=True)
    parser.add_argument('--config',required=True)
    parser.add_argument('--output',required=True)
    args=parser.parse_args()
    source=Path(args.source).resolve();output=Path(args.output).resolve()
    original=read(source/'effective-config.json');root=Path(original['runtime_root'])
    if output.exists() or not output.is_relative_to(root.resolve()):
        raise ValueError('Use a new output directory beneath the runtime root')
    cfg=configure(args.config,root,output)
    if cfg['pet_id']!=original['pet_id']:
        raise ValueError('Saved geometry cannot be reused as another species')
    if sha(cfg['concept_image'])!=sha(original['concept_image']):
        raise ValueError('Repair recipe must retain the source concept')
    output.mkdir(parents=True)
    shutil.copytree(source/'projected',output/'projected')
    effective=output/'effective-config.json';write(effective,cfg)
    manifest={'pet_id':cfg['pet_id'],'status':'refining','visual_qa':'pending',
              'studio_qa':'pending','credits_used':0,'fresh_inference':False,
              'source_run':str(source),'source_mesh_sha256':sha(source/'projected/projected.glb'),
              'config_sha256':sha(effective),'stages':[]}
    write(output/'manifest.json',manifest)
    for stage,environment in [('refine','blender-env'),('validate','deps-stage')]:
        with (output/f'{stage}.log').open('w') as log:
            result=subprocess.run([str(python_in(root,environment)),str(HERE/'workers'/f'{stage}.py'),
                                   '--config',str(effective)],stdout=log,stderr=subprocess.STDOUT)
        manifest['stages'].append({'name':stage,'exit_code':result.returncode})
        write(output/'manifest.json',manifest)
        if result.returncode:
            manifest.update(status='failed',failure=f'{stage} failed; see log')
            write(output/'manifest.json',manifest)
            return 1
    manifest.update(status='technical_pass_pending_visual',glb_sha256=sha(output/'review/pet.glb'))
    write(output/'manifest.json',manifest)
    return 0


if __name__=='__main__':raise SystemExit(main())
