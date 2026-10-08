# Implementation checkpoint — 2026-10-08

## D: migration continuation

The complete runtime now lives at `D:/AnimalKingdom3D`. Before relocation edits,
all 70,127 files (18,177,439,800 bytes) matched E: by SHA256. One skipped relative
Hugging Face symlink was materialized and hash-verified. The Python junction and
51 copied environment/launcher/script files were repaired for D:. E: is retained.
See `audits/d-migration-verification.json`, `d-relocation-changes.json` and the
complete runtime audit CSV. No files were removed from the main game repository.

Fortnite is absent. Initial hardware: RTX 3060 12GB, 9,479 MiB free VRAM,
7.2 GiB available RAM, 8.5 GiB commit headroom and 445.8 GiB free on D:.
Both drive write/read probes passed. D: PyTorch CUDA arithmetic and Blender 4.5.3
imports pass. Nine safety tests pass, including low-commit and GPU admission gates.
`runtime-env.ps1` and `run-pet-factory.ps1` isolate caches/temp on D: and use offline
model lookup. User-level `AK_3D_ROOT` points to D:; system TEMP is not modified.

Fresh Ocelot run `outputs/ocelot-d-reproduction-001` passed all local stages and
four-view visual review. Bidirectional geometry distance to the approved asset
is zero; front-render SSIM is 1.0. The recipe, source and weights are unchanged.
Native Studio import succeeded. Body mesh 86956296653033, fur mesh 83705741042121
and texture 89955741043720 were independently recreated/preloaded successfully.
See `audits/d-ocelot-reproduction` and `audits/d-ocelot-studio-assets.json`.
The review scene's saved persistence is unverified; the uploaded assets and local
GLB are preserved. No gameplay registration or reward interaction is certified.
Live read-only readiness checks still pass Meadow/Forest family bindings; all ten
future ContentReady gates remain false. This does not certify interaction QA.

Two fresh Tapir inferences and six downstream diagnostics are preserved under
`D:/AnimalKingdom3D/outputs/tapir-d-*`. None passes complete art QA. The latest
four-view texture diagnostic retains jagged eyes, mottled fur and malformed ear
detail, and exceeds the 2.5 depth limit (2.52735). Both front-paw numeric floor
checks pass; that does not establish acceptable anatomy. No thresholds were
relaxed and no failed candidate was imported or registered. The frontal recipe
is explicitly diagnostic. Its concept was rendered from an existing historical
Tapir reference asset; only the rendered images feed fresh TripoSR inference.
No paid generation was invoked. Experimental symmetry/projection scripts remain
separate from production refinement, which is unchanged.

BLOCKER: C: has zero free bytes. Studio logged SQLite disk-full errors against
its C: rbx-storage.db-wal and then exited following a failed file write. Native
imports and live tree interaction QA cannot continue in that state. Studio's
78 screenshot cache files were copied and individually hash-verified on D:,
then the exact original cache directory was redirected with a junction. Other
activity consumed the small amount recovered; C: remains full. No unrelated
files were deleted and no user processes were terminated. D: still has over
428 GiB free. Logs and relocation evidence are in the runtime audit directory.

Resume: restore adequate C: headroom for Studio and verify it stays available;
reopen the test place and recreate the Ocelot review from its uploaded IDs if
needed; finish a distinct second species that passes four-view art and geometry
QA; then produce/import/register the 250 planned future-biome pets in batches,
map families and test every tree reward loop. Keep all future gates locked until
their QA passes. E: remains intact until the full D: pipeline is verified.
The full requested goal is incomplete. No Roblox game publication occurred.

The older checkpoint below is retained as failure history.

User approved the original free Ocelot. Its GLB SHA256 is
`d00c5ceb074ec9e67ec8eeaaae7a358d7cc4f4dd04e9b475958eada868b67cc7`.
The original asset is preserved unchanged. Approval of that asset is not evidence
that the newly packaged pipeline reproduces it yet.

Implemented: pinned vendored inference source, model hashes, environment snapshots,
preserved successful scripts, configurable stages, separate non-overwriting run
directories, four-view previews, numeric validation, explicit visual approval gates,
and native Roblox import preparation. Five approval-gate tests pass.

Clean reproduction results so far: 0 successful / 4 attempts. Attempts 001–003
crashed with native Windows access violation in PyTorch `param.copy_` while loading
the checkpoint. The untouched original script reproduces the same crash in
`outputs/original-workflow-diagnostic-001`. Attempt 004 used a separate diagnostic
recipe to stream identical FP16 weights to CUDA and failed with CUDA out-of-memory.
That loading variant is experimental and is NOT the production default. No new
geometry from these runs passed QA. Logs and manifests are retained in audits.

At investigation time: RTX 3060 12GB, approximately 8.5GB reported free VRAM,
16GB installed RAM, approximately 3GB available Windows commit, C: about 52MB
free, E: about 221GB free. Fortnite alone used about 4.4GB resident RAM. The CUDA
error despite available VRAM may involve WDDM/system commit; this is a hypothesis,
not a confirmed diagnosis. A temporary Fortnite closure was requested while
independent implementation continues. No user processes were terminated.

Live audit: each of ten future biomes has 25 anonymous registered pet slots,
250 total. Jungle has five empty named tree families; the other nine have no
explicit family definitions. Physical art copies are not equivalent to reward
families and require deliberate mapping. Meadow and Forest are preserved.

Follow-up: seven gate/roster/source-lock tests now pass. The downstream diagnostic
reused the preserved raw neural mesh (NOT fresh inference) and successfully ran
projection, Blender refinement, export, previews and validation. Exported vertex
distances against the approved GLB are exactly zero and front-render SSIM is 1.0.
Both meshes and the 2048 texture reopen correctly. See the downstream audit JSON.
An unused PyTorch import was removed from projection by preserving the licensed
rasterizer in its own module with explicit graphics-context release.

Fresh inference remains 0/5. Attempt 005 directly constructed the same FP16 model
on CUDA; it failed allocating 20MB despite reporting 10.49GB free VRAM. Diagnostic
recipes are retained separately; the approved recipe remains unchanged. A Tapir
recipe and background preparation test have been added for the second-species test.

`roster.json` contains 250 distinct production species names, curated gameplay
weights and incomes calculated from existing biome ranges. Rarity counts match
the current architecture. Each proposed family has five slots. Assignment is
provisional pending live tree-art mapping; none of these entries is registered
in gameplay, and missing models are explicitly marked rather than substituted.

Remaining: resolve loading failure, clean Ocelot comparison, second original
species generation and art QA, durable Studio import verification, complete
unique rosters, all future-biome production, full feature integration, and every
tree-family reward test before biome release. No future biome has been released
and the Roblox game has not been published. The full user task remains active.

Continuation audit: current Studio definition/model/tree-binding checks pass for
Meadow and Forest without edits. Jungle's five families remain empty and none of
its 35 authored trees has a family binding. The other nine future biomes lack
configured families. `studio_readiness_audit.luau` reuses the game's canonical
validator/resolver and records these failures without certifying interactions.
The report is preserved under audits. Tapir background removal also completed;
its isolated concept, input/output hashes and exact U2Net model hash are saved.
