"""MIT TripoSR reference-to-mesh baseline. No hosted generation or credentials.

Uses a documented CPU marching-cubes adapter in place of torchmcubes' CUDA
extension, so Windows needs no CUDA compiler. Neural inference stays on GPU.
This is not ForgeGUI's private model and does not promise equivalent quality.
"""
import argparse, hashlib, json, os, sys, time, types
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
for key, rel in {'HF_HOME':'cache/huggingface','TORCH_HOME':'cache/torch',
                 'U2NET_HOME':'cache/u2net','TEMP':'temp','TMP':'temp'}.items():
    os.environ[key] = str(ROOT / rel)
    (ROOT / rel).mkdir(parents=True, exist_ok=True)
os.environ['HF_HUB_DISABLE_SYMLINKS_WARNING'] = '1'
sys.path.insert(0, str(ROOT / 'tools/TripoSR'))

import numpy as np
import torch
from PIL import Image
from skimage.measure import marching_cubes

# torchmcubes returns xyz for a zyx grid; TripoSR swaps it back afterwards.
# Explicit adapter uses the same zero isosurface, with scikit-image on CPU.
adapter = types.ModuleType('torchmcubes')
def cpu_marching_cubes(volume, level):
    vertices, faces, _, _ = marching_cubes(volume.detach().cpu().numpy(), level)
    return torch.from_numpy(vertices[:, [2, 1, 0]].copy()), torch.from_numpy(faces.copy().astype(np.int64))
adapter.marching_cubes = cpu_marching_cubes
sys.modules['torchmcubes'] = adapter

# The supplied PNG already has alpha. Defer unused rembg/numba initialization.
import importlib.util
rembg_spec = importlib.util.find_spec('rembg')
rembg_spec.loader = importlib.util.LazyLoader(rembg_spec.loader)
rembg_lazy = importlib.util.module_from_spec(rembg_spec)
sys.modules['rembg'] = rembg_lazy
rembg_spec.loader.exec_module(rembg_lazy)

from tsr.system import TSR
from tsr.utils import resize_foreground, remove_background
from tsr.bake_texture import bake_texture
import tsr.bake_texture as texture_module
import trimesh

# Keep atlas queries on the same device as the neural field and bound memory.
def gpu_positions_to_colors(model, scene_code, positions_texture, texture_resolution):
    flat = positions_texture.reshape(-1, 4)
    colors = np.zeros_like(flat)
    valid = np.flatnonzero(flat[:, 3] > 0)
    with torch.inference_mode():
        for start in range(0, len(valid), 8192):
            ids = valid[start:start+8192]
            pos = torch.from_numpy(flat[ids, :3].copy()).to(scene_code.device)
            colors[ids, :3] = model.renderer.query_triplane(model.decoder, pos, scene_code)['color'].cpu().numpy()
            colors[ids, 3] = 1
    return colors.reshape(texture_resolution, texture_resolution, 4)
texture_module.positions_to_colors = gpu_positions_to_colors

def sha(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1024*1024), b''): h.update(block)
    return h.hexdigest()

parser = argparse.ArgumentParser()
parser.add_argument('--image', default=str(ROOT/'inputs/ocelot-reference.png'))
parser.add_argument('--output', default=str(ROOT/'outputs/ocelot-local-v1'))
parser.add_argument('--resolution', type=int, default=256)
parser.add_argument('--texture-resolution', type=int, default=4096)
args = parser.parse_args()
out = Path(args.output); out.mkdir(parents=True, exist_ok=True)
torch.manual_seed(42); np.random.seed(42)
started = time.time()
print('Loading pinned MIT TripoSR weights', flush=True)
weights = ROOT/'tools/TripoSR-weights'
# Read tensors only; do not execute checkpoint pickle globals.
from omegaconf import OmegaConf
cfg = OmegaConf.load(weights/'config.yaml'); OmegaConf.resolve(cfg)
torch.set_default_dtype(torch.float16)
model = TSR(cfg)
torch.set_default_dtype(torch.float32)
state = torch.load(weights/'model.ckpt', map_location='cpu', weights_only=True, mmap=True)
model.load_state_dict(state); del state
import gc
gc.collect()
model.eval().to('cuda:0'); model.renderer.set_chunk_size(4096)
source = Image.open(args.image).convert('RGBA')
if source.getextrema()[3][0] == 255:
    import rembg
    source = remove_background(source, rembg.new_session('u2net'))
source = resize_foreground(source, 0.85)
rgba = np.asarray(source, dtype=np.float32)/255
input_image = Image.fromarray(np.uint8(np.clip(rgba[:,:,:3]*rgba[:,:,3:4] + 0.5*(1-rgba[:,:,3:4]),0,1)*255))
input_image.save(out/'inference-input.png')
print('GPU inference', flush=True)
with torch.inference_mode(), torch.autocast('cuda', dtype=torch.float16):
    codes = model([input_image], device='cuda:0')
    torch.save(codes.cpu(), out/'scene-code.pt')
    print('Extracting original neural geometry', flush=True)
    mesh = model.extract_mesh(codes, False, resolution=args.resolution)[0]
    mesh.fix_normals()
    mesh.export(out/'untextured-source.ply')
    print('Baking neural color atlas (4K does not imply 4K learned detail)', flush=True)
    bake = bake_texture(mesh, model, codes[0], args.texture_resolution)
    atlas = Image.fromarray(np.uint8(np.clip(bake['colors'],0,1)*255)).transpose(Image.Transpose.FLIP_TOP_BOTTOM)
    atlas.save(out/'basecolor.png')
    textured = trimesh.Trimesh(vertices=mesh.vertices[bake['vmapping']], faces=bake['indices'], process=False)
    material = trimesh.visual.material.PBRMaterial(name='Ocelot_Local_Matte', baseColorTexture=atlas, metallicFactor=0.0, roughnessFactor=0.85, alphaMode='OPAQUE')
    textured.visual = trimesh.visual.texture.TextureVisuals(uv=bake['uvs'], material=material)
    textured.export(out/'ocelot-local-raw.glb')
manifest = {'status':'generated_not_approved','backend':'TripoSR local CUDA inference',
 'weights_repo':'stabilityai/TripoSR','weights_revision':'5b521936b01fbe1890f6f9baed0254ab6351c04a',
 'weights_sha256':sha(weights/'model.ckpt'),'input_sha256':sha(args.image),
 'original_geometry':True,'reused_bear_mesh':False,'credits_used':0,
 'seed':42,'mc_resolution':args.resolution,'texture_resolution':args.texture_resolution,
 'triangles':len(textured.faces),'vertices':len(textured.vertices),
 'runtime_seconds':time.time()-started,'torch':torch.__version__,
 'gpu':torch.cuda.get_device_name(),'peak_vram_bytes':torch.cuda.max_memory_allocated(),
 'extraction':'scikit-image CPU marching cubes adapter; no neural model changes',
 'limitations':['Single image; unseen surfaces inferred','No independent generated normal/PBR maps','4096 atlas does not restore missing learned fur detail'],
 'outputs':{p.name:{'bytes':p.stat().st_size,'sha256':sha(p)} for p in out.iterdir() if p.is_file()}}
(out/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps(manifest,indent=2), flush=True)
