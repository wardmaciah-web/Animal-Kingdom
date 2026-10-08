from pathlib import Path
import bpy, numpy as np, math
from mathutils import Matrix
root=Path('D:/AnimalKingdom3D');out=root/'outputs/tapir-d-reunwrap-011';out.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(root/'outputs/tapir-d-frontal-fresh-007/generated/raw.glb'))
o=next(o for o in bpy.context.scene.objects if o.type=='MESH');bpy.context.view_layer.objects.active=o;o.select_set(True)
o.matrix_world=Matrix.Rotation(-math.pi/2,4,'X')@o.matrix_world
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.mesh.remove_doubles(threshold=.00001);bpy.ops.mesh.normals_make_consistent(inside=False);bpy.ops.object.mode_set(mode='OBJECT')
s=o.modifiers.new('Surface smoothing','SMOOTH');s.factor=.65;s.iterations=10;bpy.ops.object.modifier_apply(modifier=s.name)
tri=sum(len(p.vertices)-2 for p in o.data.polygons);d=o.modifiers.new('Game budget','DECIMATE');d.ratio=18000/tri;bpy.ops.object.modifier_apply(modifier=d.name)
o.data.calc_loop_triangles();v=np.array([tuple(v.co) for v in o.data.vertices]);v[:,0]*=.975
np.savez(out/'optimized-geometry.npz',vertices=v,faces=np.array([tuple(t.vertices) for t in o.data.loop_triangles]));print('optimized',len(v),len(o.data.loop_triangles))
