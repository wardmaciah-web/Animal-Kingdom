"""Bake supplied concept detail onto visible front, retain neural unseen surfaces."""
import os, sys, json
from pathlib import Path
root=Path(os.environ.get('AK_3D_ROOT', 'E:/AnimalKingdom3D'))
sys.path.insert(0,str(root/'tools/TripoSR'))
import numpy as np
import trimesh
from PIL import Image
from scipy.ndimage import map_coordinates, distance_transform_edt
from tsr.bake_texture import rasterize_position_atlas
src=root/'outputs/ocelot-free-resume-v1'
out=src/'refined';out.mkdir(exist_ok=True)
scene=trimesh.load(src/'ocelot-local-raw.glb',process=False)
mesh=list(scene.geometry.values())[0]
n=2048
atlas=rasterize_position_atlas(mesh,np.arange(len(mesh.vertices)),mesh.faces,mesh.visual.uv,n,8)
normal_mesh=trimesh.Trimesh(vertices=mesh.vertex_normals,faces=mesh.faces,process=False)
normals=rasterize_position_atlas(normal_mesh,np.arange(len(mesh.vertices)),mesh.faces,mesh.visual.uv,n,8)
concept=np.asarray(Image.open(root/'inputs/ocelot-reference.png').convert('RGBA'),dtype=np.float32)/255
ys,xs=np.where(concept[:,:,3]>.5)
lo,hi=mesh.bounds
u=(atlas[:,:,1]-lo[1])/(hi[1]-lo[1])*(xs.max()-xs.min())+xs.min()
v=(hi[2]-atlas[:,:,2])/(hi[2]-lo[2])*(ys.max()-ys.min())+ys.min()
sample=np.stack([map_coordinates(concept[:,:,c],[v,u],order=1,mode='nearest') for c in range(4)],axis=-1)
base=np.asarray(Image.open(src/'basecolor.png').convert('RGBA'),dtype=np.float32)[::-1]/255
# Project only surfaces facing the reference camera. Keep inferred back texture.
weight=np.clip((normals[:,:,0]-.15)/.6,0,1)*sample[:,:,3]*(atlas[:,:,3]>0)
result=base.copy();result[:,:,:3]=base[:,:,:3]*(1-weight[:,:,None])+sample[:,:,:3]*weight[:,:,None]
# Pad islands into unused atlas pixels, preventing black seams under filtering.
valid=atlas[:,:,3]>0
_,indices=distance_transform_edt(~valid,return_indices=True)
result[~valid]=result[indices[0][~valid],indices[1][~valid]]
result[:,:,3]=1
image=Image.fromarray(np.uint8(np.clip(result[::-1],0,1)*255))
image.save(out/'basecolor.png')
mesh.visual.material.baseColorTexture=image
mesh.export(out/'ocelot-projected.glb')
(out/'projection.json').write_text(json.dumps({'method':'front-facing concept projection; neural texture retained on unseen surfaces','concept':'ocelot-v7.png','resolution':n,'generated_new_image':False},indent=2))
