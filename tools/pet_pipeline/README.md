# Animal Kingdom pet production

This packages the approved free Ocelot's TripoSR and Blender process. Original
scripts remain in `preserved/`; source and weights are hash-pinned. Original pets
and the approved GLB are inputs for comparison and are never overwritten.

Run from the project directory:

```powershell
& E:/AnimalKingdom3D/tools/deps-stage/Scripts/python.exe tools/pet_pipeline/pet_pipeline.py generate --config tools/pet_pipeline/configs/ocelot.json --runtime-root E:/AnimalKingdom3D --output E:/AnimalKingdom3D/outputs/ocelot-new-run
```

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

Current implementation and reproducibility status is recorded in run manifests;
the presence of these scripts alone does not establish successful reproduction.
