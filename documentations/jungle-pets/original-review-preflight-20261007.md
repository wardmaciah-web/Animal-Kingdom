# Jungle original pet review — pre-generation audit

Status: Awaiting explicit paid-generation approval. No new pet models generated; no new asset IDs. Paid calls made: 0.

## Verified source
Live Roblox Studio Edit DataModel: place 132313449035787, universe 10764288431.
Inspected PetDefinitions, ForestPetDefinitions, ImportedPetDefinitions, legacy PetDatabase, all MeadowPetTemplates and PetAssets children, both duplicate Assets.Pets folders, and other PetTypeId/CanonicalPet-tagged models.
ImportedPetDefinitions is empty. Anonymous biome/rarity legacy entries do not identify animal species.
Existing original templates were not edited.

## Species exclusion list
Mouse; chicken/chick; rabbit (including retired Honey Lop and all fantasy bunny variants); squirrel; goat; deer (fawn, buck, prism antler, and conservatively Leaf-Antler Guardian); fox; sheep/lamb; dog (legacy); raccoon; black bear; skunk; badger; tree frog; river otter; bat; owl (woodland and crested).
Emerald-Wing Guardian is also excluded as an existing creature identity; its exact zoological species is not established by its registry name.
No tapir or toucan appears in the inspected registry or imported pet roots.

## Animal Kingdom pet style guide
Observed from actual textured Studio mesh renders, including front, side, back and three-quarter captures:
- Rounded oversized heads and compact seated bodies; visually estimated head height around 45–55% of total, varying by species. This is an art target, not a measured submesh ratio.
- Very large glossy near-black eyes, bright catchlights, warm expressive eyelid/cheek framing, small noses and soft smiles.
- Short substantial limbs; readable toe/paw-pad detail and small species-specific ears.
- Sculpted layered fur clumps and feather rows with textured directional detail; smooth faces and eyes provide contrast.
- Painted natural color variation, cream muzzles/bellies and clearly readable markings. Fantasy variants retain the same anatomy/material finish.
- Smooth detailed mesh silhouettes rather than primitive block construction. Meadow uses SurfaceAppearance/PBR alongside texture bindings; inspected Forest templates use TextureID.
- Reference templates are roughly one stud at import. Shared PetVisualGeometry.Normalize establishes a 2.8-stud maximum authored reference dimension, then PetWeight applies absolute kilograms. Species must not be resized independently in owned-pet contexts.

## Original designs (not generated)
1. Jungle Rainstripe Tapir — original baby tapir. Broad pear-shaped seated torso, short flexible proboscis, tiny oval white-edged ears, squat four-toed front feet, tiny tail, cocoa fur and cream broken juvenile stripes/spots. Gentle raised brows and oval glossy eyes. No deer ears, antlers, fox tail, raccoon mask or bear muzzle.
2. Jungle Canopy Toucan — original keel-billed toucan. Upright egg-shaped torso, rounded cheek planes, oversized curved keel-shaped beak in lime/coral/amber with restrained dark tip, charcoal-blue layered plumage, creamy yellow throat, tucked scalloped wings, short broad tail and rounded three-toed feet. Curious eye shape and slight head tilt. No owl facial disc, owl ears or guardian ornamentation.

Both need newly generated geometry and textures. Existing references are style evidence only; no source mesh copying, recoloring or animal anatomy transfer.

## Bounded generation plan
Two ForgeGUI generation_model_3d calls, quality high, game_style roblox, one per new species.
Cost unknown: live tool schema provides no credit estimate.
No paid concept images, remeshes, rigging, animation or retries authorized.
ForgeGUI publishing preflight succeeded: active Personal destination @Maciahxcx1 supports Model, Image, Audio. Integrated Roblox Model delivery is available.
Before submission, establish the image reference handoff if supported; existing Roblox mesh IDs cannot be passed as ForgeGUI image references. Do not claim the provider consumed Studio captures unless an owned image upload is verified.
Submit one model first, inspect its mesh and textures in Studio, then proceed with the second only if consistent.

## Studio preparation and evidence
Workspace.AK_JunglePetReview created with ReviewOnly=true, Status=AwaitingPaidGenerationApproval.
StyleReferencesOnly contains eight explicitly named reference copies: Field Mouse, Fawn, Cloudtail Fox, Black Bear Cub, Raccoon, River Otter, Woodland Owl, Tree Frog.
Only comparison copies were normalized and moved to an isolated review area near Y=1000. No active pet definitions or reward pools changed. No Jungle unlock.
MCP captures inspected in this session: JungleStyle_ThreeQuarter, JungleStyle_Front (back-facing view), JungleStyle_Close, JungleStyle_Side, JungleStyle_ActualFront. These are reference captures, not evidence of generated Jungle pets. Capture images were returned in chat; durable screenshot files are not yet recorded.

## Required verification after generation
- Distinct mesh and texture IDs from all existing pets; inspect actual topology/triangle counts from artifact where accessible rather than inferring from an ID.
- Textures loaded, no missing faces or broken UVs; inspect front, side, three-quarter views beside references.
- Script-free templates, non-colliding anchored presentation parts, valid visible bounds and coherent pivot/orientation.
- Normalize via the shared 2.8-stud reference; test weight scaling through maximum 70kg on review copies.
- Exercise the actual inventory viewport, follower and Sanctuary presentation code using isolated review definitions/adapters; do not register prototypes in reward pools to enable testing.
- Save source meshes/textures, durable Roblox Model/mesh/texture IDs and review-only install instructions.
- Stop with exactly two review pets for user visual approval. Do not generate the remaining Jungle roster.

## Repository state
Local C:/Users/Kenny/Documents/Real_Animal_K has an invalid/broken current Git branch and all visible project content is untracked. Do not stage unrelated files or repair history blindly.
This audit is committed through the authenticated GitHub connector to wardmaciah-web/Animal-Kingdom. No game code or existing pet asset changes are included.
