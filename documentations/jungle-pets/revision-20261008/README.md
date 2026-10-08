# Jungle pet material and geometry revision — partial, not approved

Only the two existing review pets were edited. No new pet model generation, paid ForgeGUI calls, additional credits, experience publication, reward-pool edits, Jungle unlock, or original Meadow/Forest template edits occurred. Paid generation credits spent this revision: 0.

## Actual changes in Studio
All 13 Jungle MeshParts have live SurfaceAppearance color, normal, roughness and metalness content. Color maps include fine directional variation; normal maps add shallow surface relief. Roughness is 238/255 and metalness is zero. These are actual editable image maps, not changes to Reflectance alone.
Tapir: one native texture revision retained, warmer brown with cream juvenile markings; head/eye area reshaped; central head and body crest vertices flattened. Remaining crest-like protrusions and the upright stance are still visible.
Toucan: a native texture revision was inspected then discarded because facial UV/panel artifacts were worse. Original matching mesh/texture bindings were restored before applying PBR and geometry edits. Eye region reshaped. Chest and wings have 216 small raised feather overlays (864 additional triangles) integrated into editable meshes. Beak is matte with color gradients. Feet and tail anatomy have not received the requested premium redesign.
The procedural fine pattern is too uniform and looks cloth-like in places. These edits do not achieve the requested richly sculpted, professionally painted fantasy-animal finish.

## Visual findings
Front and three-quarter comparison rows include copies of Meadow Field Mouse, Forest Owl and Black Bear, under the same unchanged scene lighting. Close side images show the remaining limitations. Both new pets still have smaller/less expressive eyes, simpler painted texture variation and less integrated fur/feather sculpture than the references. The Tapir crest is NOT fully removed. Do not mark art quality complete.
Images are committed beside this report: front.jpg, side-tapir.jpg, side-toucan.jpg, three-quarter.jpg. Comparison row order from front capture: Mouse, Owl, Toucan, Tapir, Bear. Side captures are close inspection images rather than matched-distance comparison rows.

## Persistence blocker
AssetService:CreateAssetAsync returned "CreateAssetAsync and CreateAssetVersionAsync are not available yet" for attempted image saves. Custom images and six edited meshes currently use Content.SourceType Object in Studio, with empty MeshId on edited parts. They have NO new durable Roblox asset IDs. Do not assume saving a place or the old rbxmx preserves editable content. Keep this Studio session open until durable export/upload is available.
The pre-revision model assets remain Tapir 122381160257662 and Toucan 136689948933009. They do NOT contain this revision. Source URI bindings and current transforms are recorded in studio-audit.json. Existing source assembly remains ../NativeJungleReviewModels.rbxmx.
This commit preserves the edit recipes and images, not exported revised mesh/image binaries. Local filesystem is read-only, so local binary export is also blocked. A supported durable mesh/image upload or writable export route is necessary before completion.

## Recipe provenance and replay limitations
Recipes are ModuleScript sources retained in ServerStorage in the live session. They return a table with Apply(reviewRoot); retain returned tables to keep editable resources alive.
Geometry-first recipe was applied to both native texture revisions; the Toucan revision was subsequently discarded. For a clean replay use geometryRecipe restricted to RainstripeTapir with its new source URI bindings in the ledger, followed by crestRecipe and bodyCrestRecipe. Toucan uses original model bindings, toucanGeometryRecipe and featherRecipe. Apply pbrRecipe for Tapir and toucanPbrRecipe for Toucan after geometry. Do not apply every recipe blindly or run twice: they deform/add geometry. This replay ordering has not been independently tested from a fresh Studio session.
The native Tapir texture operation tag is RBXAI-TexturedMesh-TextureGen-d62a4e28-e6ef-4c54-bbfd-bf8f9d25aa04. Discarded Toucan tag is RBXAI-TexturedMesh-TextureGen-43e86a57-3e85-4893-8355-a23db44dca35.

## Verification and gate
Checked actual MeshContent, TextureID, SurfaceAppearance presence, pivots, positions and displayed rendering. Review pets remain anchored/noncolliding and isolated in Workspace.AK_JunglePetReview. Geometry changes preserve existing part transforms and model pivot.
Inventory previews, follower animation/placement, Sanctuary displays and final weight scaling require testing once durable final assets exist; they are not verified by this material revision. No game implementation scripts changed.
Status: PARTIAL REVISION; STYLE NOT APPROVED; DURABLE ASSET SAVE BLOCKED. Stop for user visual feedback and do not generate additional pets or spend paid credits.
