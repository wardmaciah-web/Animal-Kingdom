# Free Jungle Ocelot v7 review candidate

One original Ocelot reconstructed locally from `../plush-stylized-20261008/ocelot-v7.png`. The original black bear front, side and three-quarter views were inspected as mandatory art-style references; no bear or existing pet mesh was reused. Zero paid generation calls or purchases.

## Verified locally

- Shell execution and project write probe passed. RTX 3060: 12,288 MiB VRAM, 9,363 MiB free at preflight. Installed RAM: 17,042,083,840 bytes. Blender 4.5.3 LTS `bpy` imports successfully.
- Free MIT TripoSR source and pinned weights were already on E:. Installed missing PyTorch 2.5.1+cu124/torchvision 0.20.1+cu124 into the existing isolated environment. Full precision failed CUDA allocation under Windows memory pressure. Memory-mapped loading, half precision, and deferred unused background-removal initialization succeeded. Inference used the exact v7 PNG, seed 42, 256 extraction resolution and a 2048px atlas.
- Blender refinement welded UV seam duplicates before decimation, corrected coordinate conversion, smoothed the neural surface, grounded both front paws, added 1,100 short sculpted fur locks, and applied front-facing source concept detail while retaining inferred back texture.
- `ocelot-review.glb` reopened in a fresh Blender scene and separately in trimesh with embedded texture and finite geometry/UVs. Two mesh primitives: 18,000 + 8,800 triangles. Both foreground paw regions reach the floor within 0.001 model units. Detailed measurements and hashes are in the JSON reports.
- `ocelot-review.blend` contains the editable review scene. `front.png`, `three-quarter.png`, `side.png`, and `back.png` are Blender renders of the exported candidate geometry. High-resolution neural source, scene code and intermediate artifacts remain under `E:/AnimalKingdom3D/outputs/ocelot-free-resume-v1`.
- Every pre-existing project GLB still matches its initial SHA-256. No gameplay files or existing pets were changed.

## Pending Studio verification

Native Studio import was prepared for `JungleOcelot_V7_FreeReview`, creator Me, anchored, add to Workspace. No successful import or new Roblox asset receipt has been observed. Desktop coordination is pending; do not assume that opening the Import Preview inserted an asset.

After native import, move only this candidate into `Workspace.AK_JunglePetReview.PlushStylizedReview`, normalize to the bear's 2.8-stud height, ground on the comparison floor, verify textures and script-free/noncolliding settings, and capture front/three-quarter comparisons. Preserve the bear, Tapir and all previous review candidates. No Jungle unlock, active registry change or game publication.

The candidate has the intended head/eye proportions and seated pose, but inferred side/back texture is softer than the source concept. It is not user-approved and no art-parity claim is made. Stop for visual approval after the Studio comparison.

## Reproduce

Set `AK_3D_ROOT` to the existing tools/inputs/outputs root (default `E:/AnimalKingdom3D`). `requirements-local.txt` records non-torch inference dependencies; use the CUDA torch versions above in `tools/deps-stage`. Run `local_ocelot_resume.py --output E:/AnimalKingdom3D/outputs/ocelot-free-resume-v1 --resolution 256 --texture-resolution 2048`, followed by `project_concept.py`. In the separate Blender environment run `blender_review_resume.py --input E:/AnimalKingdom3D/outputs/ocelot-free-resume-v1/refined/ocelot-projected.glb --output <new-review-directory> --source-z-up --yaw -90 --refine`. Existing outputs should be retained before a rerun.

Source references: [TripoSR, MIT code and weights](https://github.com/VAST-AI-Research/TripoSR), [Hunyuan3D-2 hardware comparison](https://github.com/Tencent-Hunyuan/Hunyuan3D-2), [Roblox native importer](https://create.roblox.com/docs/studio/importer). TripoSR's license is included. No hosted generator or paid Tripo service was used.
