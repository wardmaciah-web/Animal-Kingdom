"""Preserve supplied concept pixels; validate isolation rather than guessing a subject."""
import shutil
import numpy as np
from PIL import Image,ImageDraw
from common import context,write,sha

cfg,out,root,pipeline=context()
im=Image.open(cfg['concept_image']).convert('RGBA')
original=np.asarray(im).copy()
alpha=np.asarray(im)[:,:,3]
if alpha.min()==255:
    if cfg.get('concept_preparation',{}).get('background_removal')!='rembg':
        raise ValueError('Opaque concept: supply isolated RGBA or explicitly select free rembg preparation')
    import rembg
    im=rembg.remove(im,session=rembg.new_session('u2net'))
    # Explicitly reviewed regions restore real colored subject pixels that
    # rembg dropped (e.g. a low-contrast tail). No RGB pixels are synthesized.
    for region in cfg.get('concept_preparation',{}).get('preserve_regions',[]):
        if not region.get('reason'):raise ValueError('Mask correction needs a review reason')
        mask=Image.new('L',im.size,0);ImageDraw.Draw(mask).polygon([tuple(p) for p in region['polygon']],fill=255)
        rgb=original[:,:,:3].astype(np.float32)
        chroma=rgb.max(axis=2)-rgb.min(axis=2)
        threshold=region.get('chroma_threshold',8)
        coverage=np.clip((chroma-threshold)/region.get('chroma_feather',16),0,1)
        if 'maximum_value' in region:
            coverage*=np.clip((region['maximum_value']-rgb.max(axis=2))/16,0,1)
        restored=np.uint8(coverage*np.asarray(mask))
        current=np.asarray(im).copy();current[:,:,3]=np.maximum(current[:,:,3],restored)
        current[:,:,:3]=original[:,:,:3];im=Image.fromarray(current)
if alpha.min()==255:im.save(out/'concept.png')
else:shutil.copyfile(cfg['concept_image'],out/'concept.png')
expected=cfg.get('concept_preparation',{}).get('reviewed_prepared_sha256')
if expected and sha(out/'concept.png')!=expected:
    raise ValueError('Prepared foreground differs from the reviewed input')
alpha=np.asarray(im)[:,:,3];ys,xs=np.where(alpha>127)
if len(xs)<64 or not len(xs):raise ValueError('Concept has no usable foreground')
write(out/'concept-validation.json',{'input_sha256':sha(cfg['concept_image']),
    'prepared_sha256':sha(out/'concept.png'),'size':list(im.size),
    'foreground_repairs':cfg.get('concept_preparation',{}).get('preserve_regions',[]),
    'foreground_box':[int(xs.min()),int(ys.min()),int(xs.max()),int(ys.max())],
    'foreground_ratio':cfg['generation']['foreground_ratio'],
    'rgb_background':0.5,'style_conditioning':'concept and downstream visual review; TripoSR has no style-reference input'})
