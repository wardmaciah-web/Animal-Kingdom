# Jungle regeneration after unlimited-credit authorization

## Outcome
PARTIAL AND BLOCKED, not ready for two-pet visual approval. The user's unlimited generation-credit authorization applies only to Rainstripe Tapir and Canopy Toucan; it does not authorize credit-pack/subscription purchases. No purchases occurred. No new species, reward-pool edits, Jungle unlock, original template edits, or experience publication occurred.

## Preservation
Before regeneration, the entire existing review folder was cloned to ServerStorage.AK_JungleBeforePaidRevision_20261008. The original workspace Tapir and Toucan material/geometry revisions remain intact. Their custom EditableMesh/EditableImage content is still session-only; the clone is NOT a durable binary export. Keep Studio open. Previous revision recipes/ledger remain committed at 1dec65fa3e2c36fa6b9266d886189af9b1bf1e15.

## Tool blocker and route selection
ForgeGUI capabilities report high-quality model generation and a personal Roblox Model upload destination @Maciahxcx1 (connection 718e04c2-533c-49fb-9683-e1ef6c7a3b65). The requested high-quality generation, request ak-rainstripe-tapir-premium-20261008-v1, was rejected by the client: "MCP tool call requires approval, but approval policy is never." No ForgeGUI generation job or billing receipt was returned. User authorization did not overcome the session tool restriction.
Native Roblox generation was usable. Two initial prompts failed "Character limit exceeded"; shorter prompts succeeded. No image-guided 3D input is exposed by native generate_mesh. Actual reference meshes were inspected and their earlier captured imagery reviewed; generation used descriptions of their style, not copied geometry. No runnable supported Blender/refinement export route was established in this read-only local filesystem session.

## Native generated source assets and quality decisions
| Source | Model asset ID | Generation ID | Result |
|---|---|---|---|
| Tapir first successful retry | 84415449329074 | 31386c21-8572-4758-a477-9f414ee25b9c | Rejected: long face, tiny eyes, crest, smooth surfaces |
| Tapir rounded retry | 85556258141652 | 22f85eaf-0774-4115-b456-074b4af07420 | Rejected: tiny eyes, unwanted crown protrusions, flat texture, weak tapir anatomy |
| Tapir anatomy retry | 138433180389405 | 25746402-42aa-40ab-92f7-9ae87e881976 | Rejected: crest, weak cream stripes, tiny eyes, excessive smooth shine |
| Toucan regeneration | 122094076926904 | 66807ee2-4126-454c-a609-219214b776c4 | Retained for comparison only: better layered feathers/larger eyes; still overly smooth beak and insufficient painted richness |

All three rejected Tapirs are archived under ServerStorage.AK_JungleBeforePaidRevision_20261008.RejectedNativeCandidates. The regenerated Toucan is Workspace.AK_JunglePetReview.CanopyToucanPremiumCandidate, beside reference copies and the original two review pets. QualityApproved is false.
One Toucan native texture pass was inspected (tag RBXAI-TexturedMesh-TextureGen-d64a4392-9c7a-47c9-bacd-9612f1c2399d) and discarded because eyes/facial shading degraded. The retained Toucan uses its ORIGINAL generation mesh/texture bindings. Discarded retexture is archived in the backup folder.

## Credit accounting
ForgeGUI completed generation calls: 0. No ForgeGUI debit receipt returned. Native submissions: 6 mesh requests, of which 2 failed prompt-length validation and 4 completed; 1 texture request completed but was rejected on visual inspection. Native MCP responses expose no billed amount or balance. Actual native credit usage is UNKNOWN, not zero and not estimated. No purchases/subscriptions.
Native mesh jobs: 6f5cb4cb-1b69-4283-a6d2-7d40ddd56ae2 (failed), df222a63-6fcc-4e23-b314-4a2d07cb212f (failed), eb38ba6b-4db6-4230-a2fb-ea6a144f5eff (completed first Tapir), dc6d66b0-fc27-4140-beab-7d983c7fe16e (completed rounded Tapir), 22e92ba5-b483-4692-95a4-4d9d3ac7f3a2 (completed anatomy Tapir), 2eaa9f60-bf64-48a4-85ac-665aada651ed (completed Toucan).
ForgeGUI tracking run: 0d274e8f-7480-4f74-be48-a356b34614b0. It records caller-reported native activity, not verified native billing.

## Verification
Checked rendered geometry and textures, source mesh/texture URI bindings, model pivots, bounding boxes and grounding. Native candidates were normalized to maximum dimension 2.8 studs, anchored and noncolliding. New Toucan has six MeshParts with durable URI MeshIDs and TextureIDs, but NO SurfaceAppearance PBR maps. Native outputs do not satisfy the requested final PBR material finish. Existing session-edited two pets still have their maps, untouched.
Front, side, three-quarter Toucan captures and a same-row comparison with Field Mouse/Owl/Bear are saved in this directory. Rejected Tapir inspection images document failures. Scene lighting unchanged. This is candidate art review, not end-to-end weight scaling, inventory, follower or Sanctuary verification. No final game integration was attempted.
Binding ledger is studio-audit.json; durable model asset IDs above can restore generated source assets. Saved screenshots and binding ledger do not constitute an exported binary of older session edits.

## Next prerequisite
A usable high-quality reference-guided generation/refinement route and durable export route are required. The current session rejects ForgeGUI paid generation despite the user's spending authorization. Native retries did not achieve the reference standard. Do not claim both pets are ready, approve them automatically, or continue the Jungle collection.
