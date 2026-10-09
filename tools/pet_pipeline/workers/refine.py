"""Non-destructive Blender review/refinement. Run in the separate bpy environment."""
import argparse, json, math, os, random
from pathlib import Path
from types import SimpleNamespace
from common import context
import bpy
from mathutils import Vector, Matrix
from pose_adjustments import apply_to_mesh

cfg,run,root,pipeline=context()
settings=cfg['refinement']; fur_settings=settings['fur']
height=cfg['target_dimensions']['height'];unit=height/settings['reference_height']
args=SimpleNamespace(input=str(run/'projected/projected.glb'),output=str(run/'review'),
                     source_z_up=True,yaw=settings['yaw_degrees'],refine=True)
out=Path(args.output); out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.temporary_directory=str(root/'temp')
bpy.ops.import_scene.gltf(filepath=str(Path(args.input).resolve()))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
bpy.ops.object.join()
pet=bpy.context.object; pet.name=cfg['pet_id']+'_Body'
world=pet.matrix_world.copy()
pet.parent=None
pet.matrix_world=world
# Trimesh GLB keeps input axes; TripoSR uses Z-up, unlike glTF's Y-up.
if args.source_z_up:
    pet.matrix_world=Matrix.Rotation(-math.pi/2,4,'X') @ pet.matrix_world
pet.matrix_world=Matrix.Rotation(math.radians(args.yaw),4,'Z') @ pet.matrix_world
bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
coords=[pet.matrix_world@Vector(v) for v in pet.bound_box]
lo=Vector(tuple(min(v[i] for v in coords) for i in range(3)))
hi=Vector(tuple(max(v[i] for v in coords) for i in range(3)))
scale=height/(hi.z-lo.z)
pet.scale*=scale
pet.location=Vector((-(hi.x+lo.x)*.5*scale,-(hi.y+lo.y)*.5*scale,-lo.z*scale))
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
for p in pet.data.polygons:p.use_smooth=True
for mat in pet.data.materials:
    if not mat or not mat.use_nodes:continue
    for node in mat.node_tree.nodes:
        if node.type=='BSDF_PRINCIPLED':
            # Preserve authored maps; make scalar-only materials matte/nonmetal.
            if not node.inputs['Metallic'].is_linked:node.inputs['Metallic'].default_value=0
            if not node.inputs['Roughness'].is_linked:node.inputs['Roughness'].default_value=cfg['texture']['roughness']
        if node.type=='TEX_IMAGE' and node.image:
            texture_path = Path(args.input).parent/'basecolor.png'
            if texture_path.exists():
                node.image = bpy.data.images.load(str(texture_path), check_existing=True)
            if not node.image.packed_file: node.image.pack()
# glTF splits positions at UV seams. Weld geometry while preserving loop UVs
# before decimation, otherwise each atlas island becomes a separate shard.
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=settings['weld_distance']*unit)
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode='OBJECT')
if args.refine:
    smooth=pet.modifiers.new('Refine neural surface','SMOOTH')
    smooth.factor=settings['smooth_factor']; smooth.iterations=settings['smooth_iterations']
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    # Optional per-species soft selections move original anatomy and preserve UVs.
    # Empty by default: approved Ocelot recipes retain their original geometry.
    pose_report=apply_to_mesh(pet.data,settings.get('pose_adjustments',[]),unit)
    # A shared flat contact plane for paws; preserve the upper paw silhouettes.
    for vertex in pet.data.vertices:
        z=vertex.co.z
        upper=settings['grounding']['upper']*unit;cut=settings['grounding']['cut']*unit
        if z<upper: vertex.co.z=max(0.,(z-cut)/(upper-cut)*upper)
# Keep original high-resolution geometry and a separate game-mesh export.
source_tris=sum(len(p.vertices)-2 for p in pet.data.polygons)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'high-resolution.blend'))
bake_source=None
if settings.get('rebake_after_decimation'):
    bake_source=pet.copy();bake_source.data=pet.data.copy()
    bpy.context.collection.objects.link(bake_source)
    bake_source.name=cfg['pet_id']+'_BakeSource'
    for i,material in enumerate(pet.data.materials):
        pet.data.materials[i]=material.copy()
if source_tris>settings['body_triangle_budget']:
    dec=pet.modifiers.new('Game export budget','DECIMATE'); dec.ratio=settings['body_triangle_budget']/source_tris
    bpy.ops.object.modifier_apply(modifier=dec.name)
if bake_source:
    # Repack and bake the projected high-resolution color onto the game mesh.
    # This avoids tiny wrong-color UV triangles introduced by decimation.
    bpy.ops.object.select_all(action='DESELECT');pet.select_set(True)
    bpy.context.view_layer.objects.active=pet
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.01)
    bpy.ops.object.mode_set(mode='OBJECT')
    baked=bpy.data.images.new('RebakedColor',width=cfg['texture']['resolution'],height=cfg['texture']['resolution'])
    for material in pet.data.materials:
        node=material.node_tree.nodes.new('ShaderNodeTexImage');node.image=baked
        material.node_tree.nodes.active=node
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=1
    scene.render.bake.use_pass_direct=False;scene.render.bake.use_pass_indirect=False
    scene.render.bake.use_pass_color=True
    bake_source.select_set(True)
    bpy.ops.object.bake(type='DIFFUSE',use_selected_to_active=True,cage_extrusion=.03*unit,
                       max_ray_distance=.08*unit,margin=12)
    baked.filepath_raw=str(out/'rebaked-basecolor.png');baked.file_format='PNG';baked.save();baked.pack()
    if settings.get('rebake_median_filter'):
        from PIL import Image,ImageFilter
        image_path=out/'rebaked-basecolor.png'
        with Image.open(image_path) as image:
            image.filter(ImageFilter.MedianFilter(3)).save(image_path)
        baked.unpack(method='REMOVE');baked.filepath=str(image_path);baked.reload();baked.pack()
    for material in pet.data.materials:
        for node in material.node_tree.nodes:
            if node.type=='TEX_IMAGE':node.image=baked
    bpy.data.objects.remove(bake_source,do_unlink=True)
if settings.get('baked_fur_detail'):
    # Bake subtle directional fur relief into a portable tangent normal map.
    # The frontal face is protected by a geometry mask; no new body geometry.
    detail_mask=pet.data.attributes.new('FurDetailMask','FLOAT','POINT')
    for vertex in pet.data.vertices:
        x,y,z=vertex.co
        detail_mask.data[vertex.index].value=max(min(1.,max(0.,(1.45*unit-z)/(.2*unit))),
                                               min(1.,max(0.,(y+.5*unit)/(.3*unit))))
    normal_image=bpy.data.images.new('FurNormal',width=cfg['texture']['resolution'],height=cfg['texture']['resolution'])
    normal_image.colorspace_settings.name='Non-Color'
    temporary=[]
    for material in pet.data.materials:
        nodes=material.node_tree.nodes;links=material.node_tree.links
        coordinate=nodes.new('ShaderNodeTexCoord');scale_node=nodes.new('ShaderNodeVectorMath');scale_node.operation='MULTIPLY'
        scale_node.inputs[1].default_value=(95,95,14);links.new(coordinate.outputs['Generated'],scale_node.inputs[0])
        noise=nodes.new('ShaderNodeTexNoise');noise.inputs['Scale'].default_value=1.;noise.inputs['Detail'].default_value=2.
        links.new(scale_node.outputs['Vector'],noise.inputs['Vector'])
        mask_node=nodes.new('ShaderNodeAttribute');mask_node.attribute_name='FurDetailMask'
        strength=nodes.new('ShaderNodeMath');strength.operation='MULTIPLY';strength.inputs[1].default_value=.3
        links.new(mask_node.outputs['Fac'],strength.inputs[0])
        bump=nodes.new('ShaderNodeBump');bump.inputs['Distance'].default_value=.018*unit
        links.new(strength.outputs[0],bump.inputs['Strength']);links.new(noise.outputs['Fac'],bump.inputs['Height'])
        shader=next(n for n in nodes if n.type=='BSDF_PRINCIPLED');links.new(bump.outputs['Normal'],shader.inputs['Normal'])
        target=nodes.new('ShaderNodeTexImage');target.image=normal_image;nodes.active=target
        temporary.append((material,[coordinate,scale_node,noise,mask_node,strength,bump],shader,target))
    bpy.context.scene.render.engine='CYCLES';bpy.context.scene.cycles.samples=1
    bpy.ops.object.bake(type='NORMAL',use_selected_to_active=False,normal_space='TANGENT',margin=12)
    normal_image.filepath_raw=str(out/'fur-normal.png');normal_image.file_format='PNG';normal_image.save();normal_image.pack()
    for material,nodes_to_remove,shader,target in temporary:
        nodes=material.node_tree.nodes;links=material.node_tree.links
        for node in nodes_to_remove:nodes.remove(node)
        normal_map=nodes.new('ShaderNodeNormalMap');links.new(target.outputs['Color'],normal_map.inputs['Color'])
        links.new(normal_map.outputs['Normal'],shader.inputs['Normal'])
if args.refine and fur_settings['enabled']:
    # Sculpt short, curved, broad fur locks on the actual reconstructed surface.
    # Separate material primitive keeps each exported mesh below 20k triangles.
    pet.data.calc_loop_triangles()
    triangles=list(pet.data.loop_triangles)
    areas=[t.area for t in triangles]
    rng=random.Random(cfg['generation']['seed'])
    positions=[];faces=[];uvs=[];surface_normals=[]
    uvdata=pet.data.uv_layers.active.data
    for tri in rng.choices(triangles,weights=areas,k=fur_settings['attempts']):
        a,b=rng.random(),rng.random()
        if a+b>1:a,b=1-a,1-b
        weights=(a,b,1-a-b)
        p=sum((pet.data.vertices[i].co*w for i,w in zip(tri.vertices,weights)),Vector())
        normal=sum((pet.data.vertices[i].normal*w for i,w in zip(tri.vertices,weights)),Vector()).normalized()
        if p.z<fur_settings['minimum_height']*unit:continue
        # Species-specific masks live in the recipe, not the implementation.
        excluded=False
        for mask in fur_settings['exclusions']:
            if (normal.y<mask['normal_y_max'] and p.z>mask.get('z_min',-1e6)*unit
                and p.z<mask.get('z_max',1e6)*unit and abs(p.x)<mask.get('abs_x_max',1e6)*unit
                and abs(p.x)>mask.get('abs_x_min',-1e6)*unit):excluded=True
        if excluded:continue
        if len(positions)//6>=fur_settings['count']:break
        direction=Vector((p.x/unit*fur_settings['outward_flow'],0,-1))
        direction=(direction-normal*direction.dot(normal)).normalized()
        if direction.length<.1:continue
        side=normal.cross(direction).normalized()
        length=rng.uniform(*fur_settings['length'])*unit; width=length*rng.uniform(*fur_settings['width_ratio'])
        root=p-normal*fur_settings['root_inset']*unit
        verts=[root-side*width*.4,root+side*width*.4,
               root+direction*length*.45-side*width*.55+normal*fur_settings['shoulder_height']*unit,
               root+direction*length*.45+side*width*.55+normal*fur_settings['shoulder_height']*unit,
               root+direction*length*.40+normal*fur_settings['ridge_height']*unit,
               root+direction*length+normal*fur_settings['tip_height']*unit]
        start=len(positions);positions.extend(verts)
        local_faces=[(0,1,4),(0,4,2),(1,3,4),(2,4,5),(4,3,5),(0,2,5),(0,5,1),(1,5,3)]
        if fur_settings.get('style')=='open_shingles':
            # Keep only the outer surface. Closed, buried undersides caused
            # dark triangular wedges in rejected Tapir/Red Panda reviews.
            local_faces=local_faces[:5]
            local_faces=[face if (verts[face[1]]-verts[face[0]]).cross(verts[face[2]]-verts[face[0]]).dot(normal)>0
                         else tuple(reversed(face)) for face in local_faces]
        faces.extend(tuple(start+j for j in face) for face in local_faces)
        surface_normals.extend([tuple(normal)]*6)
        uv=sum((uvdata[i].uv*w for i,w in zip(tri.loops,weights)),Vector((0,0)))
        uvs.extend([uv.copy()]*6)
    data=bpy.data.meshes.new('SculptedFurLocks');data.from_pydata(positions,[],faces);data.update()
    fur=bpy.data.objects.new(cfg['pet_id']+'_SculptedFur',data);bpy.context.collection.objects.link(fur)
    fur.visible_shadow=fur_settings.get('cast_shadow',True)
    fur_material=pet.data.materials[0]
    if settings.get('baked_fur_detail'):
        fur_material=fur_material.copy()
        shader=next(n for n in fur_material.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        for link in list(shader.inputs['Normal'].links):fur_material.node_tree.links.remove(link)
    data.materials.append(fur_material)
    uv_layer=data.uv_layers.new(name='FurUV')
    for loop in data.loops:uv_layer.data[loop.index].uv=uvs[loop.vertex_index]
    for face in data.polygons:face.use_smooth=True
    if fur_settings.get('style')=='open_shingles':
        data.normals_split_custom_set_from_vertices(surface_normals)
    fur.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'pet.blend'))
bpy.ops.export_scene.gltf(filepath=str(out/'pet.glb'),export_format='GLB',use_selection=True,export_materials='EXPORT')
export_tris=sum(len(p.vertices)-2 for o in bpy.context.selected_objects if o.type=='MESH' for p in o.data.polygons)

scene=bpy.context.scene
scene.render.engine='CYCLES'; scene.cycles.samples=cfg['preview']['samples']
scene.cycles.use_denoising=True
scene.render.resolution_x=cfg['preview']['resolution'];scene.render.resolution_y=cfg['preview']['resolution'];scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Neutral studio')
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.18,.18,.18,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
scene.view_settings.view_transform='Standard'
scene.view_settings.look='Medium High Contrast' if 'Medium High Contrast' in [i.name for i in scene.view_settings.bl_rna.properties['look'].enum_items] else 'None'
def area(name,loc,power,size):
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size
    obj=bpy.data.objects.new(name,data);scene.collection.objects.link(obj);obj.location=Vector(loc)*unit
    data.energy*=unit*unit; data.size*=unit
    obj.rotation_euler=(Vector((0,0,height/2))-obj.location).to_track_quat('-Z','Y').to_euler()
area('Soft key',(-3,-4,6),450,5)
area('Fill',(4,-2,4),250,4)
area('Rim',(0,4,5),350,3)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.005))
ground=bpy.context.object;ground.name='ReviewGround'
mat=bpy.data.materials.new('Neutral matte ground');mat.diffuse_color=(.19,.21,.23,1);mat.use_nodes=True
mat.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=1
ground.data.materials.append(mat)
cam_data=bpy.data.cameras.new('ReviewCamera');cam=bpy.data.objects.new('ReviewCamera',cam_data)
scene.collection.objects.link(cam);scene.camera=cam;cam_data.type='ORTHO';cam_data.ortho_scale=3.6*unit
views={'front':(0,-7,2.0),'three-quarter':(5,-7,2.5),'side':(7,0,2.0),'back':(0,7,2.0)}
for name,loc in views.items():
    cam.location=Vector(loc)*unit;cam.rotation_euler=(Vector((0,0,height/2))-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(out/(name+'.png'))
    bpy.ops.render.render(write_still=True)
cam.location=Vector(views['three-quarter'])*unit;cam.rotation_euler=(Vector((0,0,height/2))-cam.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.wm.save_as_mainfile(filepath=str(out/'preview-scene.blend'))
# Reopen the actual saved GLB in a clean scene and verify embedded texture/UVs.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(out/'pet.glb'))
opened=[o for o in bpy.context.scene.objects if o.type=='MESH']
report={'blender':bpy.app.version_string,'source_triangles':source_tris,'export_triangles':export_tris,
 'pose_adjustments':pose_report if args.refine else [],
 'reopened_glb':bool(opened),'uv_layers':[len(o.data.uv_layers) for o in opened],
 'images':[{'name':i.name,'size':list(i.size),'has_data':i.has_data} for i in bpy.data.images if i.type=='IMAGE'],
 'normalization_height':height,'original_files_modified':False,'visual_approval':'pending'}
(out/'blender-validation.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report),flush=True)
