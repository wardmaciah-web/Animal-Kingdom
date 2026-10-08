from pathlib import Path
import sys,json,numpy as np,trimesh
from PIL import Image
from scipy.ndimage import distance_transform_edt
r=Path('D:/AnimalKingdom3D');sys.path.insert(0,str(r/'github-review/tools/pet_pipeline/workers'));from rasterize import rasterize_position_atlas
out=r/'outputs/tapir-d-coat-020';dest=out/'generated';dest.mkdir()
m=list(trimesh.load(r/'outputs/tapir-d-smooth-018/generated/raw.glb',process=False).geometry.values())[0]
pos=rasterize_position_atlas(m,np.arange(len(m.vertices)),m.faces,m.visual.uv,2048,8);lo,hi=m.bounds
xyz=(pos[:,:,:3]-lo)/(hi-lo);x,y,z=xyz.transpose(2,0,1)
from scipy.ndimage import map_coordinates
# Tile a small fur-only forehead swatch from this Tapir concept. Front features
# still come from the full concept projection; no mesh or other species is copied.
reference=np.asarray(Image.open(out/'concept.png').convert('RGB'),dtype=np.float32)/255
patch=reference[185:300,465:555]
theta=np.arctan2(y-.5,x-.5)/(2*np.pi)+.5
u=(theta*9)%2;u=np.minimum(u,2-u)*(patch.shape[1]-1)
v=(z*7)%2;v=np.minimum(v,2-v)*(patch.shape[0]-1)
coat=np.stack([map_coordinates(patch[:,:,i],[v,u],order=1,mode='nearest') for i in range(3)],axis=-1)
coat*=.85
stripes=np.zeros_like(x)
for i,height in enumerate([.16,.275,.39,.505]):
    center=height+.033*np.sin(x*7+i)+.009*np.sin(x*33+y*4+i*8)
    width=.008+.003*(1+np.sin(x*19+i*7))
    band=np.exp(-((z-center)/width)**4)
    broken=np.clip((np.sin(x*(27+i*3)+i*12)+.45)*2,0,1)
    stripes=np.maximum(stripes,band*broken)
stripes*=np.clip((.78-x)*7,0,1)*np.clip((np.abs(y-.5)-.08)*10,0,1)
spots=np.zeros_like(x);rng=np.random.default_rng(24)
for i in range(55):
    st=rng.uniform(0,1);sz=rng.uniform(.12,.93);rad=rng.uniform(.008,.018)
    dt=np.minimum(np.abs(theta-st),1-np.abs(theta-st))
    d=(dt/rad)**2+((z-sz)/(rad*1.3))**2
    spots=np.maximum(spots,np.exp(-d*d))
mask=np.maximum(stripes,spots)
furvalue=coat.mean(axis=-1)/max(float(coat.mean()),1e-5)
cream=np.array([.68,.54,.38])[None,None,:]*np.clip(furvalue[:,:,None],.8,1.15)
coat=coat*(1-mask[:,:,None])+cream*mask[:,:,None]
valid=pos[:,:,3]>0;_,idx=distance_transform_edt(~valid,return_indices=True);coat[~valid]=coat[idx[0][~valid],idx[1][~valid]]
im=Image.fromarray(np.uint8(np.clip(coat[::-1],0,1)*255));im.save(dest/'basecolor.png');m.visual.material.baseColorTexture=im;m.export(dest/'raw.glb')
(out/'diagnostic-provenance.json').write_text(json.dumps({'fresh_inference':False,'source_run':'tapir-d-frontal-fresh-007','geometry_source':'018 refined TripoSR mesh','material':'Same-concept forehead fur swatch plus irregular authored juvenile stripes/spots; front source projection follows','credits_used':0},indent=2))
