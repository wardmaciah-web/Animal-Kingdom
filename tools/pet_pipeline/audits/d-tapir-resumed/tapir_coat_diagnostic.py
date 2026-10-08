from pathlib import Path
import sys,json,numpy as np,trimesh
from PIL import Image
from scipy.ndimage import distance_transform_edt
r=Path('D:/AnimalKingdom3D');sys.path.insert(0,str(r/'github-review/tools/pet_pipeline/workers'));from rasterize import rasterize_position_atlas
out=r/'outputs/tapir-d-coat-019';dest=out/'generated';dest.mkdir()
m=list(trimesh.load(r/'outputs/tapir-d-smooth-018/generated/raw.glb',process=False).geometry.values())[0]
pos=rasterize_position_atlas(m,np.arange(len(m.vertices)),m.faces,m.visual.uv,2048,8);lo,hi=m.bounds
xyz=(pos[:,:,:3]-lo)/(hi-lo);x,y,z=xyz.transpose(2,0,1)
# Fine directional strokes and broad pigment variation; material only.
strand=(np.sin(y*1800+np.sin(z*24)*3)+np.sin(x*1500+z*180)+np.sin((x+y)*740+z*55))/3
soft=np.sin(x*17+np.sin(z*15))*np.sin(y*18+z*9)
shade=1+.075*strand+.07*soft
brown=np.array([.29,.205,.158]);cream=np.array([.70,.54,.36])
coat=brown[None,None,:]*shade[:,:,None]
# Broken longitudinal juvenile stripes over the rear/flanks.
stripes=np.zeros_like(x)
for height in [.20,.32,.44,.56]:
    center=height+.08*(x-.4)**2+.009*np.sin(x*28+y*3)
    band=np.exp(-((z-center)/.012)**4)
    broken=np.clip((np.sin(x*44+height*60+y*2)+.8)*2,0,1)
    stripes=np.maximum(stripes,band*broken)
stripes*=np.clip((.74-x)*8,0,1)*np.clip((np.abs(y-.5)-.12)*10,0,1)
# Small cream spots on rear head and around broken stripe ends.
spots=np.zeros_like(x)
rng=np.random.default_rng(42)
for i in range(80):
    sx,sy,sz=rng.uniform(0,1,3);radius=rng.uniform(.018,.033)
    d=((x-sx)/radius)**2+((y-sy)/radius)**2+((z-sz)/(radius*.65))**2
    spots=np.maximum(spots,np.exp(-d*d)*.95)
mask=np.maximum(stripes,spots)*(1+.06*strand);mask=np.clip(mask,0,1)
coat=coat*(1-mask[:,:,None])+cream[None,None,:]*shade[:,:,None]*mask[:,:,None]
valid=pos[:,:,3]>0;_,idx=distance_transform_edt(~valid,return_indices=True);coat[~valid]=coat[idx[0][~valid],idx[1][~valid]]
im=Image.fromarray(np.uint8(np.clip(coat[::-1],0,1)*255));im.save(dest/'basecolor.png');m.visual.material.baseColorTexture=im;m.export(dest/'raw.glb')
(out/'diagnostic-provenance.json').write_text(json.dumps({'fresh_inference':False,'source_run':'tapir-d-frontal-fresh-007','geometry_source':'018 refined TripoSR mesh','material':'Authored cocoa juvenile stripes and spots with directional fur strokes; front source projection follows','credits_used':0},indent=2))
