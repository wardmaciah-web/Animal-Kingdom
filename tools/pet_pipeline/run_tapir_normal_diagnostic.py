"""One bounded saved-mesh diagnostic; never performs Tapir inference."""
import os,shutil,subprocess
from pathlib import Path
from pet_pipeline import HERE,preflight,check_hardware,read,write,python_in
root=Path(os.environ.get('AK_3D_ROOT','D:/AnimalKingdom3D'))
hardware=preflight(root);write(HERE/'audits/next-species-preflight.json',hardware)
check_hardware(hardware)
source=root/'outputs/tapir-d-coat-022';out=root/'outputs/tapir-d-surface-normals-023'
if out.exists():raise ValueError('Diagnostic already attempted; do not repeat it')
out.mkdir();shutil.copytree(source/'projected',out/'projected')
cfg=read(source/'effective-config.json');cfg['output_directory']=str(out)
cfg['refinement']['fur']['shading_normals']='supporting_surface'
write(out/'effective-config.json',cfg);write(out/'preflight.json',hardware)
write(out/'diagnostic-provenance.json',{'fresh_inference':False,'source':'tapir-d-coat-022',
 'change':'Only opt-in supporting-surface fur normals','approved':False,'credits_used':0})
for stage,env in [('refine','blender-env'),('validate','deps-stage')]:
    with (out/f'{stage}.log').open('w') as log:
        worker=(HERE/'audits/tapir-bounded-diagnostic/refine_surface_normals.py') if stage=='refine' else (HERE/'workers/validate.py')
        result=subprocess.run([str(python_in(root,env)),str(worker),
            '--config',str(out/'effective-config.json')],stdout=log,stderr=subprocess.STDOUT)
    if result.returncode:raise RuntimeError(f'{stage} failed; preserve diagnostic and defer Tapir')
print(out,flush=True)
