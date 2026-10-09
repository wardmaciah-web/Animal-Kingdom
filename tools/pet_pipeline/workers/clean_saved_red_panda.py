"""Texture-only Blender repair of the accepted 528f6b5 Red Panda.

Run with blender-env Python. No reconstruction, remesh, pose or UV changes.
The original scene is read-only; output must be a new directory.
"""
import argparse
import hashlib
import json
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector


def digest_mesh(obj):
    mesh = obj.data
    vertices = np.empty(len(mesh.vertices) * 3, dtype=np.float32)
    mesh.vertices.foreach_get('co', vertices)
    loops = np.empty(len(mesh.loops), dtype=np.int32)
    mesh.loops.foreach_get('vertex_index', loops)
    uv = np.empty(len(mesh.uv_layers.active.data) * 2, dtype=np.float32)
    mesh.uv_layers.active.data.foreach_get('uv', uv)
    return {'vertices': len(mesh.vertices), 'polygons': len(mesh.polygons),
            'geometry_sha256': hashlib.sha256(vertices.tobytes() + loops.tobytes()).hexdigest(),
            'uv_sha256': hashlib.sha256(uv.tobytes()).hexdigest(),
            'matrix': [list(row) for row in obj.matrix_world]}


parser = argparse.ArgumentParser()
parser.add_argument('--source', required=True)
parser.add_argument('--output', required=True)
args = parser.parse_args()
source, out = Path(args.source).resolve(), Path(args.output).resolve()
if source == out or out.exists():
    raise ValueError('Texture repair requires a fresh output directory')
out.mkdir(parents=True)
bpy.ops.wm.open_mainfile(filepath=str(source / 'preview-scene.blend'))
pets = [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.name.startswith('JungleRedPanda')]
assert len(pets) == 2, 'Expected accepted body and decorative fur'
before = {o.name: digest_mesh(o) for o in pets}
body = next(o for o in pets if o.name.endswith('_Body'))
fur = next(o for o in pets if o != body)
material = body.data.materials[0]
nodes, links = material.node_tree.nodes, material.node_tree.links
shader = next(n for n in nodes if n.type == 'BSDF_PRINCIPLED')
original = shader.inputs['Base Color'].links[0].from_socket
output = next(n for n in nodes if n.type == 'OUTPUT_MATERIAL')

# Surface-space coat pigment avoids neural projection patches and UV-island
# filtering artifacts. The front face/eyes/muzzle retain the original pigment.
geometry = nodes.new('ShaderNodeNewGeometry')
separate = nodes.new('ShaderNodeSeparateXYZ')
links.new(geometry.outputs['Position'], separate.inputs[0])
mask = nodes.new('ShaderNodeMapRange'); mask.interpolation_type = 'SMOOTHSTEP'
mask.inputs['From Min'].default_value = -.64
mask.inputs['From Max'].default_value = -.08
links.new(separate.outputs['Y'], mask.inputs['Value'])
scale = nodes.new('ShaderNodeVectorMath'); scale.operation = 'MULTIPLY'
scale.inputs[1].default_value = (100, 100, 12)
links.new(geometry.outputs['Position'], scale.inputs[0])
noise = nodes.new('ShaderNodeTexNoise'); noise.inputs['Scale'].default_value = 1
noise.inputs['Detail'].default_value = 2
links.new(scale.outputs['Vector'], noise.inputs['Vector'])
pigment = nodes.new('ShaderNodeValToRGB')
pigment.color_ramp.elements[0].position = .12
pigment.color_ramp.elements[0].color = (.235, .059, .026, 1)
pigment.color_ramp.elements[1].position = .88
pigment.color_ramp.elements[1].color = (.34, .102, .044, 1)
links.new(noise.outputs['Fac'], pigment.inputs['Fac'])
feet = nodes.new('ShaderNodeMapRange'); feet.interpolation_type = 'SMOOTHSTEP'
feet.inputs['From Min'].default_value = .1; feet.inputs['From Max'].default_value = .65
links.new(separate.outputs['Z'], feet.inputs['Value'])
coat = nodes.new('ShaderNodeMixRGB')
coat.inputs[1].default_value = (.035, .019, .014, 1)
links.new(feet.outputs[0], coat.inputs[0]); links.new(pigment.outputs['Color'], coat.inputs[2])
mix = nodes.new('ShaderNodeMixRGB')
links.new(mask.outputs[0], mix.inputs[0]); links.new(original, mix.inputs[1])
links.new(coat.outputs[0], mix.inputs[2])
emission = nodes.new('ShaderNodeEmission'); links.new(mix.outputs[0], emission.inputs['Color'])
links.new(emission.outputs[0], output.inputs['Surface'])
image = bpy.data.images.new('RedPanda_CleanCoat', width=2048, height=2048, alpha=False)
target = nodes.new('ShaderNodeTexImage'); target.image = image; nodes.active = target
bpy.ops.object.select_all(action='DESELECT'); body.select_set(True)
bpy.context.view_layer.objects.active = body
scene = bpy.context.scene; scene.render.engine = 'CYCLES'; scene.cycles.samples = 1
bpy.ops.object.bake(type='EMIT', use_selected_to_active=False, margin=16)
image.filepath_raw = str(out / 'clean-basecolor.png'); image.file_format = 'PNG'
image.save(); image.pack()
links.new(shader.outputs[0], output.inputs['Surface'])
links.new(target.outputs['Color'], shader.inputs['Base Color'])
for node in [geometry, separate, mask, scale, noise, pigment, feet, coat, mix, emission]:
    nodes.remove(node)
# Tufts retain their original sampled body UVs and get the same cleaned atlas.
fur_shader = next(n for n in fur.data.materials[0].node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
fur_shader.inputs['Base Color'].links[0].from_node.image = image
fur.visible_shadow = False
after = {o.name: digest_mesh(o) for o in pets}
assert before == after, 'Texture-only operation changed geometry, UVs or transforms'
bpy.ops.object.select_all(action='DESELECT')
for obj in pets: obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(out / 'pet.glb'), export_format='GLB', use_selection=True, export_materials='EXPORT')
bpy.ops.wm.save_as_mainfile(filepath=str(out / 'preview-scene.blend'))
scene.cycles.samples = 32
for name, loc in {'front': (0,-7,2), 'three-quarter': (5,-7,2.5), 'side': (7,0,2), 'back': (0,7,2)}.items():
    scene.camera.location = loc
    scene.camera.rotation_euler = (Vector((0,0,1.4)) - scene.camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath = str(out / (name + '.png'))
    bpy.ops.render.render(write_still=True)
report = {'source': str(source), 'geometry_and_uv_unchanged': before == after,
          'before': before, 'after': after, 'blender': bpy.app.version_string,
          'glb_sha256': hashlib.sha256((out / 'pet.glb').read_bytes()).hexdigest(),
          'visual_approval': 'pending', 'studio_qa': 'not tested',
          'decorative_fur_cast_shadow': False}
(out / 'texture-repair.json').write_text(json.dumps(report, indent=2))
print(json.dumps(report), flush=True)
