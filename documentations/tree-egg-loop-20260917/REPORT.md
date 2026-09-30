# Animal Kingdom — corrected tree → egg → pet loop

The existing map trees now produce a free immediate biome-egg hatch. The generated world-tree and ground-egg flow is retired. Pet ownership, inventory, following, saving, rarities, Index, economy, biome progression, challenges, weather, upgrades, plots and admin services remain integrated.

## 1. Generated trees removed

Removed the generation/replacement code from WorldContentService. Startup and edit-place cleanup remove only objects stamped by the previous generator with `GameplayGenerated = true` and `AssetCategory = Trees`, `Resources`, or `Eggs`. No original map tree is deleted or replaced. The inspected edit place contained zero generated instances; live testing confirmed zero generated gameplay geometry.

## 2. Generated ground eggs removed

No world egg stands, egg pickups, purchase prompts or platforms are spawned. Legacy EggStation tags and EggPrompt interactions are retired. The old Hatch remote action is rejected, and its compatibility server method cannot award pets. Egg definitions, models and RNG remain available for hatch presentation.

## 3. Existing biome tree paths discovered

Inspected the current authored Workspace in place `132313449035787` before changing the flow. [Complete inventory of all 322 registered paths, roots and pivots](TREE-INVENTORY.md); [machine-readable registration](registered-trees.json); [raw current-place inspection](current-tree-discovery.json).

The paths include `Workspace.BiomeEnvironments.MeadowEnvironment.Scenery.Trees`, `Workspace.AK_AncientRuins_RandomizedTrees`, `Workspace.AK_MagicalForest_RestoredTrees`, direct Workspace tree models, and two MeshParts under `Workspace.Volcano island lowpoly`. These were inspected, not inferred from the Rojo blockout.

## 4. Usable real trees per biome

| Biome | Trees | Example existing instance |
|---|---:|---|
| Meadow | 28 | `Workspace.BiomeEnvironments.MeadowEnvironment.Scenery.Trees.Tree_Oak_4_V5_005` |
| Forest | 29 | `Workspace.Willow_5_V5_034` |
| Jungle | 35 | `Workspace.CommonTree_5_V5_041` |
| Desert | 19 | `Workspace.CactusFlowers_2_V5_015` |
| Snow | 31 | `Workspace.pine_tree_1_snow_V5_012` |
| Volcano | 26 | `Workspace.CommonTree_Dead_5_V5_001` |
| Ocean | 27 | `Workspace.Tree_Palm_1_V5_002` |
| AncientRuins | 22 | `Workspace.AK_AncientRuins_RandomizedTrees.AncientRuinsTree_02_Type1` |
| MagicalForest | 55 | `Workspace.AK_MagicalForest_RestoredTrees.MagicalForestTree_006_AK_LowpolyWillow` |
| Sky | 19 | `Workspace.Tree_Pine_6_V5_015` |
| Prehistoric | 27 | `Workspace.Willow_3_V5_038` |
| Mythical | 4 | `Workspace.Tree3_V5_024` |

Total: **322 instances: 320 Models and 2 MeshParts**. Desert uses its existing cactus tree assets. Flowers, bushes, roots, rocks, embedded scenery and objects outside the actual biome floors are excluded. The four real Mythical tree assets are usable; its large decorative flowers are not turned into trees.

## 5. Registration

AuthoredTreeDiscovery scans once at startup. It recognizes audited asset identities and specific inspected tree families, rejects nested duplicates/unanchored geometry, and resolves biome identity against actual biome floors. WorldContentService adds GatherableTree plus AuthoredGatherableTree, BiomeId, ResourceType, RespawnTime and a reachable InteractionPosition. Registration also ran automatically in the edit place. No manual tagging is required.

## 6. Tree shake

A small SHAKE TREE ProximityPrompt sits on an Attachment at reachable trunk height, including trees whose primary mesh is a canopy. The actual existing Model/MeshPart rocks for 1.2 seconds through PivotTo. One shared Heartbeat updates active shakes only. Original pivots and every part CFrame are restored to prevent imported-pivot rounding drift. Optional local leaf flecks are bounded and self-cleaning.

## 7. Tree locking

The server checks registered target, living player, proximity, biome, inventory space and cooldown, then claims AVAILABLE → SHAKING without yielding. A per-player in-flight guard prevents simultaneous claims on several trees. A server-only claim token binds one player to one tree. Replayed/wrong-owner claims cannot award another pet. Different players on different trees proceed independently.

## 8. Biome → egg mapping

`BiomeDefinitions[biomeId].EggId` is the single routing source: MeadowEgg, ForestEgg, JungleEgg, DesertEgg, SnowEgg, VolcanoEgg, OceanEgg, AncientRuinsEgg, MagicalForestEgg, SkyEgg, PrehistoricEgg and MythicalEgg. The registered tree determines the biome; the client supplies neither EggId nor PetId.

## 9. Immediate hatch

ResourceService calls EggService:HatchFromTree with the claimed tree. Capacity/access/range are checked again at commit. One pet is rolled, assigned a UID and committed to the existing profile; then the tree is hidden and the client receives its hatch result. No egg inventory, payment, world pickup or shop is involved. The server commits before the cosmetic reveal so death/disconnection cannot undo or duplicate a result. Full inventory, including inventory that fills during the shake, restores the tree without a cooldown and displays PET INVENTORY FULL.

## 10. Server RNG

Existing LootService/WeightedRandom and ModifierService choose the pet and variants from EggDefinitions. RNG and rewards stay server-owned. The normal interaction produces one hatch. Legacy egg prices/triple-capable definitions remain data for future features but are unused by this loop. Removing the Meadow Collection stand does not strand its Index pets: MeadowEgg retains 80% combined weight for its introductory pets and shares 20% among the legacy Meadow collection.

## 11. Placeholder pets / egg presentation

The existing AssetResolver/PetAppearance pipeline uses `ReplicatedStorage.Assets.Eggs.<EggId>` in the hatch viewport and `ReplicatedStorage.Assets.Pets.<PetId>` for the revealed pet. Missing models use existing placeholders; imported models need no gameplay rewrite. The sequence wiggles increasingly, flashes, reveals the named/rarity-colored pet and queues subsequent presentations. Inventory/equipping/following/XP/saving use the existing PetService.

## 12. Hiding

The entire same tree instance is hidden. Saved BasePart CFrames, transparency, collision, touch and query flags are retained; decals/textures and enabled states for prompts, emitters, beams, trails, labels, lights and other supported effects are restored. Emitters/trails are cleared when hidden so old particles do not linger. No replacement clone is created.

## 13. Exact 20-second respawn

After hiding, the server sets RESPAWNING and schedules `task.delay(20, ...)`. The deadline is also exposed as RespawnAt. Restoration reuses the same instance and restores its exact saved transforms/properties before setting AVAILABLE. The scheduler executes on the first available frame at/after the 20-second deadline; it cannot return early and does not depend on client FPS. Departure after award does not stop the tree timer.

## 14. Challenges

A successful tree hatch fires the existing Harvested event once and Hatched event once. They drive the saved Gather/tree-shake and Hatch/egg-hatch challenges. Failed, full, cancelled and replayed attempts do not increment either. Existing secondary coin/token rewards remain, preserving earn-currency challenges and progression.

## 15. Pet Index

The existing Discover and Granted flow records identity and variants once. Configured auto-delete still records discovery and retains existing protections. All **304 defined Index pets** remain obtainable through the twelve primary biome eggs; automated coverage verifies this.

## 16. Weather / luck / SFX

Tree hatching queries the existing ModifierService for rarity weights, luck, mutation, Shiny and hatch speed. Existing weather-specific secondary drops and resource multipliers remain. No weather state or formula was duplicated. Live Rainbow luck integration passed.

Five optional sound slots are explicitly empty: TreeRustle, TreeShake, EggWiggle, EggCrack and PetReveal in GameplayEffectsDefinitions. They remain silent until real approved recordings are supplied; no SoundIds were invented. The visual hatch and bounded leaf effects function without them.

## 17. Files created

- `src/ReplicatedStorage/Shared/Gameplay/Definitions/AuthoredTreeDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/GameplayEffectsDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/PresentationSounds.lua`
- `src/ServerScriptService/ServerSource/Utilities/AuthoredTreeDiscovery.lua`
- `src/StarterPlayer/StarterPlayerScripts/TreePresentation.client.lua`

- `tests/TreeEggLoop.studio.server.lua`
- `tests/TreeEggLoop.studio.client.lua`
- `tests/TreeShakeMotion.studio.server.lua`
- `tools/gameplay/InspectAuthoredTrees.studio.lua`
- `tools/gameplay/prepare_tree_loop_install.py`
- `tools/gameplay/prepare_tree_loop_test.py`

Evidence, source snapshots and saved build artifacts are under `documentations/tree-egg-loop-20260917/`; files-manifest.json enumerates them.

## 18. Files modified

- `src/ReplicatedStorage/Shared/Gameplay/Definitions/BiomeDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/EggDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/TutorialDefinitions.lua`
- `src/ServerScriptService/ServerSource/Server/EggService.lua`
- `src/ServerScriptService/ServerSource/Server/GameplayService.lua`
- `src/ServerScriptService/ServerSource/Server/ResourceService.lua`
- `src/ServerScriptService/ServerSource/Server/WorldContentService.lua`
- `src/ServerScriptService/ServerSource/Utilities/GameplayRequestPolicy.lua`
- `src/StarterGui/AnimalKingdomUI/HatchPresentation.lua`
- `src/StarterGui/AnimalKingdomUI/Main.client.lua`
- `tests/Gameplay.spec.lua`
- `tools/gameplay/prepare_live_tests.py` — forwards to the current tree-loop test.
- `documentations/gameplay-20-systems-20260917/REPORT.md` — marks the old ground-egg flow as superseded.

PetService, PetFollowing, ProfileService/profile schema, EconomyService, BiomeService, ChallengeService, WeatherGameplayService, admin/weather/plot sources and default.project.json were preserved.

## 19. Rojo build

**PASS.** Rojo builds succeeded after each correction phase; all **129 first-party Luau files compile**. Automated gameplay suite: **918 assertions, zero failures**. Existing admin/security and profile-lifecycle suites pass.

## 20. Sourcemap

**PASS.** The source hierarchy/service audit resolves **188 literal requires**, with no missing service or static require cycle. Rojo's mapped build is a source artifact; the complete authored map is saved separately.

## 21. Exact live Studio test checklist

1. Join with zero Coins and room in pet storage. Walk to an existing Meadow tree and activate SHAKE TREE. Confirm that same tree rocks, disappears, and immediately shows Meadow Egg → named/rarity-colored pet. Equip it and verify following.
2. Fill pet storage and retry an available tree. Confirm PET INVENTORY FULL, no reward, no disappearance and no cooldown. Fill the last slot during an active shake to confirm the final capacity check also cancels cleanly.
3. Start two actual clients. Trigger the same tree nearly simultaneously: exactly one pet owner, one challenge credit each, and one 20-second timer. Then trigger different trees together: one independent result/cooldown per tree.
4. Check the same instance returns no earlier than 20 seconds with the exact pivot, part CFrames, transparency, collision/effects and prompt state. Include a Model and one of the two MeshPart trees.
5. Shake unlocked trees in each biome and confirm its mapped egg. Try a locked biome: no award. Enable Rainbow/Blood Moon and confirm modifiers remain active; reset weather afterward.
6. Die/respawn after an award and verify one committed pet. Leave/rejoin using a separate test profile to finish persistence acceptance. Confirm Index/challenge progress increments once and protected auto-delete remains protected.
7. Check desktop/mobile hatch presentation and first-tree tutorial guidance. Insert a real egg/pet model at its asset path and repeat; the viewport should use it automatically.

Final live acceptance on the corrected sources: **37 two-client server assertions**, **9 client presentation assertions**, and **6 Model/MeshPart motion/restoration assertions**, all with **zero failures**. The earlier solo run also passed 33 server / 6 client assertions. [Final multiplayer evidence](live-multiplayer-final.txt), [final motion evidence](live-motion-final.txt), [client 1](live-client-final-1.txt), [client 2](live-client-final-2.txt).

The final edit-place audit confirms **15/15 changed source files match disk**, **322 registered trees**, **zero generated gameplay geometry**, **zero egg stations**, **zero temporary audit scripts**, and all seven asset folders present. [Audit](final-edit-audit.json). All **448 inspected map candidates retain identical paths, pivots, bounds and part geometry** compared with the pre-edit snapshot. [Map preservation](map-preservation-audit.json).

A clean full authored-place recovery copy was downloaded: [AnimalKingdom-tree-egg-loop-complete.rbxl](AnimalKingdom-tree-egg-loop-complete.rbxl), **9,569,326 bytes**. [Save evidence and SHA-256](full-place-save.json). Studio's Download a Copy operation also saved the edit changes to the Roblox place; no Publish command was invoked.

The remaining checklist items are the manual presentation/persistence/device sweep and eventual SFX/model imports, not a blocker in the corrected core loop.
