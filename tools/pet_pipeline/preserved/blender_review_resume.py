"""Non-destructive Blender review/refinement. Run in the separate bpy environment."""
import argparse, json, math, os, random
from pathlib import Path
import bpy
from mathutils import Vector, Matrix

root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser()
parser.add_argument('--input', required=True)
parser.add_argument('--output', required=True)
parser.add_argument('--source-z-up', action='store_true')
parser.add_argument('--yaw', type=float, default=0)
parser.add_argument('--refine', action='store_true')
args=parser.parse_args()
out=Path(args.output); out.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.temporary_directory=str(root/'temp')
bpy.ops.import_scene.gltf(filepath=str(Path(args.input).resolve()))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
for o in meshes:
    o.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
bpy.ops.object.join()
pet=bpy.context.object; pet.name='JungleOcelot_LocalReview'
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
scale=2.8/(hi.z-lo.z)
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
            if not node.inputs['Roughness'].is_linked:node.inputs['Roughness'].default_value=.85
        if node.type=='TEX_IMAGE' and node.image:
            texture_path = Path(args.input).parent/'basecolor.png'
            if texture_path.exists():
                node.image = bpy.data.images.load(str(texture_path), check_existing=True)
            if not node.image.packed_file: node.image.pack()
# glTF splits positions at UV seams. Weld geometry while preserving loop UVs
# before decimation, otherwise each atlas island becomes a separate shard.
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=0.00001)
bpy.ops.mesh.normals_make_consistent(inside=False)
bpy.ops.object.mode_set(mode='OBJECT')
if args.refine:
    smooth=pet.modifiers.new('Refine neural surface','SMOOTH')
    smooth.factor=.65; smooth.iterations=5
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    # A shared flat contact plane for paws; preserve the upper paw silhouettes.
    for vertex in pet.data.vertices:
        z=vertex.co.z
        if z<.13: vertex.co.z=max(0.,(z-.045)/(.13-.045)*.13)
# Keep original high-resolution geometry and a separate game-mesh export.
source_tris=sum(len(p.vertices)-2 for p in pet.data.polygons)
bpy.ops.wm.save_as_mainfile(filepath=str(out/'ocelot-source.blend'))
if source_tris>18000:
    dec=pet.modifiers.new('Game export budget','DECIMATE'); dec.ratio=18000/source_tris
    bpy.ops.object.modifier_apply(modifier=dec.name)
if args.refine:
    # Sculpt short, curved, broad fur locks on the actual reconstructed surface.
    # Separate material primitive keeps each exported mesh below 20k triangles.
    pet.data.calc_loop_triangles()
    triangles=list(pet.data.loop_triangles)
    areas=[t.area for t in triangles]
    rng=random.Random(42)
    positions=[];faces=[];uvs=[]
    uvdata=pet.data.uv_layers.active.data
    for tri in rng.choices(triangles,weights=areas,k=4300):
        a,b=rng.random(),rng.random()
        if a+b>1:a,b=1-a,1-b
        weights=(a,b,1-a-b)
        p=sum((pet.data.vertices[i].co*w for i,w in zip(tri.vertices,weights)),Vector())
        normal=sum((pet.data.vertices[i].normal*w for i,w in zip(tri.vertices,weights)),Vector()).normalized()
        if p.z<.30:continue
        # Keep eyes, muzzle, and inner ears clear. Detail cheeks, crown, chest/back.
        if normal.y<-.25 and p.z>1.50 and abs(p.x)<.85 and p.z<2.48:continue
        if normal.y<-.4 and p.z>2.42 and abs(p.x)>.55:continue
        if len(positions)//6>=1100:break
        direction=Vector((p.x*.35,0,-1))
        direction=(direction-normal*direction.dot(normal)).normalized()
        if direction.length<.1:continue
        side=normal.cross(direction).normalized()
        length=rng.uniform(.055,.10); width=length*rng.uniform(.23,.33)
        root=p-normal*.007
        verts=[root-side*width*.4,root+side*width*.4,
               root+direction*length*.45-side*width*.55+normal*.009,
               root+direction*length*.45+side*width*.55+normal*.009,
               root+direction*length*.40+normal*.019,
               root+direction*length+normal*.003]
        start=len(positions);positions.extend(verts)
        faces.extend(tuple(start+j for j in face) for face in [(0,1,4),(0,4,2),(1,3,4),(2,4,5),(4,3,5),(0,2,5),(0,5,1),(1,5,3)])
        uv=sum((uvdata[i].uv*w for i,w in zip(tri.loops,weights)),Vector((0,0)))
        uvs.extend([uv.copy()]*6)
    data=bpy.data.meshes.new('SculptedFurLocks');data.from_pydata(positions,[],faces);data.update()
    fur=bpy.data.objects.new('Ocelot_SculptedFur',data);bpy.context.collection.objects.link(fur)
    data.materials.append(pet.data.materials[0])
    uv_layer=data.uv_layers.new(name='FurUV')
    for loop in data.loops:uv_layer.data[loop.index].uv=uvs[loop.vertex_index]
    for face in data.polygons:face.use_smooth=True
    fur.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(out/'ocelot-review.glb'),export_format='GLB',use_selection=True,export_materials='EXPORT')
export_tris=sum(len(p.vertices)-2 for o in bpy.context.selected_objects if o.type=='MESH' for p in o.data.polygons)

scene=bpy.context.scene
scene.render.engine='CYCLES'; scene.cycles.samples=16
scene.cycles.use_denoising=True
scene.render.resolution_x=700;scene.render.resolution_y=700;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('Neutral studio')
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.18,.18,.18,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.7
scene.view_settings.view_transform='Standard'
scene.view_settings.look='Medium High Contrast' if 'Medium High Contrast' in [i.name for i in scene.view_settings.bl_rna.properties['look'].enum_items] else 'None'
def area(name,loc,power,size):
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='DISK';data.size=size
    obj=bpy.data.objects.new(name,data);scene.collection.objects.link(obj);obj.location=loc
    obj.rotation_euler=(Vector((0,0,1.4))-obj.location).to_track_quat('-Z','Y').to_euler()
area('Soft key',(-3,-4,6),450,5)
area('Fill',(4,-2,4),250,4)
area('Rim',(0,4,5),350,3)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.005))
ground=bpy.context.object;ground.name='ReviewGround'
mat=bpy.data.materials.new('Neutral matte ground');mat.diffuse_color=(.19,.21,.23,1);mat.use_nodes=True
mat.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=1
ground.data.materials.append(mat)
cam_data=bpy.data.cameras.new('ReviewCamera');cam=bpy.data.objects.new('ReviewCamera',cam_data)
scene.collection.objects.link(cam);scene.camera=cam;cam_data.type='ORTHO';cam_data.ortho_scale=3.6
views={'front':(0,-7,2.0),'three-quarter':(5,-7,2.5),'side':(7,0,2.0),'back':(0,7,2.0)}
for name,loc in views.items():
    cam.location=loc;cam.rotation_euler=(Vector((0,0,1.4))-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(out/(name+'.png'))
    bpy.ops.render.render(write_still=True)
cam.location=views['three-quarter'];cam.rotation_euler=(Vector((0,0,1.4))-cam.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.wm.save_as_mainfile(filepath=str(out/'ocelot-review.blend'))
# Reopen the actual saved GLB in a clean scene and verify embedded texture/UVs.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(out/'ocelot-review.glb'))
opened=[o for o in bpy.context.scene.objects if o.type=='MESH']
report={'blender':bpy.app.version_string,'source_triangles':source_tris,'export_triangles':export_tris,
 'reopened_glb':bool(opened),'uv_layers':[len(o.data.uv_layers) for o in opened],
 'images':[{'name':i.name,'size':list(i.size),'has_data':i.has_data} for i in bpy.data.images if i.type=='IMAGE'],
 'normalization_height':2.8,'original_files_modified':False,'visual_approval':'pending'}
(out/'blender-validation.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report),flush=True)
