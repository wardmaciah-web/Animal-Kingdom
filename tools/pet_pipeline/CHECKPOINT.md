# Resume checkpoint - 2026-10-08 evening

Verified origin/main and local main at af7a2397aa6fc4a821047e78eecb824d6340565a,
a descendant of requested 8cc744d. Continued existing uncommitted concept work.
Approved Ocelot GLB SHA256 remains d00c5ceb074ec9e67ec8eeaaae7a358d7cc4f4dd04e9b475958eada868b67cc7.
No src/ changes; Meadow/Forest and future ContentReady gates preserved.

Free local SDXL now completed two batches: Red Panda 006 and Coati 001, three
1024px concepts each. All SIX fail visual review (raised/hidden paws, missing tail,
or multiple subjects). Exact prompts, seeds, hashes and previews are in audits.
No second pet is approved, reconstructed, imported or registered. Count remains
1/250. Do not promote these images or resume rejected Tapir trials.

Pipeline improvements: retained CUDA checkpoint loading workaround and encoder
release from interrupted work; supervised stderr/exit recording; stage records;
reject truncated prompts; release candidate/cache allocations between images.
Coati supervisor ran end-to-end with exit 0. Fifteen tests pass. All twenty local
SDXL files match pinned SHA256 hashes. No paid inference. A transient git malloc
failure occurred during concurrent generation; serialize memory-heavy operations.
No workers remain running at checkpoint. Studio MCP returned no instances twice;
Studio import, Rojo connection, and tree/ownership QA remain unavailable.

Next: controlled-pose original concept that visibly passes isolation, four paws,
matte sculpted fur and expressive-eye review; then fresh TripoSR and four-view
mesh QA. Prompt-only SDXL has not established acceptable repeatable anatomy.
Reconnect Real_Animal_K (place 132313449035787, universe 10764288431) before import;
verify Ocelot template/texture and Orchidwood tree shake, authoritative reward UID,
weight/rarity, inventory ownership, equip/follower and save/rejoin behavior in an
isolated Studio session. Keep future biomes locked; never publish the experience.

---

# Implementation checkpoint — 2026-10-08

## Bounded retries and next species

Resumed from 8cc744d. Ocelot registration/assets and its recipe are preserved.
No source/game changes. Tapir is now explicitly deferred in production policy;
the entry point blocks more inference. Pending species receive at most three
fresh-worker attempts, including failed starts; downstream saved-mesh trials
do not consume that inference budget. Twelve safety tests pass.

The single allowed saved-mesh diagnostic 023 corrected fur normal alignment
(63.3% inward to 0%) but visibly worsened black triangular fur artifacts.
It is rejected. The experimental normal override was removed from production;
its exact worker, output hashes, validation and renders are preserved. Merged
rear anatomy remains unresolved; do not keep iterating Tapir.

Red Panda is selected as the next distinct furry Jungle species. A separate
D: concept environment and pinned public SDXL FP16 download add a free local
concept path without changing TripoSR dependencies or invoking paid services.
See LOCAL_CONCEPTS.md. Initial RAM was below admission threshold; a later
4.01 GiB RAM / 7.62 GiB commit / 9.56 GiB VRAM preflight admitted diagnostic 023.
Recheck before loading any new model. Concept weight download/verification is
in progress; no Red Panda concept, mesh or approval is claimed yet.

## D: migration continuation

RESUMED after user storage recovery. C: 11.54 GiB free, D: about 416 GiB free;
Fortnite absent. D: write/read, CUDA arithmetic and Blender 4.5.3 smoke checks
pass, with all temporary directories on D:. Nine safety tests pass. The correct
Studio place 132313449035787 / universe 10764288431 is open again. Both prior
D: Ocelot review models persisted, including their uploaded mesh/texture IDs.

The approved Ocelot is now a verified production template in
`ReplicatedStorage.PetAssets.JungleOcelot`, registered as Rare, 12 kg base weight,
93 base income, in Orchidwood (`Jungle_Shakeable_03`, drop weight 12). Fresh
module-snapshot tests resolve/clone both meshes, validate the economy/pool,
preserve Meadow/Forest family membership and prices, and confirm all future
gates remain locked. Actual tree interaction QA is still pending. Source and
idempotent Studio registration/verification scripts are committed together.

Tapir trial 022 has completed: numeric validation passes (25,994 triangles,
2048 texture, 2.8 height, both front paws grounded), but four-view art review
rejects the side/back anatomy and dark fur-lock artifacts. The second original
species production test is NOT accepted. Repeated downstream material/UV/fur
experiments do not resolve the reconstructed rear silhouette. Trial 017 tested
fresh angled-image inference and failed depth/art QA. No failed Tapir is imported.
See `audits/d-tapir-resumed/review.json` for precise findings, checksums and next
steps; full GLBs, Blender files, scene codes and logs remain on D:.

The runtime/storage blocker is resolved. The current production blocker is
Tapir reconstruction/art QA. Remaining scope is 249 approved models, including
Tapir, future-tree mapping/prices, reward integration and live interaction QA.
Do not repeat the successful Ocelot reproduction or promote rejected trials.
Source/asset bindings and registration scripts are saved; a new full-place local
save was attempted but not verified because Studio's native input produced no
save dialog. No paid calls or publication; Meadow/Forest and future locks persist.

## Historical continuation notes (superseded where stated above)

Storage blocker verified for a third consecutive goal turn: C: is still at zero
free bytes and Studio is absent. A 586,572,498-byte Roblox download cache was
identified as a possible relocation target. The proposed copy/hash-verification,
original removal and D: junction operation was rejected by automatic approval
review with reason "blocked by policy". It did not execute; do not retry the
same removal through another shell or tool. External C: storage recovery is now
required for Studio integration and tree-interaction QA.

Surface-transfer diagnostic 015 completed after cancelling 014's inefficient
queries over empty atlas pixels. It passes numeric validation but visibly fails
art QA (patches, damaged eye borders, misplaced texture regions). It remains
rejected, with no imported/registered Tapir. Source geometry is the fresh 007
inference; only material color was sampled from the existing owned reference.
Evidence and the diagnostic script are in `audits/d-tapir-surface-transfer`.
No generation process remains running. The goal is blocked, not complete; after
storage recovery resume second-species correction and fresh QA, then the full
250-pet production/integration/tree-testing scope. Keep all future gates locked.

Latest continuation: Studio remains absent and C: remains at zero bytes. No
default Hugging Face, Torch or pip cache was found on C: to relocate safely.
Local diagnostics 009-013 continued on D:. Disabling decimation reduced texture
faceting; rebuilding UVs after decimation restored clean front eye detail at
the game budget. Three degenerate triangles had to be removed before xatlas
to avoid NaN normals. Candidates 012 and 013 pass numeric QA (24,396 triangles,
2048 textures, 2.8 height, 2.46955 depth, both paws on the floor), but still fail
art QA: 012 stretches the side texture, while 013 duplicates eyes/ears in side
projection. Neither is approved or imported. See `audits/d-tapir-reunwrap` for
four-view comparison excerpts, validation, configurations and diagnostic scripts.
Next local step is correcting side-view projection registration and head ridges,
then proving the revised stages from fresh inference. Production workers and
the approved Ocelot recipe remain unchanged. The full goal remains active.

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
