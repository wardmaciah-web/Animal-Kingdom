# Latest checkpoint - guarded storage, queue and memory supervision

2026-10-09: continued from 2a3c54e. Added the resumable factory controller,
per-job D: scratch, immutable preserved bundles and verification-gated cleanup.
Only explicitly inventoried disposable files in new factory-owned scratch jobs
can be removed, after matching durable import/registration/full Studio QA and a
pushed canonical Git checkpoint. Final meshes, Blender files, textures, references,
recipes, QA, asset IDs and checkpoint records survive. Historical and failed
unverified outputs are never adopted for deletion. Low-disk cleanup uses the same
gates; 10 GiB storage reserve is enforced. See FACTORY.md for receipt/queue use.

System commit is measured with GetPerformanceInfo. Owned child workers have a
0.5-second RAM/commit watchdog, before/after resource telemetry, bounded shutdown
and wait. Shared generation locking now also covers saved-mesh refinement.
Admission remains 4 GiB RAM / 16 GiB commit / 7 GiB VRAM; emergency stop reserves
are 1 GiB RAM / 4 GiB commit. No claim of successful full SDXL loading yet.
Proven FP16/mmap, low-CPU-memory loading, VAE/chunking and model quality fixes
remain. Prompt lengths are checked before SDXL allocation; Coati's revised seated
species prompt and explicit malformed-paw/photorealism exclusions use 60/51 tokens
in both tokenizers. New final art checks explicitly reject duplicated limbs,
malformed paws and photorealistic proportions.

46 automated tests pass, including owned-process termination with an unrelated
test process left running, real Windows junction rejection, archive corruption,
unpushed checkpoint rejection and idempotent cleanup. Initial archive tests ran
on low-space C: temp and correctly hit the disk gate; the fixture now isolates
disk measurements, final tests run with D: temp. Both logs are retained.
Python compilation and unchanged src/tests gameplay diff verified.

Actual queue initialized at D:/AnimalKingdom3D/factory/queue.json: 248 remaining
pets, Coati ready, 247 need species recipes. Real queue run returned
resource_blocked without launching a model or recording an inference attempt:
5.44 GiB RAM, 10.33 GiB commit headroom, 11.09 GiB VRAM, 408.71 GiB D: free.
Automatic C: pagefile remains 11205 MiB (3988 MiB used); unchanged. No generation,
Blender or Studio worker remains. Studio tool listing returns no connected place.
ForgeGUI read-only capabilities respond but expose no balance or per-call cost;
no paid generation submitted. No subscriptions, pagefile edits or app termination.

All 35 Jungle mappings, approved Ocelot/Red Panda, Meadow/Forest and ContentReady
gates remain unchanged. No game publication. Evidence: audits/factory-20261009/.
Remaining: fresh admission pass, supervised Coati concept/mesh/four-view approval,
durable Studio import/registration, real physical-tree reward, rarity/weight/income,
Inventory/Held/followers/Sanctuary/Index and isolated save/rejoin/ownership checks;
then archive/checkpoint/cleanup and next pet. Multiplayer remains unverified.

## Previous checkpoint - physical Jungle tree mapping and isolated payout/rejoin QA

2026-10-09: all 35 existing Jungle trees are assigned through canonical explicit
visual/source metadata. Rainbloom5, EmeraldCanopy5, Orchidwood4, Sunvine15,
AncientBanyan6. Positions, visuals, rarity weights, progression and release gates
are unchanged. Unknown/conflicting mappings fail closed; no generic pool fallback.
TreeFamilyDefinitions owns the mapping; WorldContentService and ResourceService
bind metadata; EggService verifies the authored family at payout.

Actual Orchidwood/Ocelot and Sunvine/Red Panda gathers passed in the private Studio
server with the separate AKJungleTreeQA_4e9674b_20261009 datastore. Unique UIDs,
duplicate gather rejection, foreign UID rejection, Inventory/Held transitions,
owned Sanctuary placement, durable datastore reads and full stop/start rejoin
passed. Client rendered the same owned follower/Sanctuary models; Pets STORE and
HELD buttons worked. Only runtime Jungle.ContentReady was temporarily enabled
during controlled gathers, then restored. OriginalData1 source and mock setting
are restored; no QA scripts remain. Solo testing does not certify multiplayer.

Evidence: `audits/jungle-tree-20261009/`; regression harnesses under `tests/`.
24 safety tests and Studio family regression pass. Initial harness Source-access
and rate-limit failures were corrected without bypassing production validation;
their evidence is retained. Existing unrelated Studio source differences were
preserved with targeted edits rather than a whole-project overwrite.

Full local Studio recovery copy saved through Download a Copy:
`D:/AnimalKingdom3D/checkpoints/AnimalKingdom-JungleMappings-20261009.rbxl`
SHA256 940e8bc257221da35aed982b0873828cdcc7ec869ba17d525a61c6b5888f7eb8.
Studio closed normally afterward. Stopped animated wallpaper using its supported
control command and closed NVIDIA settings normally; no forced app termination,
pagefile change, reboot or publication. AI/cache/output paths remain D:.

Coati guided005 completed three free concepts, exit0 (116.828s); visual inspection
rejected all for short raccoon-like muzzles and insufficient ringed-tail identity.
Anatomy006 failed cleanly on the tokenizer limit (78 > 77); its prompt was shortened.
Anatomy007 passed admission at 6.74 GiB RAM / 12.27 GiB commit / 11.64 GiB VRAM free,
but loading reduced commit headroom to 289220 KiB. Stopped only its identity-checked
worker PID30092; supervisor recorded exit4294967295 and all Python workers exited.
No overlapping jobs. No mesh produced or pet registered. Logs/configs retained.
Commit admission is now 16 GiB with an observed-pressure regression test. Generation
is paused until a fresh check passes; no pagefile resize or reboot was performed.
Animated wallpaper restored after worker exit. Studio remains closed; use the saved
local recovery copy above. Approved pets unchanged; 2/250 registered.
Remaining: restore safe headroom, finish species-correct Coati concept/mesh/four-view
and Studio QA, then continue roster; multiplayer reward/ownership QA is outstanding.

## Previous checkpoint - stability and reward cache verified, generation held

2026-10-09 UTC: see `audits/stability-20261009/`. No generation worker is
running. Coati guided 001 failed the old commit gate; 002/003 have orphaned
loading manifests and truncated logs (exit status unknown); 004 logged CUDA
allocation failure followed by MemoryError. No candidate was produced by these
four runs. Preserve the original logs; do not assume a loading manifest is live.

Current admission snapshot: available RAM 4.47 GiB, commit headroom 7.13 GiB,
RTX 3060 free VRAM 10.07 GiB. Windows automatic C: pagefile is 11,205 MiB;
usage 4,923 MiB, peak 8,632 MiB. C: has about 9.83 GiB free, D: 408.74 GiB.
No OS/pagefile changes or unrelated process termination. All generation/cache/
output paths remain on D:. Commit admission raised from 6 to a conservative
12 GiB after failures passed the old threshold. This is a safety margin, not a
guarantee or proof of the failure's root cause. RAM/VRAM checks remain 4/7 GiB.
Unknown RAM/commit measurements fail closed. Concept and reconstruction entry
points share an OS-held exclusive runtime lock; no overlapping job was launched.

Studio cache reproduced: saved Sunvine source contained Red Panda but require()
returned empty family/reward arrays. Refreshed ImportedPetDefinitions,
PetDefinitions, TreeFamilyDefinitions and EggDefinitions instances in Edit;
the three registration/pool sources use canonical saved source, and the live
PetDefinitions source (including existing absolute-weight policy) is preserved.
No approved models, probabilities, or ContentReady gates changed.

Fresh Play runtime Server Script verifies all 15 configured family memberships;
Sunvine contains JungleRedPanda at DropWeight4, Orchidwood contains JungleOcelot
at DropWeight12. Client agrees. Existing Meadow/Forest pools unchanged.
All 35 physical Jungle trees still lack Sunvine mapping; their prompts are
disabled COMING SOON. Real Sunvine payout is NOT verified and cannot be claimed
until authentic tree-family mapping/content readiness is resolved. Play stopped;
temporary runtime audit objects are gone. No game publication or place save.

23 safety tests pass. Resume generation only after a fresh admission pass and
checking active workers; inspect one supervised result before another attempt.
Remaining Studio QA: authentic Sunvine/Orchidwood physical mappings and eventual
real tree payout, ownership/save/rejoin and existing-tree regressions when the
biome is legitimately ready; keep Jungle locked meanwhile. Pipeline remains
incomplete (2/250 registered). Pre-existing review-script edits are left unstaged.

## Previous checkpoint - Red Panda imported, pet QA passed, registered

Resume from the Git commit containing `audits/red-panda-studio-001/`.
DO NOT regenerate Red Panda. Native model: `src/ReplicatedStorage/PetAssets/JungleRedPanda.rbxm`.
Saved GLB remains a9388ee117900de354169310c9396e7697009e5e5e26c410a9672db800a791fd.
Studio review: `Workspace.AK_JunglePetReview.RedPandaTextureReview` (existing Jungle review root).
Canonical template: `ReplicatedStorage.PetAssets.JungleRedPanda`.

Native import, shared-lighting 2.8-stud comparison with original black bear and
approved Ocelot, face/front/side/back inspection passed. Red Panda has softer fur
than the references, with no prior side/back white patches. Body normal texture
and cleaned color bindings retained. Body casts shadows; decorative fur does not.
Source model is engine-serialized RBXM, roundtripped with two real MeshParts.

Actual runtime Script tests (not plugin-context Knit copies) passed UID uniqueness,
foreign/forged UID rejection, Held/Inventory movement, client UI Inventory and
equip, follower creation, owned Sanctuary placement, durable datastore read and
full stop/start rejoin. Both UIDs, locations and weights survived; follower and
Sanctuary display reappeared. Tests used separate `AKPetFactoryQA_RedPanda_21b30d9`
store; production OriginalData1 source and mock attribute restored afterward.
Temporary QA definitions restored before final registration; no QA scripts remain.

Registered Epic Red Panda in Sunvine / Jungle_Shakeable_04: BaseWeight7,
BaseIncome130, DropWeight4. Note live Studio uses its existing absolute 0.01-70kg
weight policy; BaseWeight7 is reference metadata, not a minimum rolled weight.
Existing live weight/HUD code differs from this checkout and was preserved.
Source changes are only Red Panda definition, Sunvine membership and real RBXM.
Ocelot, Meadow, Forest, all existing assets and ContentReady gates unchanged.
Registered production count: 2/250. Next bounded candidate: JungleCoati guided
concept using original bear/Ocelot references; no mass auto-acceptance.

Coati initially failed the unchanged 4 GiB RAM admission check. Reclaiming the
task-launched Studio's cached working pages subsequently freed enough RAM
(6,074,421,248 bytes free); no unrelated apps were closed and no guard bypassed.
Guided concept run: D:/AnimalKingdom3D/outputs/coati-guided-001. Inspect its live
manifest and candidates before proceeding; do not assume inference or QA passed.

Remaining BIOME QA: no physical trees currently map to Sunvine in the loaded
place. Correct reward pool is ready, but a real Sunvine tree payout cannot be
claimed tested. An in-range Jungle tree interaction returned COMING SOON and
changed neither coins nor pets. Jungle/future biomes stay locked. Existing HUD
Shop overlaps part of Pets navigation; its unobscured right edge opens Inventory
and was tested. Existing ActivityCoordinator startup error on a fresh QA profile
was observed; no related source was modified. These are not pet-model failures
or full-game QA. Direct asynchronous normal-map preload did not complete before
the test session ended; bound normal-map rendering was visually reviewed instead.
No paid calls or Roblox experience publication.

## Previous checkpoint - 2026-10-08, texture-only repair

Resume `audits/red-panda-texture-001/pet.glb` (same accepted geometry).
SHA256: a9388ee117900de354169310c9396e7697009e5e5e26c410a9672db800a791fd.
Editable Blender scene: `audits/red-panda-texture-001/preview-scene.blend`.
Runtime output: D:/AnimalKingdom3D/outputs/red-panda-texture-001/review.
DO NOT regenerate or adjust the user-approved geometry, tail or sitting pose.

Blender surface-space pigment repair removed the neural white patches and colored
speckles from the sides/back. Retained original front facial pigment, expressive
eyes, normal map, fur geometry and UVs. All exported vertices/faces/UVs are exactly
identical to checkpoint 528f6b5 (maximum vertex delta 0). Both grounded-paw checks,
embedded 2048 color/normal maps, 23,500 triangle budget and Blender reopen pass.
19 existing tests pass. Four original-scene and four reopened-export views saved.
Approved Ocelot rendered with the same neutral lighting at nominal 2.8 height;
original black bear screenshots reviewed. Ocelot file hash is unchanged.

Local side/back texture repair passes inspection. This is NOT final art acceptance:
front retains some small inherited dark flecks; fur is less sculptural than Ocelot.
Matched black bear comparison, overall art acceptance and all live gameplay QA
remain outstanding. Studio MCP reports no connected instances on repeated checks.
No import/registration/ownership test has happened for this candidate. Notion stage
is Studio Testing / Partial. Next: connect Real_Animal_K, import this exact GLB to
Workspace.AK_PetFactoryReview.Jungle, set decorative fur CastShadow=false, compare
all three pets at matching scale/lighting. Only after Studio art approval, confirm
Sunvine family mapping (proposed Jungle_Shakeable_04, Epic, 7kg, income130), then
register the reward and test tree grants, UID ownership, Held, followers, Sanctuary,
save/rejoin and old-pet regressions. Keep all ContentReady gates unchanged.

No src changes, Meadow/Forest edits, new inference, paid tools or game publication.
Registered count stays 1/250. Remaining production waits for second-species QA.

## Previous checkpoint - completed local trials

Design-first workflow is implemented. Preserve the selected guided Red Panda
2051; stop discarding designs for minor paw pose. The latest real review model is
`audits/red-panda-final-review/red-panda-polish-003/red-panda-review.glb`.
SHA256: abaf670650c3e6155662c230ea74bd81685c915ca6ca017bc38cdec13679e9e8.
It is NOT art-approved, imported or registered. Surface speckles and patchy
side/back material still need cleanup; do not claim an excellent second pet yet.
The selected design and complete seated mesh are retained for continued work.

Found/fixed a concrete preprocessing defect: rembg removed the original tail
before reconstruction 003. Reviewed original-pixel alpha restoration and pinned
prepared SHA256 c472a583df3f8b858384c8cff83727a8a263d925553c297d593b0d1ad0b87ca1.
One documented fourth inference rebuilt the full tail. The current bounded
inference budget is exhausted; continue refining this saved mesh before any more
inference. This is a production retry limit, not a request for user permission.

Blender polish: optional high-resolution color rebake after decimation, median
speckle filtering, outward open fur shingles, decorative fur shadows disabled,
and masked directional fur normal bake. Ocelot defaults/assets are unchanged.
Latest GLB passes numeric/ground-contact/Blender-reopen checks: body 18,000 and
fur 5,500 triangles; embedded 2048px color and normal maps; 2.8-stud target height.
19 automated tests pass. Four-view art review is explicitly rejected for surface
finish, not for slight concept pose. Latest source-run path is
D:/AnimalKingdom3D/outputs/red-panda-polish-003; original projected mesh is in
D:/AnimalKingdom3D/outputs/red-panda-reconstruction-004. All worker processes ended.

Studio MCP remained disconnected on three checks. Next: clean the saved model's
surface and rear fur/tail definition without regenerating its design, repeat
four-view comparison against black bear/Ocelot, then reconnect Real_Animal_K.
Verify import/color/normal maps and decorative fur CastShadow=false, actual paw
stance, correct tree pool/reward rarity/weight, ownership/UID, equip/follower and
save/rejoin. No src changes, no Meadow/Forest changes, no biome unlocks, no paid
calls and no Roblox publication. Registered production count remains 1/250.

---

# Design-first / Blender-repair checkpoint - 2026-10-08

User revised the workflow after 36d17ce: AI designs face, fur, proportions and
species; Blender repairs minor sitting/paw/hind-leg issues. Collages, severe
anatomy distortion and wrong species remain rejected. Final mesh and Studio
QA remain mandatory. Focus on ONE excellent second Jungle pet.

Added optional soft-selection Blender pose operations and saved-mesh refinement
runner. Eighteen tests pass. Approved Ocelot recipe/GLB and all src/ are unchanged.
Red Panda designs 1042 and 2042 were reassessed as reconstruction-eligible under
the new gate. Two fresh reconstructions and two Blender repairs are preserved
in audits/red-panda-blender-repair. The first reconstruction is badly damaged;
the frontal one is numerically valid but not art-approved. The first repair
stretched the chin/chest; the narrowed repair preserves all 51,451 upper-body
vertices exactly but still flattens the forelegs. None is approved for import.

Free local SDXL img2img now explicitly uses the Ocelot render for design guidance,
with black bear comparison still mandatory. Three new Red Panda designs rendered;
2051 selected for stronger face/eyes/species identity, with tail material detail
still requiring review. Its source is audits/red-panda-guided-concepts-001.
Fresh reconstruction 003 is running on D: at this checkpoint. Resume its manifest
rather than starting another inference. No second pet registered; remains 1/250.
Studio MCP currently reports no connected instances. No paid calls or game publish.

---

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
