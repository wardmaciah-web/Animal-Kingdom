"""Validate exported data and prepare an import receipt, never invent asset IDs."""
import json
import numpy as np
import trimesh
from scipy.spatial import cKDTree
from PIL import Image
from skimage.metrics import structural_similarity
from common import context,write,sha
cfg,out,root,pipeline=context()
path=out/'review/pet.glb';scene=trimesh.load(path,process=False)
rules=cfg['validation'];height=cfg['target_dimensions']['height'];unit=height/cfg['refinement']['reference_height']
errors=[];meshes=[]
for name,mesh in scene.geometry.items():
    material=mesh.visual.material
    row={'name':name,'vertices':len(mesh.vertices),'triangles':len(mesh.faces),
         'finite_positions':bool(np.isfinite(mesh.vertices).all()),
         'finite_normals':bool(np.isfinite(mesh.vertex_normals).all()),
         'indices_valid':bool(mesh.faces.min()>=0 and mesh.faces.max()<len(mesh.vertices)),
         'uv_finite':bool(mesh.visual.kind=='texture' and np.isfinite(mesh.visual.uv).all()),
         'texture_size':list(material.baseColorTexture.size) if material.baseColorTexture else None,
         'normal_texture_size':list(material.normalTexture.size) if getattr(material,'normalTexture',None) else None,
         'metallic':float(material.metallicFactor),'roughness':float(material.roughnessFactor)}
    if not all(row[k] for k in ('finite_positions','finite_normals','indices_valid','uv_finite')):errors.append(f'Invalid mesh data: {name}')
    if row['triangles']>20000:errors.append(f'Mesh exceeds 20k: {name}')
    if row['texture_size']!=[cfg['texture']['resolution']]*2:errors.append(f'Missing/wrong texture: {name}')
    if row['metallic']!=0 or row['roughness']<.7:errors.append(f'Body must be matte and nonmetallic: {name}')
    meshes.append(row)
world=scene.dump(concatenate=True)
bounds=world.bounds;size=np.ptp(bounds,axis=0)
if abs(size[1]-height)>rules['height_tolerance']*height:errors.append('Incorrect exported height')
for axis,key in ((0,'width_max'),(2,'depth_max')):
    if cfg['target_dimensions'].get(key) and size[axis]>cfg['target_dimensions'][key]:errors.append(f'Exceeds {key}')
if sum(x['triangles'] for x in meshes)>rules['max_triangles']:errors.append('Total triangle budget exceeded')
body=max(scene.geometry.values(),key=lambda m:len(m.faces));paws=[]
if cfg['refinement'].get('baked_fur_detail'):
    normal=getattr(body.visual.material,'normalTexture',None)
    if normal is None or list(normal.size)!=[cfg['texture']['resolution']]*2:
        errors.append('Missing/wrong embedded body fur normal map')
for region in rules['paw_regions']:
    v=body.vertices
    selected=v[(v[:,0]>=region['x'][0]*unit)&(v[:,0]<=region['x'][1]*unit)&
               (v[:,2]>=region['z'][0]*unit)&(v[:,2]<=region['z'][1]*unit)]
    contact=float(selected[:,1].min()-bounds[0,1]) if len(selected) else None
    passed=contact is not None and abs(contact)<=rules['ground_tolerance']*unit
    paws.append({'name':region['name'],'minimum_above_floor':contact,'passed':passed,'region':region})
    if not passed:errors.append(f'Paw contact failed: {region["name"]}')
if len(paws)!=2:errors.append('Both front paw regions must be annotated and checked')
reopen=json.loads((out/'review/blender-validation.json').read_text())
if not reopen['reopened_glb'] or not all(i['has_data'] for i in reopen['images']):errors.append('Blender reopen failed')
comparison=None
if cfg.get('approved_model'):
    golden=trimesh.load(cfg['approved_model'],process=False).dump(concatenate=True)
    # Bidirectional vertex distance is independent of GLB names and UV packing.
    distances=np.concatenate((cKDTree(world.vertices).query(golden.vertices)[0],cKDTree(golden.vertices).query(world.vertices)[0]))
    comparison={'approved_sha256':sha(cfg['approved_model']),'mean_vertex_distance':float(distances.mean()),
                'p99_vertex_distance':float(np.quantile(distances,.99)),'max_vertex_distance':float(distances.max()),
                'geometry_pass':bool(np.quantile(distances,.99)<rules['reproduction_distance'])}
    if not comparison['geometry_pass']:errors.append('Clean run differs materially from approved geometry')
    if cfg.get('approved_front_render'):
        reference=Image.open(cfg['approved_front_render']).convert('RGB')
        current=Image.open(out/'review/front.png').convert('RGB').resize(reference.size)
        score=structural_similarity(np.asarray(reference),np.asarray(current),channel_axis=2,data_range=255)
        comparison['front_ssim']=float(score)
        comparison['appearance_metric_pass']=bool(score>=rules['reproduction_ssim'])
        if not comparison['appearance_metric_pass']:errors.append('Clean-run render needs visual investigation')
report={'passed':not errors,'errors':errors,'glb_sha256':sha(path),'meshes':meshes,'bounds':bounds.tolist(),
        'dimensions':size.tolist(),'front_paws':paws,'approved_comparison':comparison,
        'semantic_art_checks':'pending actual four-view review; geometry tests do not certify anatomy or style',
        'roblox_import':'prepared_not_imported'}
write(out/'validation.json',report)
write(out/'roblox-import.json',{'pet_id':cfg['pet_id'],'biome':cfg['biome'],'species':cfg['species'],
    'glb_path':str(path),'glb_sha256':sha(path),'review_folder':f'Workspace.AK_PetFactoryReview.{cfg["biome"]}',
    'asset_folder':f'ReplicatedStorage.PetAssets.{cfg["pet_id"]}',
    'native_import':{'anchored':True,'set_pivot_to_scene_origin':True,'upload_to_roblox':True,'import_as_package':False},
    'model_asset_id':None,'mesh_asset_ids':[],'texture_asset_ids':[],
    'requirements':['visual QA acceptance','durable native importer receipt','fresh reinsert and texture load',
                    'Inventory/Held/Followers/Sanctuary/Garden/Index/variants/70kg QA before biome release'],
    'game_publication_authorized':False})
print(json.dumps(report),flush=True)
if errors:raise SystemExit(1)
