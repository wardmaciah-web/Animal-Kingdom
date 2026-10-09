# Local concept stage

Red Panda is the next original Jungle quadruped. Tapir is deferred: no more
fresh inference after three reconstructions and 22 saved trials. At most one
saved-mesh supporting-surface-normal diagnostic remains; it does not qualify
Tapir for import. The approved Ocelot recipe/assets stay unchanged.

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

Once the standard memory/VRAM gate passes, run `generate_concepts.py` using
the concept environment, `--config concept_red_panda.json` and a NEW
`--output D:/AnimalKingdom3D/outputs/red-panda-concepts-001` directory.
The script checks hardware before importing PyTorch or loading weights and
generates at most three candidates. Inspect all concepts against the actual
bear and approved Ocelot references before selecting a TripoSR input.
SDXL is text-conditioned here; references are not secretly fed into the model.

Reject wrong anatomy, small eyes, fused paws, cropped tail, plastic fur or
incompatible proportions before expensive 3D work. Fresh TripoSR inference
must still pass numeric and four-view art review, then isolated Studio import
and interaction QA. Numeric validation alone never grants approval.

The single saved-mesh diagnostic `tapir-d-surface-normals-023` corrected the
normal alignment but made the black fur wedges worse in actual renders. It is
rejected. The optional normal-setting experiment was removed from production
and preserved only under `audits/tapir-bounded-diagnostic`. The measured normal
problem was not sufficient to explain/fix the visual failure. Fur intersections
and thin closed-shell backfaces remain candidates; do not repeat Tapir trials.
