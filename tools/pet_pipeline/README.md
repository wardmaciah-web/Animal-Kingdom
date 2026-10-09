# Animal Kingdom pet production

This packages the approved free Ocelot's TripoSR and Blender process. Original
scripts remain in `preserved/`; source and weights are hash-pinned. Original pets
and the approved GLB are inputs for comparison and are never overwritten.

For the accepted Red Panda geometry, use the texture-only checkpoint described in
`CHECKPOINT.md`; do not rerun generation or `refine_saved_mesh.py`. Its Blender
worker `workers/clean_saved_red_panda.py --source <saved-review> --output <new-review>`
reads the saved `preview-scene.blend`, repairs side/back pigment in surface space,
bakes a portable atlas and asserts unchanged geometry, UVs and transforms. The
output directory must be new. `workers/verify_texture_export.py --review <new-review>
--ocelot <approved-ocelot.glb>` reopens the actual GLB, checks embedded textures,
renders four views and renders the Ocelot under the same neutral rig. These are
local checks; Studio art approval and ownership/persistence QA are still required.

Run from the project directory:

```powershell
& ./tools/pet_pipeline/run-pet-factory.ps1 -Recipe ocelot
```

The launcher defaults to `D:/AnimalKingdom3D`, configures the parent Python process
and all child stages to keep temporary files and caches there, and creates a new
timestamped output directory. Read `CHECKPOINT.md` before resuming the second pet;
reuse its saved mesh instead of repeating completed inference. Use a named recipe,
`-RuntimeRoot` to relocate, and `-Output` to select a new output directory.
Direct Python invocation accepts `--runtime-root` or `AK_3D_ROOT`, defaulting to D:.
Concept and reconstruction workers share an OS-held exclusive `generation.lock`
under the D: runtime. Inspect active processes and prior manifests/logs before
retrying; a stale `loading` manifest is not evidence of a running worker. The
lock covers these entry points, not manually launched legacy worker scripts.
Missing RAM/commit measurements block admission. The 12 GiB commit margin was
raised after Coati failed despite passing the old 6 GiB check; it is conservative,
not a guarantee of successful loading. Keep caches and outputs on D:.

The generation gate requires 4 GiB free RAM, 12 GiB free system commit, 7 GiB free
VRAM on the first GPU and 2 GiB free output storage. These are admission thresholds,
not guarantees of peak memory use. Models load from the verified offline caches.

Every run requires a new output directory. A recipe specifies species, biome,
concept, style references, target dimensions, neural generation, texture atlas,
refinement, fur masks, previews and validation tolerances. Paths in recipes are
relative to the recipe. Copy the recipe and annotate the new species' actual paw
regions and fur exclusion regions; do not reuse Ocelot anatomy assumptions blindly.

Stages run in separate processes: isolated concept preparation, fresh neural
geometry, neural texture baking, source-detail projection, Blender refinement and
optimization, embedded-texture GLB export, four-view rendering, clean GLB reopen
and technical validation. Each stage records logs, duration and exit status.
Failures remain on disk as evidence. A passing technical result is not art approval.

Both the original black bear and approved Ocelot are mandatory visual references.
Judge AI concepts primarily by original species design, face, fur and proportions.
Allow repairable pose defects, including a slightly raised paw. Correct sitting
pose and limb placement in Blender on the actual reconstruction before final QA;
see `LOCAL_CONCEPTS.md`. Reject collages, wrong species and severe distortions.
Normal animals require large expressive eyes, rounded heads, compact chubby bodies,
rich stylized fur, matte surfaces, short paws and a seated pose with both front paws
forward and grounded. Scaled or armored species retain the same cute proportions.
Every species must begin with fresh species-specific geometry, never a recolor.
TripoSR does not accept style-conditioning images: the references guide concept
creation and actual visual review, not hidden model conditioning.

Inspect front, side, back and three-quarter renders against both references. Record
all checks listed in `pet_pipeline.py` with the exported GLB hash, reviewer and
observations, then use `review --run RUN --evidence REVIEW.json --accept`. Reject
poor anatomy, blurry or stretched textures and incorrect stance, even if numeric
validation passes. Acceptance requires both actual visual review and technical QA.

`roblox-import.json` prepares the native Studio import and tracks the exact GLB.
It deliberately contains no invented asset IDs. Import into the biome review
folder, verify durable mesh and texture IDs by fresh insertion, then integrate
QA-passed models into PetAssets and existing definitions. Check Inventory, Held,
Followers, Sanctuary, Garden, Index, mutations, Shiny/Prismatic and the 70kg system.
Test every tree family before releasing a biome. No pipeline stage publishes the
game or changes Coming Soon gates.

Run `studio_readiness_audit.luau` through Studio's `execute_luau` to reuse the
game's existing PetAssetValidator and PetModelResolver and check every family's
definitions, reward membership, durable texture bindings and mapped physical
trees. The report explicitly leaves interaction QA unverified. It does not
change the place, profiles, rewards, or release flags.

Current implementation and reproducibility status is recorded in run manifests;
the presence of these scripts alone does not establish successful reproduction.
