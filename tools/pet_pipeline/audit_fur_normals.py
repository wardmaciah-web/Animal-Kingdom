"""Inspect a saved GLB without loading any AI model or modifying the asset."""
import argparse,json
import numpy as np
import trimesh
from scipy.spatial import cKDTree
from pet_pipeline import sha

parser=argparse.ArgumentParser();parser.add_argument('--glb',required=True);parser.add_argument('--output',required=True)
args=parser.parse_args()
scene=trimesh.load(args.glb,process=False)
body=max(scene.geometry.values(),key=lambda m:len(m.faces))
fur=next(m for name,m in scene.geometry.items() if 'Fur' in name)
_,indices=cKDTree(body.vertices).query(fur.vertices)
alignment=np.sum(fur.vertex_normals*body.vertex_normals[indices],axis=1)
report={'glb':args.glb,'sha256':sha(args.glb),'fur_vertices':len(alignment),
 'inward_fraction':float(np.mean(alignment<0)),
 'poor_alignment_fraction':float(np.mean(alignment<.5)),
 'median_alignment':float(np.median(alignment)),
 'interpretation':'Closed thin fur-lock underside/top smoothing is a candidate cause of dark wedge shading. Compare opt-in supporting_surface normals in renders before promoting.',
 'scope':'Normal directions only; does not establish visual acceptance or repair anatomy.'}
from pathlib import Path
Path(args.output).write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
