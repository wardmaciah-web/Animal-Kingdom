import sys
sys.path.insert(0,'D:/AnimalKingdom3D/github-review/tools/pet_pipeline/workers')
"""The approved Ocelot inference method, parameterized without changing its model."""
import gc, importlib.util, sys, time, types, faulthandler
faulthandler.enable()
print('Loading inference dependencies',flush=True)
from common import context,write,sha
cfg,out,root,pipeline=context()
sys.path.insert(0,str(pipeline/'vendor/TripoSR'))
import numpy as np
import torch
torch.set_num_threads(1)
import trimesh
from PIL import Image
from skimage.measure import marching_cubes
from omegaconf import OmegaConf

adapter=types.ModuleType('torchmcubes')
def cpu_marching_cubes(volume,level):
    vertices,faces,_,_=marching_cubes(volume.detach().cpu().numpy(),level)
    return torch.from_numpy(vertices[:,[2,1,0]].copy()),torch.from_numpy(faces.copy().astype(np.int64))
adapter.marching_cubes=cpu_marching_cubes
sys.modules['torchmcubes']=adapter
spec=importlib.util.find_spec('rembg');spec.loader=importlib.util.LazyLoader(spec.loader)
lazy=importlib.util.module_from_spec(spec);sys.modules['rembg']=lazy;spec.loader.exec_module(lazy)
print('Loading TripoSR modules',flush=True)
from tsr.system import TSR
from tsr.utils import resize_foreground
import tsr.bake_texture as bake_module

def gpu_positions_to_colors(model,scene_code,positions_texture,resolution):
    flat=positions_texture.reshape(-1,4);colors=np.zeros_like(flat)
    valid=np.flatnonzero(flat[:,3]>0)
    with torch.inference_mode():
        for start in range(0,len(valid),cfg['texture']['query_chunk']):
            ids=valid[start:start+cfg['texture']['query_chunk']]
            query_positions=flat[ids,:3].copy();query_positions[:,0]/=.975
            pos=torch.from_numpy(query_positions).to(scene_code.device)
            colors[ids,:3]=model.renderer.query_triplane(model.decoder,pos,scene_code)['color'].cpu().numpy()
            colors[ids,3]=1
    return colors.reshape(resolution,resolution,4)
bake_module.positions_to_colors=gpu_positions_to_colors

print('Initializing pinned model',flush=True)
started=time.time();g=cfg['generation'];t=cfg['texture'];gen=out/'generated';gen.mkdir()
torch.manual_seed(g['seed']);np.random.seed(g['seed'])
if not torch.cuda.is_available():raise RuntimeError('The approved CUDA workflow requires a working NVIDIA GPU')
weights=root/'tools/TripoSR-weights'
model_cfg=OmegaConf.load(weights/'config.yaml');OmegaConf.resolve(model_cfg)
torch.set_default_dtype(torch.float16)
if g.get('checkpoint_loading')=='cuda_constructor':
    with torch.device('cuda:0'):model=TSR(model_cfg)
else:model=TSR(model_cfg)
torch.set_default_dtype(torch.float32)
state=torch.load(weights/'model.ckpt',map_location='cpu',weights_only=True,mmap=True)
if g.get('checkpoint_loading','approved_cpu_copy')=='cuda_streamed':
    # Same FP16 weights, transferred one tensor at a time; avoid the Windows
    # native CPU copy path that also crashes in the preserved original script.
    state={k:v.to(device='cuda:0',dtype=torch.float16 if v.is_floating_point() else v.dtype)
           for k,v in state.items()}
    model.load_state_dict(state,assign=True)
else:model.load_state_dict(state)
del state;gc.collect()
model.eval().to('cuda:0');model.renderer.set_chunk_size(g['renderer_chunk'])

from rasterize import rasterize_position_atlas
bake_module.rasterize_position_atlas=rasterize_position_atlas
geo=np.load(root/'outputs/tapir-d-reunwrap-012/optimized-geometry.npz')
mesh=trimesh.Trimesh(vertices=geo['vertices'],faces=geo['faces'],process=False)
mesh.update_faces(mesh.unique_faces() & mesh.nondegenerate_faces());mesh.remove_unreferenced_vertices();mesh.fix_normals()
codes=torch.load(root/'outputs/tapir-d-frontal-fresh-007/generated/scene-code.pt',weights_only=True).to('cuda:0')
with torch.inference_mode(),torch.autocast('cuda',dtype=torch.float16):
    print('Rebake saved neural field onto optimized geometry',flush=True)
    bake=bake_module.bake_texture(mesh,model,codes[0],t['resolution'])
atlas=Image.fromarray(np.uint8(np.clip(bake['colors'],0,1)*255)).transpose(Image.Transpose.FLIP_TOP_BOTTOM);atlas.save(gen/'basecolor.png')
textured=trimesh.Trimesh(vertices=mesh.vertices[bake['vmapping']],faces=bake['indices'],vertex_normals=mesh.vertex_normals[bake['vmapping']],process=False)
material=trimesh.visual.material.PBRMaterial(name='Pet_Local_Matte',baseColorTexture=atlas,metallicFactor=0.,roughnessFactor=.85,alphaMode='OPAQUE')
textured.visual=trimesh.visual.texture.TextureVisuals(uv=bake['uvs'],material=material);textured.export(gen/'raw.glb')
write(out/'diagnostic-provenance.json',{'fresh_inference':False,'source_run':'tapir-d-frontal-fresh-007','method':'Optimize mesh then bake same TripoSR neural field on new UVs; no reference mesh material or geometry transfer','scene_code_sha256':sha(root/'outputs/tapir-d-frontal-fresh-007/generated/scene-code.pt'),'credits_used':0})
print('Neural rebake completed',flush=True)
