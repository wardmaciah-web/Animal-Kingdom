# Map, navigation, UI, and performance source audit — 2026-09-17

This document records source inspection and targeted UI repairs. Live map geometry is assessed separately from the actual open Studio snapshot; old `.rbxlx` exports were not treated as current geometry.

## Confirmed defects repaired

1. **Currency HUD showed permanent demo balances.** Coins were always 12,840 and Friendship Tokens 425. The HUD now shows a loading dash until an authoritative ProfileService snapshot, then follows the same server data signals used by biome ownership. No client balance timer or local grants were introduced.
2. **Biome menu prices disagreed with the actual economy.** ExampleData's exponential placeholder formula listed Forest for 600, while ProgressionService charges 2,500. All twelve menu prices now come from AnimalKingdomConfig, the authoritative configuration underlying BiomeDatabase.
3. **Unlock buttons had no mapped server handler.** They sent `AnimalKingdomRemotes.UIRequest`, which no source server script creates or receives. The existing RemoteBridge now routes `UnlockBiome` to the existing Knit ProgressionService. Existing server checks for previous biome, ownership, balance, and request rate remain authoritative.
4. **Biome cards overflowed on small screens.** Three fixed columns yielded roughly 80-pixel cards on narrow mobile widths. The grid now uses one to three columns based on actual available width, maintaining approximately 170-pixel cards when possible. Teleport/unlock button text has a bounded text scale.
5. **Text bounds were inconsistent.** The common text helper could create `MinTextSize=10`, `MaxTextSize=9` for navigation labels. Minimum now respects the requested maximum.
6. **A rapidly reopened window could close itself.** An old delayed close callback still hid a window reopened within 0.14 seconds. Window generations invalidate stale callbacks; previous tweens are canceled.
7. **Responsive layout stopped following a replacement camera.** Viewport listeners now rebind when Workspace.CurrentCamera changes and disconnect on GUI destruction. Window minimum sizes also fit short/narrow viewports.

Files changed: `src/StarterGui/AnimalKingdomUI/Main.client.lua`, `Components.lua`, `ExampleData.lua`, `RemoteBridge.lua`, and `tests/BiomeTeleport.studio.lua`.

## Source-level map observations for live comparison

- `default.project.json`: GrassFloor top is Y=0; all twelve mapped BiomeBlockout.Platform tops are Y=1. These values establish a **source mismatch**, not the intended current live common ground Y. Actual Town, plots, biome floors, and spawn surfaces must determine that value.
- Workspace and top-level source services use `ignoreUnknownInstances`; Town, detailed biome geometry, import models, and possibly Workspace.Script are live-only. Do not replace the live place with a bare Rojo build.
- WorldService, if enabled in the live place, generates fourteen biome props and five shakeable spheres per mapped biome, plus a Meadow SpawnLocation. This can coexist with a detailed live map and must be compared against the live runtime before any removal.
- WorldService's existing CreateSanctuary creates seventy display spots per player near the central map at Y=0.15. Its slot counter grows on each join and never reuses slots. This is pre-existing pet scaffold; no pet systems were added or rebuilt in this audit.
- NumNomService's existing sphere spawns use mapped Platform centers or old generated-world coordinates, not live top-level biome floors. It should be assessed with future gameplay scaffold activation state.
- BuildTree's generated Cylinder trunk uses size `(2.2,8,2.2)` then rotates Z 90 degrees; Roblox Cylinder length is along local X. This is a generated fallback geometry defect if that branch is active. Detailed live trees must not be blindly modified on that basis.
- AK_BiomeLabelRemover intentionally removes biome signs under BiomeBlockout/BiomeEnvironments and explicitly protects the full WeatherAdminRoom. This expresses a prior deliberate label decision; it was preserved.
- AK_TownVisualRuntime creates only 23 anchored noncollidable/nonqueryable visual overlays and validates bounds before replacing its runtime folder. It depends on live-only Town targets and ServerStorage imports; a source-only place lacks those targets. It is not the historical Workspace.Script.

## Biome teleport source audit

- RequestHandler permits only one string destination from the explicit twelve-name registry, rejects extra arguments, requires a loaded profile and `UnlockedBiomes[id] == true`, applies a 0.75-second per-player cooldown, and releases player request state on leave.
- Landing requires the actual collidable named region floor, clear character bounding volume, corner support, a living unanchored character, and no occupied seat. It preserves root/pivot offset and clears velocity.
- Markers are anchored, invisible, noncollidable, nontouchable, nonqueryable, and duplicate-safe. Startup retries are bounded to twelve attempts at five-second intervals.
- Floor search resolves top-level biome IDs first, then World.BiomeBlockout or World.Biomes. Compare those actual names and marker locations to the new live snapshot before changing them.
- The floor-check ray starts 150 studs above the floor and uses default RaycastParams.RespectCanCollide=false. Invisible/queryable decoration directly overhead can reject a safe landing. No generic collision change was made without actual evidence.

## Error and performance evidence

- The known `Only positive non-zero scale values are allowed` error is real in historical Studio output. It repeatedly names `Workspace.Script`, line 82, including the 2026-09-17 04:18Z log. That script has no corresponding mapped source. Read its current live Source and enabled state before diagnosing or fixing it.
- The freshly opened 2026-09-17 21:36Z Studio log had no scale-error occurrence at inspection time; that alone does not establish a successful play test.
- Latest log includes Roblox ControlsEmulator plugin errors, localhost Superbullet connection failures, and image resolution failures for font JSON asset paths. Those are not evidence of gameplay script faults.
- No mapped client script outside the weather/admin components scans all Workspace descendants every frame. Main UI uses event-driven layout; legacy AnimalKingdomController's optional fallback polls only its own data every 0.5 seconds and is bypassed when the production StarterGui exists.
- AK_BiomeLabelRemover performs a bounded set of startup scans and uses DescendantAdded afterward. Town overlay processing is startup-only. NumNom loops run every five seconds. No broad premature redesign was performed.

## Future phase limitations, not features added

- Pet index, merge, and trade panes contain pre-existing sample pet records and sample player names. No real pet/trade UI integration was fabricated: **FUTURE PET PHASE**.
- The decoration pane contains pre-existing sample catalog records and placement controls without a mapped handler: **FUTURE 3D ASSET PHASE**.
- Existing settings and redeem controls also use UIRequest without a mapped handler. They need actual feature wiring; they are warnings, not a claim that UI is fully functional.
- Currency-based progression ultimately depends on the future pet/income phase; this audit does not grant currency or unlock paid biomes to bypass that dependency.

## Verification performed

- Native Luau compiler passed all four modified UI sources and the extended BiomeTeleport Studio regression file.
- Extracted actual Main.client ownership/currency callbacks and existing Studio test harness executed in the native Luau VM: all twelve biome buttons, full ownership snapshot, per-biome updates, whole-table ownership replacement, currency snapshot, and currency update assertions passed.
- Extended Studio test additionally checks all twelve displayed biome prices against authoritative configuration. Full Roblox geometry/GUI rendering tests still belong to the root live verification pass.
- No Studio UI commands or map mutations were performed by this source-audit subtask.

## Actual live snapshot follow-up

The root agent acquired `live-before.json` from the open place, placeId 132313449035787, and saved an `.rbxl` recovery copy. The following are actual snapshot observations, not old-file assumptions:

- 4,447 Workspace BaseParts, 3,130 MeshParts, 2,495 model records. No SpawnLocations existed in edit mode; plot/admin runtime setup supplies spawning.
- Concrete support top is **7.8289308548**. Four plot bottoms exactly match that support, and their playable tops are **8.8289308548**. Meadow/Jungle/Snow biome bottoms also match the same support; their 1.3-stud slabs have tops approximately **9.1289308548**. This supports a common biome playable surface of **9.1289308548**, while retaining the shared lower support level. Do not confuse the two reference levels.
- Top-level `TownPlaza` surface is 8.4752395749; its central raised `CentralPlaza` is 9.0952325426. Town is predominantly top-level live objects, not contained by the almost-empty `AnimalKingdomTown` model.
- Sky surface is only 10.8500008, about 1.72 studs above the grounded biome benchmark. It has no high-altitude base or travel infrastructure in source; this is a base offset, not evidence of an intentional elevated island. Internal cloud/rock elevation must remain intact.
- Floor tops before correction: Meadow 9.12893057; Forest 10.12895536; Jungle 9.12894678; Desert 10.12892574; Snow 9.12893724; Volcano 10.54999965; Ocean 10.54999971; AncientRuins 11.54999971; MagicalForest 10.53673881; Sky 10.85000080; Prehistoric 9.61473590; Mythical 10.29999971.
- 102 parts were unanchored: 66 in the wholly underground `home` staging model, 24 character parts, seven AltarRuins parts, one Sky rock, one Pedestal, two loose Parts, and one Union. Character parts are an intentional exception.
- 38 invisible collidable tree RootPart helpers exist, several 13–22 studs wide, in top-level MagicalForest trees and `AK_MagicalForest_RestoredTrees`. Those are distinct from the character HumanoidRootPart. They can cause invisible navigation barriers; disabling helper collision is appropriate while preserving real trunk collision.
- Two AncientRuins StylizedTree root models have identical bounds and positions: center (-729.45355,44.16553,382.03613), size (57.15964,65.23104,42.12234). Other duplicate root names have different transforms and must not be mistaken for coincident duplicates.
- Several roots/logs sit around Y=104 outside the biome named in their metadata, and several tiny imported source copies are underground. They must be visually/raycast verified and archived as staging if confirmed, rather than blindly grounded into the wrong biome. The root audit received exact candidate names and positions.
- The eight saved Town visual models are all noncollidable/nonqueryable overlays (33 MeshParts total); their intended canonical targets are absent/empty. Do not rebuild those visual models. Assess building collisions separately from the underlying Town/Concrete floors.

## Additional confirmed runtime fixes

Three live-only cleanup scripts delete BiomeBlockout, generated gameplay, or the entire World folder. The last removes World immediately and whenever recreated. Combined with the unchanged source WorldService fallback, startup ordering could regenerate obsolete platforms, trees, pet display pads, and sphere collectibles before the cleanup deleted them again.

- WorldService now detects actual authored `Workspace.<Biome>.<Biome>Floor` instances first, retains `World.Runtime`, and skips replacement world generation.
- Rojo fallback geometry remains in edit data for a portable source build, but becomes invisible/noncollidable/nonqueryable/nontouchable with disabled prompts/spawns when an authored map exists. It is not blindly deleted.
- Legacy generated sanctuary display pads and NumNom sphere spawns are suppressed for the authored map. They require explicit development attribute `AK_EnableLegacyGameplayScaffold=true`; default is off.
- The root agent owns archiving the three live cleanup scripts so they cannot delete the retained runtime container. The live WalkSpeed=35 script is unrelated and preserved.
- Exact cause of Workspace.Script line 82 is confirmed: the legacy GeneralStore script divides by source bounds and calls ScaleTo with zero because its saved canonical GeneralStore target has zero bounds. Existing saved `AK_RUNTIME_GeneralStoreVisual` is intact. A second live-only script `ServerScriptService.AK_RuntimeTownVisuals` duplicates overlay construction and has the same invalid-target risk.
- The mapped AK_TownVisualRuntime now skips missing/empty canonical models per asset, uses a 15-second maximum import wait, and preserves existing visuals when no valid overlay targets remain. Bounds/role validation remains in place for valid targets. The root agent owns archiving both obsolete live overlay scripts.

`tests/AuthoredWorld.spec.lua` passed in the native Luau VM using the actual WorldService and NumNomService source. It verifies authored floors are unchanged, old mapped fallback remains stored but cannot interfere with the live map, runtime container exists, prototype loops/scaffold do not start, and a source-only place still uses its portable mapped fallback.
