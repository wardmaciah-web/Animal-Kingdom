# Animal Kingdom — Garden visual redesign
Completed in the current **Animal Kingdom[TESTING}** Studio place, place ID **132313449035787**. Saved locally; not published.

## Plot count and scale
- **4 active player plots** detected: `Workspace.PlayerPlots.Plot1Floor` through `Plot4Floor`. Confirmed by the existing PlotLocator during play.
- **4 physical Garden plots** now present: retained and enlarged GardenPlot1–3, added GardenPlot4.
- Soil beds enlarged from **13 × 10** to **30 × 24 studs** each.
- Garden footprint enlarged from **130 × 130** to approximately **224 × 216 studs**, with rounded corners and a layered stone foundation.
- Two orderly rows of two plots, broad front aprons, side aisles, and consistent numbered signs.

## Layout and finish
A cedar entry arbor leads along a limestone main path to a central oak court with planters and benches. Paths connect every plot, the rear shop/preview area, the return portal, a vegetable parterre, and a complete pond loop. The supplied arched bridge crosses the pond and meets a landing at each end.

Added tilled soil, timber bed edging, limestone corner caps, low flower borders, restrained lantern lighting, short wooden fence runs, shrubs, and varied perimeter trees. Existing shop and preview objects remain in the Garden. Decorative meshes are noncolliding; walking surfaces and bridge planks are anchored and collidable.

## Assets used
| Inventory asset | ID | Use |
| --- | --- | --- |
| Vegetable Garden | 93660859808046 | Scaled kitchen-garden beds and decorative vegetables |
| Koi Pond Bridge | 574502744 | Walkable crossing over the pond |
| Pond, by RobotGeometry | 215879929 | Basic pond feature; named `Basic Pond` in the Garden |
| Wood Wooden Fence | 10348034923 | Short perimeter and landscaping fence sections |

The supplied models were found in the user's inventory, rather than as placed objects under their requested names. The pond was listed as **Pond**, not **Basic Pond**. No model with the exact latter title was found. The imported copies contained **no scripts**.

Existing in-place trees reused:
- `Tree_Oak_1_V5_030`
- `Tree_Oak_5_V5_011`
- `Tree_Oak_7_V5_001`
- `CommonTree_5_V5_040`
- `Willow_2_V5_006`
- `Willow_5_V5_035`

Other existing assets reused: `Forest_Decor_plant_bushDetailed_51`, `MagicalForest_Decor_Flower_Violet_2_35`, `Flower_Daisy_3_V5_009`, and `LampR2`. Decorative tree copies have resource tags, interaction attributes, and prompts removed so they do not become harvestable resources.

## Compatibility and backup
- **All 207 existing script sources compared unchanged** before and after the build/playtest.
- No reward formulas, remotes, profiles, saves, pet systems, UI scripts, teleport scripts, admin scripts, or weather scripts edited.
- Original GardenPlot1–3 instances retained, including SoilBase, PetPad, PlotSign, six CropAnchors each, and SlotId/PlotIndex attributes.
- GardenArrival, GardenReturnFallback, ReturnPortal, and ReturnPrompt retained. Their positions were adjusted to the new paths.
- Main functional destinations stay inside the existing 90-stud Garden proximity check.
- Before-state clone and removed visual dressing retained in `ServerStorage.GardenVisualRedesign_Backup_20260922`.
- Source assets retained in `ServerStorage.GardenVisualAssets_20260922`.
- Finished Garden: **1,235 anchored BaseParts, zero runtime scripts**. The assets are static; lantern lights do not cast shadows.

## Studio verification
- Garden visit succeeded through the existing VisitGarden request.
- All four physical plots loaded on the client.
- **22 walking segments passed**, covering plot fronts, side aisles, courtyard, kitchen garden, and pond loop. Most routes tested at the standard 16-stud walk speed.
- Bridge crossed without jumping or falling; character health remained 100.
- Original return ProximityPrompt activated with **E** and returned the player to the Kingdom.
- Server inspection found no unanchored Garden parts, resource tags, or server errors.
- Studio returned to edit mode. Temporary preview geometry was removed.

## Remaining scope
The current backend and client still support **three active expeditions**. GardenPlot4 is a matching physical plot prepared for future systems work; it does not add an expedition slot, ownership behavior, or a new status UI. This limitation was intentionally preserved for the visual-only task.

## Deliverables
- [Local Studio place](AnimalKingdom-Garden-Visual-Redesign-20260922.rbxl)
- [Overview](garden-overview.png)
- [Plot view](garden-plots.png)
- [Pond view](garden-pond.png)
- [Walking test evidence](playtest.json)
- [Before-state inspection](inspection.json)
- Edit-time build and polish commands: `BuildGardenVisuals.lua`, `PolishGardenVisuals.lua`.
