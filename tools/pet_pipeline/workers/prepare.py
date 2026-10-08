"""Preserve supplied concept pixels; validate isolation rather than guessing a subject."""
import shutil
import numpy as np
from PIL import Image
from common import context,write,sha

cfg,out,root,pipeline=context()
im=Image.open(cfg['concept_image']).convert('RGBA')
alpha=np.asarray(im)[:,:,3]
if alpha.min()==255:
    if cfg.get('concept_preparation',{}).get('background_removal')!='rembg':
        raise ValueError('Opaque concept: supply isolated RGBA or explicitly select free rembg preparation')
    import rembg
    im=rembg.remove(im,session=rembg.new_session('u2net'))
    im.save(out/'concept.png')
else: shutil.copyfile(cfg['concept_image'],out/'concept.png')
alpha=np.asarray(im)[:,:,3];ys,xs=np.where(alpha>127)
if len(xs)<64 or not len(xs):raise ValueError('Concept has no usable foreground')
write(out/'concept-validation.json',{'input_sha256':sha(cfg['concept_image']),
    'prepared_sha256':sha(out/'concept.png'),'size':list(im.size),
    'foreground_box':[int(xs.min()),int(ys.min()),int(xs.max()),int(ys.max())],
    'foreground_ratio':cfg['generation']['foreground_ratio'],
    'rgb_background':0.5,'style_conditioning':'concept and downstream visual review; TripoSR has no style-reference input'})
