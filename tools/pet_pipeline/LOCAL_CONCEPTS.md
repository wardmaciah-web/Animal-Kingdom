# Local concept stage

Prioritize ONE excellent second Jungle pet before mass production. AI supplies
the original design: correct species, face, expressive eyes, fur and proportions.
Blender corrects repairable paw placement, hind-leg position and sitting anatomy.
The user revised the concept gate after 36d17ce: a slightly raised paw or an
obscured hind paw alone is not a reason to discard an otherwise excellent design.
Red Panda 006/1042 is selected for reconstruction under this revised gate; its
historical rejection remains in the audit. Collages stay rejected. Tapir remains
deferred after its severe reconstructed anatomy failures. Ocelot stays unchanged.

The public SDXL base model supplies a free local text-to-image concept stage.
No hosted inference, API keys, paid credits or external generation endpoints
are used. Its model card and CreativeML Open RAIL++-M license are stored with
the pinned weights on D:. Source:
https://huggingface.co/stabilityai/stable-diffusion-xl-base-1.0

Use a separate `tools/concept-env` virtual environment on D:, with a `.pth`
reference to `tools/deps-stage/Lib/site-packages` for existing PyTorch/CUDA.
Install these versions in the concept environment only: diffusers 0.35.1,
accelerate 1.10.1, transformers 4.45.2, tokenizers 0.20.3 and
huggingface-hub 0.34.4. Do not upgrade the proven TripoSR environment.

Dot-source `runtime-env.ps1` before every invocation. Run
`download_concept_weights.py` with the standalone D Python. It downloads only
the pinned FP16 components and checks the published LFS SHA256 digests.
Downloads do not allocate an AI model. Weights/temp/cache remain on D:.

Once the standard memory/VRAM gate passes, run `run_concepts.py` using
the concept environment, `--config concept_red_panda.json` and a NEW
`--output D:/AnimalKingdom3D/outputs/red-panda-concepts-001` directory.
The script checks hardware before importing PyTorch or loading weights and
generates at most three candidates. Inspect all concepts against the actual
bear and approved Ocelot references before selecting a TripoSR input.
Default SDXL runs are text-conditioned; references guide visual comparison.
`concept_red_panda_guided.json` explicitly opts into local image-to-image design
using the approved Ocelot render at strength 0.72. Its image hash and strength are
recorded. The black bear remains a mandatory review reference. Reject outputs
that retain cat/ocelot identity; this is design guidance, never reuse of its mesh.

The supervisor captures native stderr directly in `worker.log` and records
worker exit codes, including native Windows crashes. This avoids treating
progress output as a PowerShell terminating error after `runtime-env.ps1`.
Each run uses a new directory; completed candidates survive a later failure.

Reject multi-animal collages, severely distorted anatomy, incorrect species,
plastic fur or incompatible proportions before expensive 3D work. Review minor
pose issues for repairability and record a Blender repair plan. Never claim that
an unseen limb exists until inspecting the reconstruction. Fresh TripoSR inference
must still pass numeric and four-view art review, then isolated Studio import
and interaction QA. Numeric validation alone never grants approval.

Use optional `refinement.pose_adjustments` on the reconstructed mesh: named
soft-selection bounds, positive feather, pivot, rotation and translation in
normalized Blender Z-up coordinates. These move existing vertices while keeping
UVs; they do not fabricate limbs. Inspect before/after four-view renders for
joint continuity, ground contact, face preservation and texture stretching.
Keep final grounded-paw, art and Studio gates; only the concept gate is relaxed.

To inspect a saved-mesh repair without another neural run, dot-source
`runtime-env.ps1`, then invoke `refine_saved_mesh.py` with the deps-stage Python,
`--source` pointing at the original run, `--config` at the repair recipe, and
`--output` at a new runtime directory. It rejects another species or changed
concept, copies the projected mesh, and runs Blender plus technical validation.
Four-view inspection remains mandatory. A broad box can move torso skin along
with a fused paw; reject stretched surfaces even if their vertices reach floor.

The single saved-mesh diagnostic `tapir-d-surface-normals-023` corrected the
normal alignment but made the black fur wedges worse in actual renders. It is
rejected. The optional normal-setting experiment was removed from production
and preserved only under `audits/tapir-bounded-diagnostic`. The measured normal
problem was not sufficient to explain/fix the visual failure. Fur intersections
and thin closed-shell backfaces remain candidates; do not repeat Tapir trials.
