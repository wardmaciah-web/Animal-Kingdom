"""Render an existing owned Tapir as a concept only; no mesh enters inference."""
from pathlib import Path
import bpy,json,math
from mathutils import Vector
root=Path('D:/AnimalKingdom3D');out=root/'inputs/tapir-angle-concepts';out.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.temporary_directory=str(root/'temp')
bpy.ops.import_scene.gltf(filepath=str(root/'inputs/tapir-existing-concept-source.glb'))
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
bpy.ops.object.select_all(action='DESELECT')
for o in meshes:o.select_set(True)
bpy.context.view_layer.objects.active=meshes[0];bpy.ops.object.join();pet=bpy.context.object
coords=[pet.matrix_world@Vector(v) for v in pet.bound_box];lo=Vector([min(v[i] for v in coords) for i in range(3)]);hi=Vector([max(v[i] for v in coords) for i in range(3)])
world=pet.matrix_world.copy();pet.parent=None;pet.matrix_world=world
scale=2.8/(hi.z-lo.z);pet.scale*=scale;pet.location-=Vector(((hi.x+lo.x)/2,(hi.y+lo.y)/2,lo.z))*scale
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.cycles.use_denoising=True
scene.render.resolution_x=1024;scene.render.resolution_y=1024;scene.render.resolution_percentage=100;scene.render.film_transparent=True
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA'
scene.world=bpy.data.worlds.new('Neutral');scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
scene.view_settings.view_transform='Standard'
for name,loc,power in [('key',(-3,-4,6),450),('fill',(4,-2,5),300),('rear',(0,4,5),400)]:
    d=bpy.data.lights.new(name,'AREA');d.energy=power;d.shape='DISK';d.size=5;o=bpy.data.objects.new(name,d);scene.collection.objects.link(o);o.location=loc;o.rotation_euler=(Vector((0,0,1.4))-o.location).to_track_quat('-Z','Y').to_euler()
d=bpy.data.cameras.new('Concept');c=bpy.data.objects.new('Concept',d);scene.collection.objects.link(c);scene.camera=c;d.type='ORTHO';d.ortho_scale=3.5
for name,loc in [(f'angle-{a}',(7*math.cos(math.radians(a)),-7*math.sin(math.radians(a)),1.6)) for a in [15,25]]:
    c.location=loc;c.rotation_euler=(Vector((0,0,1.4))-c.location).to_track_quat('-Z','Y').to_euler();scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
(out/'provenance.json').write_text(json.dumps({'source':'Existing owned Tapir review asset, downloaded without new generation','source_sha256':'9ee443a81d52bb5cfdf64de6d462168b0f0b3651f25168ee1c913058c7b7561f','purpose':'Concept render for fresh TripoSR species inference; source mesh not imported into output','credits_used':0},indent=2))
