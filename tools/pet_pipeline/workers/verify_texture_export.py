"""Reopen real texture-repair GLB and render under the saved neutral rig."""
import argparse
import json
from pathlib import Path
import bpy
from mathutils import Vector

parser = argparse.ArgumentParser()
parser.add_argument('--review', required=True)
parser.add_argument('--ocelot', required=True)
args = parser.parse_args()
out = Path(args.review).resolve()
bpy.ops.wm.open_mainfile(filepath=str(out / 'preview-scene.blend'))
for obj in list(bpy.context.scene.objects):
    if obj.type == 'MESH' and obj.name.startswith('JungleRedPanda'):
        bpy.data.objects.remove(obj, do_unlink=True)
bpy.ops.import_scene.gltf(filepath=str(out / 'pet.glb'))
pets = [o for o in bpy.context.selected_objects if o.type == 'MESH']
for obj in pets:
    if 'Fur' in obj.name: obj.visible_shadow = False
scene = bpy.context.scene
scene.cycles.samples = 32
report = {'blender': bpy.app.version_string, 'reopened_glb': len(pets) == 2,
          'uv_layers': [len(o.data.uv_layers) for o in pets],
          'export_triangles': sum(len(p.vertices)-2 for o in pets for p in o.data.polygons),
          'images': [{'name': n.image.name, 'size': list(n.image.size), 'has_data': n.image.has_data}
                     for o in pets for m in o.data.materials for n in m.node_tree.nodes
                     if n.type == 'TEX_IMAGE' and n.image],
          'original_files_modified': False, 'visual_approval': 'pending Studio'}
(out / 'blender-validation.json').write_text(json.dumps(report, indent=2))
for name, loc in {'front': (0,-7,2), 'three-quarter': (5,-7,2.5), 'side': (7,0,2), 'back': (0,7,2)}.items():
    scene.camera.location = loc
    scene.camera.rotation_euler = (Vector((0,0,1.4))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath = str(out / ('export-' + name + '.png'))
    bpy.ops.render.render(write_still=True)
for obj in pets: obj.hide_render = True
bpy.ops.import_scene.gltf(filepath=str(Path(args.ocelot).resolve()))
reference = [o for o in bpy.context.selected_objects if o.type == 'MESH']
corners = [o.matrix_world @ Vector(c) for o in reference for c in o.bound_box]
minimum = min(p.z for p in corners); maximum = max(p.z for p in corners)
factor = 2.8 / (maximum - minimum)
# Only alter disposable imported comparison objects, never the approved file.
for obj in reference:
    matrix = obj.matrix_world.copy()
    obj.parent = None
    obj.matrix_world = matrix
    obj.scale *= factor
    obj.location *= factor
    obj.location.z -= minimum * factor
scene.camera.location = (0,-7,2)
scene.camera.rotation_euler = (Vector((0,0,1.4))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.render.filepath = str(out / 'ocelot-matched-front.png')
bpy.ops.render.render(write_still=True)
report['comparison'] = {'ocelot_height': 2.8, 'red_panda_height': 2.8,
                        'lighting': 'same saved neutral scene',
                        'black_bear': 'screenshots only; matched Studio comparison outstanding'}
(out / 'blender-validation.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report), flush=True)
