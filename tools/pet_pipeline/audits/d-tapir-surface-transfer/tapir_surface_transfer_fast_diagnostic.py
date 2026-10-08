"""Project owned species concept renders, never their mesh, onto fresh TripoSR UVs."""
import sys
from pathlib import Path
import numpy as np
import trimesh
from PIL import Image
from scipy.ndimage import map_coordinates,distance_transform_edt
pipeline=Path('D:/AnimalKingdom3D/github-review/tools/pet_pipeline');sys.path.insert(0,str(pipeline));import pet_pipeline as pp
sys.path.insert(0,str(pipeline/'workers'));from rasterize import rasterize_position_atlas
root=Path('D:/AnimalKingdom3D');out=root/'outputs/tapir-d-surface-transfer-015';out.mkdir(exist_ok=True)
cfg=pp.read(pipeline/'configs/tapir-front-diagnostic.json');cfg['refinement']['smooth_iterations']=10
effective=pp.configure(pipeline/'configs/tapir-front-diagnostic.json',root,out);effective['refinement']=cfg['refinement'];effective['refinement']['smooth_iterations']=0;effective['refinement']['fur']['exclusions']=[{'normal_y_max':1.1,'z_min':1.4,'z_max':2.8}];pp.write(out/'effective-config.json',effective)
src=root/'outputs/tapir-d-frontal-fresh-007/generated';dest=out/'projected';dest.mkdir()
import xatlas
geo=np.load(root/'outputs/tapir-d-reunwrap-012/optimized-geometry.npz');original=trimesh.Trimesh(vertices=geo['vertices'],faces=geo['faces'],process=False)
original.update_faces(original.unique_faces() & original.nondegenerate_faces());original.remove_unreferenced_vertices();print('clean triangles',len(original.faces),flush=True)
atlas=xatlas.Atlas();atlas.add_mesh(original.vertices,original.faces);pack=xatlas.PackOptions();pack.resolution=2048;pack.padding=8;atlas.generate(pack_options=pack);vm,faces,uv=atlas[0]
mesh=trimesh.Trimesh(vertices=original.vertices[vm],faces=faces,vertex_normals=original.vertex_normals[vm],process=False)
mesh.visual=trimesh.visual.TextureVisuals(uv=uv,material=trimesh.visual.material.PBRMaterial(roughnessFactor=.85,metallicFactor=0));n=2048
pos=rasterize_position_atlas(mesh,np.arange(len(mesh.vertices)),mesh.faces,mesh.visual.uv,n,8)
normalmesh=trimesh.Trimesh(vertices=mesh.vertex_normals,faces=mesh.faces,process=False)
normals=rasterize_position_atlas(normalmesh,np.arange(len(mesh.vertices)),mesh.faces,mesh.visual.uv,n,8)
# Transfer material only from the same-species owned reference.
# Align bounds; no reference vertices/faces enter the reconstructed output.
from scipy.spatial import cKDTree
source=list(trimesh.load(root/'inputs/tapir-existing-concept-source.glb',process=False).geometry.values())[0]
source.apply_transform(np.array([[1,0,0,0],[0,0,-1,0],[0,1,0,0],[0,0,0,1]],dtype=float))
lo,hi=mesh.bounds;slo,shi=source.bounds
points,fi=trimesh.sample.sample_surface(source,500000,seed=42)
bary=trimesh.triangles.points_to_barycentric(source.triangles[fi],points)
suv=(source.visual.uv[source.faces[fi]]*bary[:,:,None]).sum(axis=1)
sourceim=np.asarray(source.visual.material.baseColorTexture.convert('RGB'),dtype=np.float32)/255
colors=np.stack([map_coordinates(sourceim[:,:,c],[(1-suv[:,1])*(sourceim.shape[0]-1),suv[:,0]*(sourceim.shape[1]-1)],order=1,mode='nearest') for c in range(3)],axis=-1)
points=(points-slo)/(shi-slo)*(hi-lo)+lo
tree=cKDTree(points)
base=np.ones((n,n,4),dtype=np.float32)
validmask=pos[:,:,3]>0
flat=pos[:,:,:3][validmask];result=np.empty((len(flat),3),dtype=np.float32)
print('surface pixels',len(flat),flush=True)
for begin in range(0,len(flat),65536):
    dist,idx=tree.query(flat[begin:begin+65536],k=1,eps=.2,workers=4)
    result[begin:begin+65536]=colors[idx]
    if begin%262144==0:print('mapped',begin,'of',len(flat),flush=True)
base[:,:,:3][validmask]=result
valid=pos[:,:,3]>0;_,indices=distance_transform_edt(~valid,return_indices=True);base[~valid]=base[indices[0][~valid],indices[1][~valid]];base[:,:,3]=1
image=Image.fromarray(np.uint8(np.clip(base[::-1],0,1)*255));image.save(dest/'basecolor.png');mesh.visual.material.baseColorTexture=image;mesh.export(dest/'projected.glb')
pp.write(out/'diagnostic-provenance.json',{'fresh_inference':False,'source_run':'tapir-d-frontal-fresh-007','geometry_changed_by_projection':False,'preparation':'Fresh TripoSR mesh smoothed, decimated to 18000 triangles, depth scaled .975, re-unwrapped before projection','method':'Same-species owned source surface color transferred to freshly inferred optimized mesh; bounds alignment; no source geometry reused','new_paid_calls':0})
print(out,flush=True)
