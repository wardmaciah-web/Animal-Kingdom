"""Project owned species concept renders, never their mesh, onto fresh TripoSR UVs."""
import sys
from pathlib import Path
import numpy as np
import trimesh
from PIL import Image
from scipy.ndimage import map_coordinates,distance_transform_edt
pipeline=Path('D:/AnimalKingdom3D/github-review/tools/pet_pipeline');sys.path.insert(0,str(pipeline));import pet_pipeline as pp
sys.path.insert(0,str(pipeline/'workers'));from rasterize import rasterize_position_atlas
root=Path('D:/AnimalKingdom3D');out=root/'outputs/tapir-d-reunwrap-012';out.mkdir(exist_ok=True)
cfg=pp.read(pipeline/'configs/tapir-front-diagnostic.json');cfg['refinement']['smooth_iterations']=10
effective=pp.configure(pipeline/'configs/tapir-front-diagnostic.json',root,out);effective['refinement']=cfg['refinement'];effective['refinement']['smooth_iterations']=0;effective['refinement']['fur']['exclusions']=[{'normal_y_max':1.1,'z_min':1.4,'z_max':2.8}];pp.write(out/'effective-config.json',effective)
src=root/'outputs/tapir-d-frontal-fresh-007/generated';dest=out/'projected';dest.mkdir()
import xatlas
geo=np.load(out/'optimized-geometry.npz');original=trimesh.Trimesh(vertices=geo['vertices'],faces=geo['faces'],process=False)
original.update_faces(original.unique_faces() & original.nondegenerate_faces());original.remove_unreferenced_vertices();print('clean triangles',len(original.faces),flush=True)
atlas=xatlas.Atlas();atlas.add_mesh(original.vertices,original.faces);pack=xatlas.PackOptions();pack.resolution=2048;pack.padding=8;atlas.generate(pack_options=pack);vm,faces,uv=atlas[0]
mesh=trimesh.Trimesh(vertices=original.vertices[vm],faces=faces,vertex_normals=original.vertex_normals[vm],process=False)
mesh.visual=trimesh.visual.TextureVisuals(uv=uv,material=trimesh.visual.material.PBRMaterial(roughnessFactor=.85,metallicFactor=0));n=2048
pos=rasterize_position_atlas(mesh,np.arange(len(mesh.vertices)),mesh.faces,mesh.visual.uv,n,8)
normalmesh=trimesh.Trimesh(vertices=mesh.vertex_normals,faces=mesh.faces,process=False)
normals=rasterize_position_atlas(normalmesh,np.arange(len(mesh.vertices)),mesh.faces,mesh.visual.uv,n,8)
lo,hi=mesh.bounds;acc=np.zeros((n,n,3),dtype=np.float32);total=np.zeros((n,n),dtype=np.float32)
for name,axis,sign,uaxis,usign in [('positive-x',0,1,1,1),('negative-x',0,-1,1,-1),('negative-y',1,-1,0,1),('positive-y',1,1,0,-1)]:
    im=np.asarray(Image.open(root/'inputs/tapir-frontal-concepts'/f'{name}.png').convert('RGBA'),dtype=np.float32)/255
    ys,xs=np.where(im[:,:,3]>.5);u=(pos[:,:,uaxis]-lo[uaxis])/(hi[uaxis]-lo[uaxis]);u=u if usign==1 else 1-u
    u=u*(xs.max()-xs.min())+xs.min();v=(hi[2]-pos[:,:,2])/(hi[2]-lo[2])*(ys.max()-ys.min())+ys.min()
    sample=np.stack([map_coordinates(im[:,:,c],[v,u],order=1,mode='nearest') for c in range(4)],axis=-1)
    weight=np.maximum(normals[:,:,axis]*sign,0)**4*sample[:,:,3]*(pos[:,:,3]>0)
    acc+=sample[:,:,:3]*weight[:,:,None];total+=weight
base=np.ones((n,n,4),dtype=np.float32);base[:,:,:3]=[.22,.15,.11]
mix=np.minimum(total*8,1);color=acc/np.maximum(total[:,:,None],1e-6)
base[:,:,:3]=base[:,:,:3]*(1-mix[:,:,None])+color*mix[:,:,None]
# Diagnostic: use positional front coverage so split-vertex normals cannot
# punch unprojected holes through the eyes. Do not alter geometry.
im=np.asarray(Image.open(root/'inputs/tapir-frontal-concepts/positive-x.png').convert('RGBA'),dtype=np.float32)/255
ys,xs=np.where(im[:,:,3]>.5)
u=(pos[:,:,1]-lo[1])/(hi[1]-lo[1])*(xs.max()-xs.min())+xs.min()
v=(hi[2]-pos[:,:,2])/(hi[2]-lo[2])*(ys.max()-ys.min())+ys.min()
sample=np.stack([map_coordinates(im[:,:,c],[v,u],order=1,mode='nearest') for c in range(4)],axis=-1)
front=np.clip((pos[:,:,0]-(lo[0]+hi[0])*.5)/(hi[0]-lo[0])*10,0,1)
weight=front*sample[:,:,3]*(pos[:,:,3]>0)
base[:,:,:3]=base[:,:,:3]*(1-weight[:,:,None])+sample[:,:,:3]*weight[:,:,None]
valid=pos[:,:,3]>0;_,indices=distance_transform_edt(~valid,return_indices=True);base[~valid]=base[indices[0][~valid],indices[1][~valid]];base[:,:,3]=1
image=Image.fromarray(np.uint8(np.clip(base[::-1],0,1)*255));image.save(dest/'basecolor.png');mesh.visual.material.baseColorTexture=image;mesh.export(dest/'projected.glb')
pp.write(out/'diagnostic-provenance.json',{'fresh_inference':False,'source_run':'tapir-d-frontal-fresh-007','geometry_changed_by_projection':False,'preparation':'Fresh TripoSR mesh smoothed, decimated to 18000 triangles, depth scaled .975, re-unwrapped before projection','method':'Four-view projection plus positional front override; head fur excluded','new_paid_calls':0})
print(out,flush=True)
