"""Approved front-facing source projection; inferred unseen surfaces are preserved."""
import sys
from common import context,write
cfg,out,root,pipeline=context()
sys.path.insert(0,str(pipeline/'vendor/TripoSR'))
import numpy as np
import trimesh
from PIL import Image
from scipy.ndimage import map_coordinates,distance_transform_edt
from tsr.bake_texture import rasterize_position_atlas
src=out/'generated';dest=out/'projected';dest.mkdir()
mesh=list(trimesh.load(src/'raw.glb',process=False).geometry.values())[0]
n=cfg['texture']['resolution'];projection=cfg['texture']['projection']
atlas=rasterize_position_atlas(mesh,np.arange(len(mesh.vertices)),mesh.faces,mesh.visual.uv,n,projection['padding'])
normal_mesh=trimesh.Trimesh(vertices=mesh.vertex_normals,faces=mesh.faces,process=False)
normals=rasterize_position_atlas(normal_mesh,np.arange(len(mesh.vertices)),mesh.faces,mesh.visual.uv,n,projection['padding'])
concept=np.asarray(Image.open(out/'concept.png').convert('RGBA'),dtype=np.float32)/255
ys,xs=np.where(concept[:,:,3]>.5);lo,hi=mesh.bounds
u=(atlas[:,:,1]-lo[1])/(hi[1]-lo[1])*(xs.max()-xs.min())+xs.min()
v=(hi[2]-atlas[:,:,2])/(hi[2]-lo[2])*(ys.max()-ys.min())+ys.min()
sample=np.stack([map_coordinates(concept[:,:,c],[v,u],order=1,mode='nearest') for c in range(4)],axis=-1)
base=np.asarray(Image.open(src/'basecolor.png').convert('RGBA'),dtype=np.float32)[::-1]/255
weight=np.clip((normals[:,:,0]-projection['normal_start'])/projection['normal_range'],0,1)*sample[:,:,3]*(atlas[:,:,3]>0)
if not projection['enabled']:weight[:]=0
result=base.copy();result[:,:,:3]=base[:,:,:3]*(1-weight[:,:,None])+sample[:,:,:3]*weight[:,:,None]
valid=atlas[:,:,3]>0
_,indices=distance_transform_edt(~valid,return_indices=True)
result[~valid]=result[indices[0][~valid],indices[1][~valid]];result[:,:,3]=1
image=Image.fromarray(np.uint8(np.clip(result[::-1],0,1)*255));image.save(dest/'basecolor.png')
mesh.visual.material.baseColorTexture=image;mesh.export(dest/'projected.glb')
write(dest/'projection.json',{'method':'approved front-facing source projection','settings':projection,
    'unseen_surface_source':'TripoSR','new_image_generated':False})
