# Animal Kingdom systems cleanup — 2026-09-26

Phases 1–6 were implemented in the existing source and selectively synchronized into the connected Animal Kingdom testing Studio session. Phase 7 was stopped before any transform because the proposed bounds overlap a protected plot reservation. Nothing was published. Studio tests used the existing `StudioMockSnapshot` profile mode; production datastore writes were not used for testing.

## Phase 1 — authoritative pet safety and collection

- SELL ALL uses canonical ownership and only eligible Inventory records. Locked, Favorite, Secret, Prismatic, definition-protected, Held, active Held, Sanctuary, Garden and active-trip records survive. No eligible records produces useful feedback without mutation. Currency-cap overflow rejects the sale. Removal and the existing balance credit commit synchronously under the pet transaction lock; existing request receipts reject replay effects.
- Lock/Unlock uses `Pets[].Locked` and `PetService:Flag`, validates the UID, publishes the changed record and requests a checkpoint through the existing profile.
- STORE accepts Held records only, preserves the record and stats, clears the active UID when appropriate, frees the slot and rebuilds compatibility indexes. Garden return capacity remains reserved.
- Sanctuary pickup validates the actual own slot, expected UID, distance and empty active hand; accrues income before moving the same record into the first free Held slot. Five occupied Held slots reject without mutation.
- Each existing plot gets a runtime `IncomeCollector`. Character touches validate ownership, alive state, distance, debounce and the serialized existing `PlotService:Collect` operation. Fractional and cap-limited remainders stay in `UncollectedSanctuaryCoins`.
- The collector displays only whole coins that fit in the wallet. READY/EMPTY, capacity feedback and successful `+amount`/sound use authoritative results. Both accumulator and currency changes refresh it. The temporary Plot screen's missing accumulator refresh was fixed before its route was retired.

Changed in this phase: `PetService.lua`, `SellValueCalculator.lua`, `PlotService.lua`, `SanctuaryService.lua`, new `PlotCollector.lua`, `GameplayRequestPolicy.lua`, `SanctuaryInteraction.client.lua`, `Main.client.lua`, `PetOwnershipMenus.lua`, `OwnedPetCards.lua`. Exact full paths are below and in `changed-files.json`.

Verification: 41 assertions in `Phase1.server.lua` passed. Separate actual UIRequest replay verification also passed. This covers protections, exact sale payout, repeated sale, locks, STORE, Garden eligibility, pickup/full-slot rejection, place/swap, owner/non-owner collector guards, touch debounce, cap/fraction preservation and unique UIDs. The later integrated test exercised real character Touched events rather than only calling the guard.

## Phase 2 — Pets and existing Held slots

Pets displays ALL PETS, SELL ALL and exactly HIGHEST/LOWEST sorting by the existing `CoinsPerSecond`. Location, rarity and favorite/lock cycling filters and the old six-way sort are removed. Pagination remains for large ownership lists.

Cards use real previews, species, rarity, weight, coins/sec, lock state and concise location. Inventory click holds the exact pet in the first free Held slot; Held click selects it; STORE is available for Held pets. Sanctuary/Garden cards do not send invalid Equip requests. Lock/Unlock remains available.

The existing five-slot HUD is approximately 540×96 on desktop, with responsive compact behavior and usable action sizes. Empty slots do nothing. One active pet renders overhead with the existing weight-based scale and labels. No new saved Size field or second hotbar was added.

Reveal actions are truthful: HOLD PET selects an existing Held reward; OPEN PETS opens the inventory for overflow. Tree reward commitment, first-free-Held assignment and Inventory overflow remain the existing pipeline. Receiving a pet fills a slot; selecting it makes it active.

Verification: desktop control clicks, exact-UID overhead rendering, server state after LOCK/STORE/Inventory-card actions, sort toggling, desktop dimensions and portrait/landscape layout inspection passed.

## Phase 3 — physical Sanctuary and Plot replacement

Physical slot prompts support EMPTY+HELD → PLACE, OCCUPIED+HELD → SWAP, OCCUPIED+NO ACTIVE HELD → PICK UP. Empty/no-held slots offer no action. Actual E interactions for all three actions passed. Opening a menu suppresses the prompt and E interaction.

Physical capacity comes from resolved real slots: 64 in the current display. The 70-entry compatibility array remains readable. `PetLocations.ReconcileSanctuary` repairs inaccessible assignments only after actual slots resolve: use a real free slot, otherwise return the same record to Inventory. The repair is idempotent, journals previous assignments in `RecoveryData.SanctuarySlotRepairs`, preserves stats and raises existing storage capacity only if necessary to retain returned pets. Empty/unresolved slot maps do not migrate pets.

Plot functions now have homes:

- Income: physical collector, same accumulator and collection service.
- Decoration Capacity: main Upgrades, using `PlotProgression.Level`, existing prices and 25+5-per-level placement limit.
- Decorations: Shop → My Decorations, using existing `Items`, placements and `PlacementService`. Placing/removing does not consume permanent owned copies.
- Travel: Biomes → Your Sanctuary, existing authoritative plot teleport.
- Unenforced visitor preference: hidden from normal UI; saved field retained.

Plot navigation was removed after these replacements were tested. No saved PlotProgression fields were deleted. No Sanctuary management menu was restored.

Verification: actual UI purchase/place/remove and Decoration Capacity purchase passed. Migration tests cover full physical capacity, free-slot repair, exact stats, recovery journal, no repair before slots resolve and idempotence.

## Phase 4 — Index and Biomes

Index remains a species collection guide: biome sections, discovered count, real previews/silhouettes, rarity, discovered variants, milestone rewards, definition base income and actual reward source/tier. It does not display instance Weight. Compact layout keeps the discovered count visible.

`IndexCatalog.Current()` defines one shared eligibility rule for UI and the existing server Index claim service: a currently non-retired reward pool must have valid non-legacy/non-retired definitions and real resolvable models for its entries; positive-weight species in those complete pools count. There are currently 25 eligible species. Unavailable future species do not block milestones. Historical discoveries and existing claims are retained.

Biomes is progression and travel, with predecessor/cost validation, locked/unlocked state, YOU ARE HERE, Garden and Your Sanctuary destinations. The separate Teleport screen/utility is retired. Successful biome travel clears the existing Garden return/session state; failed travel does not falsely clear it.

Verification: all currently eligible species reach 100%; historical-only discovery does not inflate completion; each 25/50/75/100 reward claims once in mock data. Garden → Meadow travel clears `InGarden` and updates `CurrentBiome`.

## Phase 5 — Garden, Upgrades, Settings, Shop

Garden's main tabs are EXPEDITIONS / CROPS / SHOP. Shop keeps Upgrades / Supplies / Cosmetics. Active boosts are compact status information. Existing three forage slots, durations, countdowns, Claim, Recall, Claim All, Harvest, crops, currencies, offline math and travel remain. The picker prioritizes actual eligible Inventory pets: unlocked, real model and not already on a trip. Held/Sanctuary pets are not moved automatically. Claim All enables when trips finish without requiring the screen to reopen.

Main Upgrade descriptions now explain actual scope. Existing purchases and prices remain authoritative. Decoration Capacity is reachable here. Retired EquippedSlots purchase history stays saved and hidden. Client hatch presentation uses the authoritative result Duration; Reduced Motion keeps its reduced presentation, and server cooldown authority remains unchanged.

Settings shows only Reduced Motion and Show Other Players' Held Pets. Legacy settings and AutoDelete history remain saved. Duplicate Profile, Updates and Invite actions are removed from Settings.

Normal Shop remains separate from Garden Shop, exposes real available furniture/decorations and My Decorations, and hides unavailable/seasonal placeholders without fabricating assets.

Verification: existing Garden supply/upgrade/cosmetic purchases and a real 60-second claim passed with the same UID and expected rewards. Two hatch durations produced correspondingly different measured reveal times (~2.198s for 2s, ~0.787s for .8s). Garden portrait content and action sizes were inspected.

## Phase 6 — navigation and legacy cleanup

Primary navigation: PETS / INDEX / GARDEN / BIOMES / CHALLENGES / UPGRADES / SETTINGS. One Shop utility remains, alongside Friends, Updates and Profile. Daily and Weekly remain inside Challenges. Duplicate Plot, Teleport and Daily routes are removed.

After reference searches, `SanctuaryMenus.lua`, root `Components.lua` and `ExampleData.lua` were archived outside the Rojo source tree. The active V2 Components module remains. Old owned-detail/display UI branches, Plot Render and duplicate Teleport rendering were retired. Still-referenced adapters and saved compatibility fields remain.

Verification: all seven primary screens opened. Live focus links were inspected without dead targets. Desktop and iPhone portrait/landscape layouts were checked. Controller B remains bound, but Studio rejected synthetic ButtonB input through CoreGUI; a real controller test was not claimed.

## Phase 7 — scale operation stopped safely

**Applied: no. Exact transformed count: 0.**

Read-only tool: `tools/audit/PlanWorldScale20260926.lua`.

Proposed factor: 0.95, pivot `(-237.352539, 9.128930, 192.420868)`. The dry run records 887 candidate roots, 489 excluded roots, exact ordinal hierarchy selectors/debug IDs, original transforms/scales/sizes, mesh IDs and Vector3 attributes. No protected descendant was found inside the candidate roots. It is a candidate manifest, not authorization to blindly transform those objects later.

The conservative collision check found five new and seven increased bounding-box overlaps with `Workspace.Plot4Reservation` (center approximately `(-379.500061, 9.050000, 703.839966)`, size `130×1×130`, reserved for a future Player Sanctuary). All exact conflicting part paths and before/proposed transforms are in `world-scale-decision.json`; the full manifest is `world-scale-dry-run.json`.

New overlaps include:

- `Workspace.Volcano_Decor_stone_tallF_38.stone_tallF`
- `Workspace.Volcano_Decor_stone_largeD_29.stone_largeD`
- `Workspace.common_tree_dead_3_V5_025.common_tree_dead_3.common_tree_3_trunk`
- `Workspace.common_tree_dead_3_V5_025.common_tree_dead_3.common_tree_3_trunk.001`
- `Workspace.Volcano_Decor_Rock_7_41.Rock_7`

These are conservative bounds conflicts, not a claim of exact mesh-intersection proof. A safe full transform could not be certified, so no partial layout distortion or protected-region change was forced. Garden, Plots, Sanctuary structures/slots, reservations, Town, weather, storage assets, characters and reference/runtime content were excluded. Separately parented Sanctuary stand mesh associations were checked.

Final comparison against the dry-run originals verified 3,339 recorded instances with zero changes. The Studio-only `AK_NewMeadowTreeRuntimeRegister` still exists and was not edited. All 15 new Tripo trees registered live prompts in Play; a tier-1 tree was searched and restored successfully. Since no scale was applied, post-scale twelve-destination landing and seam tests are not claimed.

## Data and verification limits

No new inventory, ownership store, datastore, profile service, currency or income balance was added. Existing UIDs remain the canonical identities; movement changes Location/LocationSlot on the same record. Locked/Favorite, stats, ownership, Garden state, Index history/rewards and Plot data are preserved. No schema version was bumped. The only new persistent recovery detail is additive `RecoveryData.SanctuarySlotRepairs`.

The three saved regression result files contain **105 passing assertions**: 41 Phase 1, 47 integrated player-flow, 17 data/migration/Index/cap checks. The integrated flow includes actual new-Meadow search/reveal commitment, a real 60-second Garden trip, exact-record movement, real collector Touched events, decorations and JSON → existing ProfileMigrations restore of Held/Sanctuary/Garden/decoration/currency state.

Final Rojo build passed at `/tmp/AnimalKingdom-systems-cleanup-final.rbxlx`. It is a source build check, not an imported-asset replacement place. All 25 changed/new source containers passed Studio compile checks and source matching. Three archived modules were removed from the active source and Studio hierarchy.

Limits: no live datastore write/rejoin test; the saved-state test is a mock serialization/migration round trip. No physical controller B or complete touch-device playthrough. Simulator input was unreliable for mobile clicks, so mobile claims are layout inspection. Existing missing future-pet asset warnings and the unavailable local Superbullet backend remain unrelated environment warnings; unavailable species/products are not presented as obtainable purchases/rewards.

The initially failing integrated assertion incorrectly expected a reward to become active before the player selects its Held slot. The test was corrected to the requested receive → click slot flow; backend reward behavior was not changed to satisfy the test. The cap display issue found during final review was fixed and verified. No remaining implementation failure was observed in the executed checks.

## Source file map

Changed/new files (relative to project root):

```text
src/StarterGui/AnimalKingdomUI/Main.client.lua
src/StarterGui/AnimalKingdomUI/PetOwnershipMenus.lua
src/StarterGui/AnimalKingdomUI/PetMenus.lua
src/StarterGui/AnimalKingdomUI/OwnedPetCards.lua
src/StarterGui/AnimalKingdomUI/HeldPetsBar.lua
src/StarterGui/AnimalKingdomUI/HatchPresentation.lua
src/StarterGui/AnimalKingdomUI/GardenMenus.lua
src/StarterGui/AnimalKingdomUI/ProgressionMenus.lua
src/StarterGui/AnimalKingdomUI/PlotMenu.lua
src/StarterGui/AnimalKingdomUI/AnimalKingdomUIV2/HUD.lua
src/StarterPlayer/StarterPlayerScripts/SanctuaryInteraction.client.lua
src/ServerScriptService/ServerSource/Server/PetService.lua
src/ServerScriptService/ServerSource/Server/PlotService.lua
src/ServerScriptService/ServerSource/Server/SanctuaryService.lua
src/ServerScriptService/ServerSource/Server/GardenExpeditionService.lua
src/ServerScriptService/ServerSource/Utilities/PlotCollector.lua
src/ServerScriptService/ServerSource/Utilities/GameplayRequestPolicy.lua
src/ServerScriptService/ServerSource/Utilities/MeadowSanctuaryDisplay.lua
src/ServerScriptService/BiomeTeleport/init.server.lua
src/ServerScriptService/BiomeTeleport/RequestHandler.lua
src/ReplicatedStorage/Shared/Gameplay/PetLocations.lua
src/ReplicatedStorage/Shared/Gameplay/SellValueCalculator.lua
src/ReplicatedStorage/Shared/Gameplay/IndexCatalog.lua
src/ReplicatedStorage/Shared/Gameplay/Definitions/PetDefinitions.lua
src/ReplicatedStorage/Shared/Gameplay/Definitions/GardenDefinitions.lua
```

Archived from active source: `src/StarterGui/AnimalKingdomUI/{SanctuaryMenus.lua,Components.lua,ExampleData.lua}`. Copies remain under `retired-ui/` here and in the original source backup.

## Handoff and rollback

- `before/src/` and `before/default.project.json` preserve the original source/config; `baseline-sha256.json` records the baseline. `source-changes.diff` and `changed-files.json` describe the complete patch.
- The existing Rojo serve process (PID 19077) was paused to prevent a blanket reconciliation from touching Studio-only imported content. Source was synchronized by exact source-container edits with baseline checks. Automatic Rojo sync remains paused. The Rojo config was not changed.
- No save-over of imported Studio assets or place publish was performed. The connected Studio contains the tested source changes; source files are saved on disk. Play tests and temporary QA scripts are not part of the shipped source tree.
- To roll back this cleanup, restore only the listed changed/archived source files from `before/`, remove the two new modules (`IndexCatalog.lua`, `PlotCollector.lua`), and selectively restore those exact source containers. Keep current profile data and additive recovery history. Do not use the source-only build to overwrite the authored place or blindly reconnect the existing world mapping.
- World rollback is unnecessary: no transform occurred. Any later scale attempt must rebuild/revalidate exact instance references and resolve the protected reservation conflicts before mutation; ordinal paths/debug IDs are snapshot identifiers, not permanent IDs across reimports.
