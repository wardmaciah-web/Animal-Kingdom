> The tree/egg loop in this historical report is superseded by the [authored-tree correction](../tree-egg-loop-20260917/REPORT.md): existing trees now hatch biome eggs directly for free; generated trees and world egg stands are retired. The correction also includes a clean full-place save and successful two-client tests.

# Animal Kingdom — 20-system build report

Implemented in the existing `Real_Animal_K` Rojo project. The implementation uses the existing `OriginalData1` ProfileStore, existing plot allocator, existing weather state, and existing admin controls. `default.project.json`, the map, the plot allocator, WeatherAdminService, weather timing, cameras, announcements, and weather presentation sources were preserved.

**Validation:** 600 gameplay assertions pass; the existing admin and profile-lifecycle regression suites pass; all 124 first-party Luau files compile; every recorded phase builds and generates a sourcemap. The static audit resolves 183 literal requires, finds no static require cycle or missing service, and checks eight protected sources against their original hashes. [Exact results](final-test-results.txt), [phase builds](phase-validation.jsonl), [source audit](source-audit.json).

**Live evidence and limits:** the final source revision passed **83 live server assertions and 6 live client assertions, zero failures**, finishing at 02:02 UTC September 18 (7:02 PM Pacific September 17). Every biome had six resources and its main egg. The actual tree timer/restoration, triple hatch, capacity, ownership, progression, all 18 weather modifier resets, seven asset-category swaps, HUD, hatch viewports and pet following passed. The isolated test registry restored the original saved ProfileStore object. Live testing found and fixed crowded-biome station placement and missing empty asset folders; the final run includes both fixes. [Final live evidence](final-live-validation.txt).

**Current host blocker:** macOS subsequently locked (`ScreenLocked = true`), and Studio exposes zero controllable windows. No security controls were bypassed. Actual two-/four-client testing, final device/layout checks and a fresh full authored-place save remain blocked. The existing map has four plot slots. Two temporary single-player audit scripts may remain in the edit place; they are outside the Rojo build and must be removed before publishing using [the prepared cleanup command](cleanup-temporary-tests.studio.lua). [Host/cleanup details](host-dependency.txt).

“COMPLETE” below means the requested source implementation exists and its applicable available checks passed. It does not mean every feature has passed a final multiplayer/device playtest.

## 1. 20-SYSTEM STATUS

| # | System | Status |
|---|---|---|
| 1 | Profile / data foundation | COMPLETE |
| 2 | Economy | COMPLETE |
| 3 | Tree / resource gathering | COMPLETE |
| 4 | Pet core framework | COMPLETE |
| 5 | Pet inventory / equipping | COMPLETE |
| 6 | Pet following | COMPLETE |
| 7 | Egg hatching | COMPLETE |
| 8 | Luck / RNG modifiers | COMPLETE |
| 9 | Pet Index | COMPLETE |
| 10 | Biome progression / live content binding | COMPLETE |
| 11 | Pet-assisted gathering | COMPLETE |
| 12 | Pet XP / variants | COMPLETE |
| 13 | Upgrades | COMPLETE |
| 14 | Daily / weekly challenges | COMPLETE |
| 15 | Weather gameplay integration | COMPLETE |
| 16 | Central loot / drop tables | COMPLETE |
| 17 | HUD / notifications | COMPLETE |
| 18 | Tutorial | COMPLETE |
| 19 | Plots / shops / seasonal foundation | COMPLETE |
| 20 | Security / performance / release audit | PARTIAL |

System 20: automated security/data tests, source audits and final single-player Studio checks pass. Actual concurrent clients, final placement/device testing, persistence rejoin acceptance, populated-server performance, temporary-test cleanup and recovery saving remain pending because the host session is locked. The authored place has **four plot slots**; its existing allocator rejects a fifth player. A five-player admission test needs an additional authored plot, or release capacity must match those four slots. No extra plot or map geometry was invented.

The prior weather work was resumed: its final meteor/ghost test passed **19 assertions**, including the full 30-second crater lifetime. The live admin regression verified six panels, 15 camera labels, every teleport, filtered announcements, the event queue, emergency reset and production timing. [Weather lifetime evidence](../weather-polish-20260917/final-phenomena-test.txt), [admin evidence](../weather-polish-20260917/final-admin-regression.txt). A full authored-place save remains pending.

## 2. FILES CREATED

All new source files, relative to the project root:

- `src/ReplicatedStorage/Assets/Decorations/init.meta.json`
- `src/ReplicatedStorage/Assets/Eggs/init.meta.json`
- `src/ReplicatedStorage/Assets/Furniture/init.meta.json`
- `src/ReplicatedStorage/Assets/Pets/init.meta.json`
- `src/ReplicatedStorage/Assets/Resources/init.meta.json`
- `src/ReplicatedStorage/Assets/Seasonal/init.meta.json`
- `src/ReplicatedStorage/Assets/Trees/init.meta.json`
- `src/ReplicatedStorage/Assets/init.meta.json`
- `src/ReplicatedStorage/Shared/Gameplay/AssetResolver.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/BiomeDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/ChallengeDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/CurrencyDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/DropTables.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/EggDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/IndexRewardDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/PetDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/RarityDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/SeasonalDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/ShopDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/TutorialDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/UpgradeDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/VariantDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/WeatherGameplayDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/PetAppearance.lua`
- `src/ReplicatedStorage/Shared/Gameplay/PetMath.lua`
- `src/ReplicatedStorage/Shared/Gameplay/ProfileMigrations.lua`
- `src/ReplicatedStorage/Shared/Gameplay/WeightedRandom.lua`
- `src/ServerScriptService/ServerSource/Server/BiomeService.lua`
- `src/ServerScriptService/ServerSource/Server/ChallengeService.lua`
- `src/ServerScriptService/ServerSource/Server/EconomyService.lua`
- `src/ServerScriptService/ServerSource/Server/EggService.lua`
- `src/ServerScriptService/ServerSource/Server/GameplayService.lua`
- `src/ServerScriptService/ServerSource/Server/IndexService.lua`
- `src/ServerScriptService/ServerSource/Server/LootService.lua`
- `src/ServerScriptService/ServerSource/Server/ModifierService.lua`
- `src/ServerScriptService/ServerSource/Server/NotificationService.lua`
- `src/ServerScriptService/ServerSource/Server/PlacementService.lua`
- `src/ServerScriptService/ServerSource/Server/PlotService.lua`
- `src/ServerScriptService/ServerSource/Server/ResourceService.lua`
- `src/ServerScriptService/ServerSource/Server/SeasonalService.lua`
- `src/ServerScriptService/ServerSource/Server/ShopService.lua`
- `src/ServerScriptService/ServerSource/Server/TutorialService.lua`
- `src/ServerScriptService/ServerSource/Server/UpgradeService.lua`
- `src/ServerScriptService/ServerSource/Server/WeatherGameplayService.lua`
- `src/ServerScriptService/ServerSource/Server/WorldContentService.lua`
- `src/ServerScriptService/ServerSource/Utilities/GameplayRequestPolicy.lua`
- `src/StarterGui/AnimalKingdomUI/BiomeImages.lua`
- `src/StarterGui/AnimalKingdomUI/GameplayWidgets.lua`
- `src/StarterGui/AnimalKingdomUI/HatchPresentation.lua`
- `src/StarterGui/AnimalKingdomUI/PetMenus.lua`
- `src/StarterGui/AnimalKingdomUI/PlotMenu.lua`
- `src/StarterGui/AnimalKingdomUI/ProgressionMenus.lua`
- `src/StarterPlayer/StarterPlayerScripts/PetFollowing.client.lua`

New test and validation tools:

- `tests/Gameplay.spec.lua`
- `tests/Gameplay.studio.server.lua`
- `tests/Gameplay.studio.client.lua`
- `tests/GameplayMultiplayer.studio.server.lua`
- `tests/GameplayMultiplayer.studio.client.lua`
- `tests/run_gameplay_tests.py`
- `tools/gameplay/validate_phase.py`
- `tools/gameplay/audit_source.py`
- `tools/gameplay/prepare_live_tests.py`

Generated evidence in `documentations/gameplay-20-systems-20260917/`:

- `REPORT.md` — this report.
- `AnimalKingdom-gameplay-source.rbxlx` — mapped Rojo source build.
- `AnimalKingdom-gameplay.sourcemap.json` — source hierarchy.
- `phase-validation.jsonl` — every phase/build/compiler result.
- `source-audit.json` — static requires, service registration and protected-file checks.
- `final-test-results.txt` — final gameplay/admin/profile test output.
- `files-manifest.json` — complete source file inventory and hashes, plus every baseline backup path.
- `baseline-hashes.json` and `baseline/` — the pre-edit source snapshot; every copied file is enumerated in the manifest.
- `initial-live-validation.txt` and `initial-live-hud.png` — initial Studio evidence.
- `final-live-validation.txt` — final 83 server / 6 client checks, all passing.
- `host-dependency.txt` — exact remaining host boundary and cleanup state.
- `cleanup-temporary-tests.studio.lua` — guarded edit-place audit-script removal.

Also created `documentations/weather-polish-20260917/final-phenomena-test.txt` and `final-admin-regression.txt` from actual Studio log results. No trading system or fabricated Roblox asset IDs were added.

## 3. FILES MODIFIED

- `src/ReplicatedStorage/ClientSource/Client/DataController.lua`
- `src/ReplicatedStorage/SharedSource/Datas/ProfileTemplate.lua`
- `src/ServerScriptService/ServerSource/Server/CurrencyService.lua`
- `src/ServerScriptService/ServerSource/Server/EventModifierService.lua`
- `src/ServerScriptService/ServerSource/Server/HarvestService.lua`
- `src/ServerScriptService/ServerSource/Server/PetService.lua`
- `src/ServerScriptService/ServerSource/Server/PlayerDataService.lua`
- `src/ServerScriptService/ServerSource/Server/ProfileService.lua`
- `src/ServerScriptService/ServerSource/Server/ProgressionService.lua`
- `src/ServerScriptService/ServerSource/Server/SanctuaryService.lua`
- `src/ServerScriptService/ServerSource/Server/WorldService.lua`
- `src/ServerScriptService/ServerSource/Utilities/GameplayGuard.lua`
- `src/StarterGui/AnimalKingdomUI/Main.client.lua`
- `src/StarterGui/AnimalKingdomUI/RemoteBridge.lua`
- `tests/SystemAudit.spec.lua`
- `tests/run_system_audit_tests.py`
- `documentations/weather-polish-20260917/LIVE-VALIDATION-STATUS.md`

The old currency/progression/harvest service names remain compatibility adapters. The obsolete map-building body was retired from WorldService; WorldContentService now adds interactive content on discovered existing floors. The production UI uses real profile data instead of sample inventory content.

## 4. PROFILE SCHEMA

Saved top-level fields after migration:

```lua
DataVersion = 2
SchemaVersion = 2 -- legacy compatibility version
Currencies = { Coins = 0, FriendshipTokens = 0 } -- registered event currencies added when earned
Pets = {
  { UID, UniquePetId, PetId, Level, XP, Mutation, Shiny, Prismatic,
    Favorite, Locked, AcquiredAt }
}
EquippedPets = { UID, ... }
PetStorageCapacity = 50
MaxEquippedPets = 3
PetIndex = { [PetId] = { Count, Variants = { [Variant] = true } } }
UnlockedBiomes = { Meadow = true }
Upgrades = { [UpgradeId] = Level }
DailyChallenges = {
  PeriodStart, ResetAt,
  Entries = { [ChallengeId] = { Type, Target, Progress, Claimed } }
}
WeeklyChallenges = { PeriodStart, ResetAt, Entries = { ... } }
TutorialCompleted = false
TutorialProgress = { Step = 1, Gathered, Assisted }
Settings = { AutoDelete = { [Rarity] = boolean }, ReducedMotion = false, ShowOtherPets = true }
PlotProgression = {
  Level = 0, VisitorsAllowed = true,
  Placements = { { UID, ItemId, X, Z, Rotation }, ... }
}
SeasonalData = {
  [SeasonId] = { Edition, Progress, Claims, History = { [Edition] = { Progress, Claims } } }
}
Items = { [ItemId] = Count }
IndexRewards = { [MilestonePercentString] = true }
Stats = { Gather, Hatch, EarnCoins, EarnTokens, Weather, UnlockBiome, LastWeatherKey }
Boosts = { { Key, Multiplier, ExpiresAt }, ... }
RecoveryData = { Pets, Placements, PetIndex } -- only populated for malformed recovered records

-- Preserved legacy save fields:
ForestCoins = 0          -- mirror of Currencies.Coins
FriendshipTokens = 0     -- mirror of Currencies.FriendshipTokens
OwnedPets = {}           -- server-side alias of Pets
DisplayedPetIds = {}
NumNomIndex = {}
UnlockedDecorations = {}
UncollectedSanctuaryCoins = 0
SanctuaryIncomeUpdatedAt = 0
```

Existing balances, copies of pets, Index entries, unlocks and unknown fields survive migration. Unknown pet definitions remain saved. Duplicate/missing pet UIDs are repaired. Malformed records are retained in RecoveryData where applicable. A server refuses a profile from a newer DataVersion. New players start at zero Coins; existing balances are retained. ProfileStore continues to own session locking, autosave and BindToClose; the existing ProfileService owns join/leave and session release.

## 5. ECONOMY

Coins and Friendship Tokens are saved in `Currencies`. EconomyService owns `GetBalance`, `Add`, `Spend` and `CanAfford`; CurrencyService delegates to it. Purchases use server definitions. Non-finite, fractional, negative, unsupported-currency and unaffordable transactions are rejected. Main currencies cap at 9,000,000,000,000,000. Generic PlayerDataService setters cannot modify currency fields. `HarvestCandy` is registered for the inactive Halloween foundation.

## 6. TREE SYSTEM

- CollectionService tags: `GatherableTree` / `GatherableResource`.
- A successful request locks `AVAILABLE → SHAKING` before any yield; the shake lasts 1.2 seconds.
- One harvest resolves its configured drop once. Some drops deliberately include a token reward plus Coins; this is one harvest, not a duplicated reward.
- The instance is hidden; prompts, collision, touch and query are disabled, alongside visual emitters/labels.
- State becomes `RESPAWNING`; the server schedules restoration exactly 20 seconds after hiding, then restores the exact saved pivot, rotation, transparency, collision flags and prompt state.
- Roblox runs the callback on an available scheduler frame at/after the deadline; sub-frame wall-clock precision is not promised.
- The production-service adapter test verifies two-player contention and one reward owner. Final live Studio verification passed shake, duplicate denial, hidden flags, no early return, the actual twenty-second deadline, exact transform/property restoration and no repeated reward. Two actual clients still require the prepared multiplayer test.

## 7. PET SYSTEM

Unique ownership records support multiple copies. Inventory actions include equip/unequip, favorite/unfavorite, lock/unlock, server-token delete confirmation, sorting and filtering. Storage and slot caps are enforced. Equipped lists are replicated as metadata; followers interpolate locally in rows, recover from large teleports/respawns, and move toward gathering targets. XP uses a configurable curve through level 100. Variants include Shiny, Prismatic and Normal/Golden/Leafy/Frosted/Lava/Shadow/Electric/Crystal/Rainbow/Spirit mutations. Shared rarity definitions include Common through Secret and a compatibility alias for Mystic.

The 300 existing pet identities were preserved. Bunny, Dog, Deer and GoldenFox add four introductory identities: **304 Index entries total**. Index milestones at 25%, 50%, 75% and 100% are single-claim server rewards. Undiscovered entries display `???`; discovered entries show their variants.

## 8. EGGS

Server RNG, definition prices, biome access, range, cooldown and capacity are checked. Pets are constructed before the price is debited; no yielding operation separates debit and inventory insertion. Single/triple hatch modes are implemented without monetization. Central modifiers affect rarity weights, mutation and shiny/prismatic rolls. Auto-delete records Index discovery while protecting favorites, locks, Prismatic and definition-protected pets. Client presentation uses a model, wiggle, flash and reveal. The legacy Meadow collection remains obtainable through a separate Meadow Collection Egg.

## 9. BIOMES

Costs preserve the existing progression configuration. Each resource table is centralized and initially mixes base Coins, larger Coins and a token-plus-Coins drop.

| Biome | Requirement | Unlock Coins | Egg / egg Coins | Resource table |
|---|---|---:|---|---|
| Meadow | Default | 0 | MeadowEgg / 250 | MeadowTree |
| Forest | Meadow | 2,500 | ForestEgg / 750 | ForestTree |
| Jungle | Forest | 25,000 | JungleEgg / 2,500 | JungleTree |
| Desert | Jungle | 250,000 | DesertEgg / 25,000 | DesertTree |
| Snow | Desert | 2,500,000 | SnowEgg / 250,000 | SnowTree |
| Volcano | Snow | 25,000,000 | VolcanoEgg / 2,500,000 | VolcanoTree |
| Ocean | Volcano | 250,000,000 | OceanEgg / 25,000,000 | OceanTree |
| Ancient Ruins | Ocean | 2,500,000,000 | AncientRuinsEgg / 250,000,000 | AncientRuinsTree |
| Magical Forest | Ancient Ruins | 25,000,000,000 | MagicalForestEgg / 2,500,000,000 | MagicalForestTree |
| Sky | Magical Forest | 250,000,000,000 | SkyEgg / 25,000,000,000 | SkyTree |
| Prehistoric | Sky | 2,500,000,000,000 | PrehistoricEgg / 250,000,000,000 | PrehistoricTree |
| Mythical | Prehistoric | 25,000,000,000,000 | MythicalEgg / 2,500,000,000,000 | MythicalTree |

Meadow Collection Egg costs 500 Coins. Biome checks remain active in hatching, resource rewards and challenges even if someone moves into a locked region. Authorized admins can pass navigation barriers; this does not grant currency or bypass gameplay ownership/unlocks. World content uses the existing `BiomeTeleport.Landing.FindFloor` lookup and clear-point checks; absent live floors are reported, not fabricated.

## 10. CHALLENGES

Daily: shake 20 trees; shake 50 trees; hatch 5 eggs; earn 5,000 Coins; collect 20 Friendship Tokens; experience one weather event.

Weekly: shake 500 trees; hatch 100 eggs; earn 250,000 Coins; experience 10 weather events; unlock two biomes.

Progress, type, target, claim state and reset boundaries are saved. Daily resets use UTC midnight; weekly periods use Monday UTC. Server claims require completion and are consumed before crediting. Challenge/Index/refund currency does not recursively advance earn-currency challenges.

## 11. WEATHER GAMEPLAY

Existing EventDefinitions buffs are reused; no second weather timeline was added. All modifiers return to one outside the Event phase. Values below multiply together where relevant.

| Event | Gameplay modifiers / hooks |
|---|---|
| Sunny Skies | Coins ×1.5; pet luck ×1.10; gathering power ×1.10 |
| Rainy Day | Coins ×1.25; Common weights ×1.15; resource rewards ×1.20 |
| Thunderstorm | Rare weights ×1.5; mutation ×1.25; resources ×1.10; StormLoot supplemental table |
| Snowfall | Coins ×2; Snow pet-type weights ×1.25; Snow resource rewards ×1.25 |
| Foggy | Shiny ×1.25; Rare-and-higher weight adjustment ×1.20 |
| Windy | Sky/flying-type weights ×1.5; movement ×1.25; gathering ×1.25 |
| Heatwave | Coins ×2; Desert-type weights ×1.25; Desert/Volcano resources ×1.25 |
| Aurora | Shiny ×3; Rare weights ×1.5; luck ×1.25 |
| Blood Moon | Mutation ×2; Legendary weights ×1.5; Rare-and-higher adjustment ×1.5 |
| Meteor Shower | Rare weights ×3; MeteorLoot supplemental table / Meteor Shard support |
| Spirit Night | Mythical weights ×2; mutation ×1.5; event-only Spirit mutation weight |
| Rainbow | Global luck ×2; resources ×1.25 |
| Golden | Coins ×10; Shiny ×5 |
| Chaos | Coins/luck/Shiny/mutation/XP ×5; gathering ×2; deterministic resource stages ×2 / ×2.5 / ×3 |
| Inverted | Rare weights ×3; Friendship Tokens ×2 |
| Nightmare | Legendary weights ×10; Rare-and-higher adjustment ×2 |
| Void | Mythical weights ×5; mutation ×3; Secret weights ×2 |
| Admin Abuse | Coins ×5; luck ×3; Rare/Legendary/Mythical weights ×3; Shiny/mutation ×5; XP ×3; movement ×1.5; gathering/resources ×3 |

Type-wide multipliers normalize away inside an egg containing only that one biome/type; their extension point becomes meaningful for mixed pools. Snow/Heatwave/Windy still have their separate active resource/movement bonuses. Secret weighting is a framework hook; the current preserved collection does not add a new Secret species.

## 12. UI

Completed source: responsive currency counters, current weather/biome, navigation, Pets, Index, Challenges, Upgrades, Biomes, Settings, plot income/shop/placement menu, hatch choices, hatch reveal, deletion confirmation, queued/merged reward notices, and a 14-step tutorial with a world target marker. Existing biome thumbnail IDs were reused. Pet lists paginate at 12 and Index lists at 24. The final live client passed HUD, three hatch viewport reveals, local following, noncolliding pet geometry and follower proximity. Full desktop/mobile interaction and layout sweeps remain pending.

## 13. SECURITY

`GameplayRequestPolicy` validates the sender, living character, exact action, exact allowed payload fields, primitive/Instance types and finite coordinates. No action accepts a reward amount, requested RNG result or another player identity. The gateway dispatches synchronous server transactions with a per-player busy guard. Target services verify registered targets, distance, ownership, currency, capacity, biome, definition and event state as applicable. Menu purchases have no fabricated physical-shop distance requirement; world interactions and placements enforce distance.

| Action family | Minimum interval |
|---|---:|
| All gameplay UI requests combined | 0.08 s |
| Equip / favorite / lock | 0.15 s |
| Settings / auto-delete | 0.20 s |
| Hatch request | 0.25 s, plus successful hatch cooldown (2 s base, 0.6 s floor) |
| Gather / delete / tutorial | 0.30 s |
| Upgrades / challenge claims / placement | 0.40 s |
| Biomes / Index / seasonal claim / shops / plot operations | 0.50 s |
| Existing biome teleport | 0.75 s |
| Profile snapshot | 1 s; one pending load request |
| Public profile reads | 0.50 s |

Legacy Sanctuary requests retain ownership/range/capacity checks and 0.15/0.5-second throttles. Legacy Harvest/Progression endpoints forward into the authoritative new services. Existing admin policies were preserved and regression-tested. Studio-only development log/execution infrastructure remains Studio-gated. No new admin command or trading remote was exposed.

## 14. PERFORMANCE

One server Heartbeat services only actively shaking resources; respawns use bounded scheduled callbacks. No per-tree infinite loop, server pet-motion loop or per-frame Workspace scan was added. One 30 Hz client follower update culls at 180 studs and caps visible pets at 60. Equipped metadata replaces motion replication. XP updates send only affected equipped-pet records. Imported asset emitters have a bounded per-model rate and lifetime. Followers, resource registrations and plot visuals clean up on removal/session departure. Notifications merge currency bursts and cap their queue; menus paginate. Map placement is a startup-only bounded search. Plot restore, challenge rollover and biome boundary checks use separate low-frequency shared loops. Populated-server/device FPS and memory soak tests remain pending.

## 15. PLACEHOLDERS / FINAL ASSET LOCATIONS

Insert Models or BaseParts at these exact locations. Folders preserve unknown imported instances through Rojo; server initialization also creates missing empty asset folders in the live place. All seven category fallback/replacement checks passed in Studio.

| Asset | Location / name |
|---|---|
| Pets | `ReplicatedStorage.Assets.Pets.Dog`, `.Bunny`, `.Deer`, `.GoldenFox`, or the `ModelName` in PetDefinitions |
| Eggs | `ReplicatedStorage.Assets.Eggs.MeadowEgg`, `ForestEgg`, etc.; `MeadowCollectionEgg` is also supported |
| Trees | `ReplicatedStorage.Assets.Trees.MeadowTree`, `ForestTree`, etc. |
| Resources | `ReplicatedStorage.Assets.Resources.MeadowResource`, `ForestResource`, etc. |
| Furniture | `ReplicatedStorage.Assets.Furniture.WoodenChair`, or a ShopDefinitions ModelName |
| Decorations | `ReplicatedStorage.Assets.Decorations.FlowerPot`, or a ShopDefinitions ModelName |
| Seasonal | `ReplicatedStorage.Assets.Seasonal.Pumpkin`, or a future seasonal ModelName |

The resolver checks current assets on every creation and clones valid imported geometry. Missing models use generated geometry. Dog requires no PetService change. Pet followers and generated egg/tree/resource stations also listen for newly inserted replacements; an active tree harvest keeps its cooldown. Placed furniture/decorations resolve new geometry on placement or restoration. Logical ownership and rewards never derive from geometry. Pivot/grounding code uses Roblox’s documented [Model APIs](https://create.roblox.com/docs/reference/engine/classes/Model) and [BasePart pivot offsets](https://create.roblox.com/docs/reference/engine/classes/BasePart).

## 16. MISSING FINAL ASSETS

Final art is still needed for any missing definition model: 304 pet identities/desired variants, 13 egg identities, biome tree/resource models, furniture/decorations, seasonal props and future seasonal creatures/eggs. Optional final hatch/gather sounds, cracks, icons and finished placement art can replace the current presentation. No invented mesh/image/audio IDs were used. Existing weather audio retains its documented 69 unfilled specialized SFX slots with safe fallbacks or silence; subjective final audio mixing is still separate work.

## 17. BUILD

- `rojo build default.project.json -o .../AnimalKingdom-gameplay-source.rbxlx`: **PASS**.
- `rojo sourcemap default.project.json -o .../AnimalKingdom-gameplay.sourcemap.json`: **PASS**.
- Native Luau compilation: **124 files PASS**.
- Production-module gameplay tests: **600 assertions, zero failures**.
- Existing admin-command and profile-lifecycle suites: **PASS**.
- Static hierarchy/service audit: **PASS**.
- Final live Studio: **83 server + 6 client assertions, zero failures**.
- Four Studio test scripts (solo and multiplayer pairs): native syntax compilation **PASS**; the multiplayer pair is prepared but unexecuted.

The Rojo output contains mapped source and mapped blockout instances. The authored live map/plots are not completely represented by that output. It is not a replacement full-map recovery file. The prior full-map backup remains intact at `documentations/full-audit-20260917/AnimalKingdom-after-full-audit-20260917.rbxl`.

## 18. LIVE STUDIO TEST PLAN

1. After the macOS session is unlocked, confirm Studio Edit mode and run [cleanup-temporary-tests.studio.lua](cleanup-temporary-tests.studio.lua). It removes only `ServerScriptService.AK_GameplayReleaseTest` and `StarterPlayer.StarterPlayerScripts.AK_GameplayClientTest`, provided they retain the `TemporaryAudit` marker. Do this before publishing or ordinary gameplay testing.
2. Run `python3 tools/gameplay/prepare_live_tests.py --multi`, execute its generated Command Bar payload in Edit mode, then start a real server with two clients. The prepared test sends actual simultaneous gather/hatch remotes, checks one reward owner/one 20-second cooldown, distinct plots, separate inventories and UIDs, and real plot placement/ownership. Require `AK_MULTI_DONE ... failures=0`. Repeat with `--multi --four` and four clients. Remove audit scripts afterward. These tests compile but have not run.
3. Complete the new-player tutorial through assisted gathering using a separate test profile. Leave/rejoin and verify currencies, pets, flags, equipment, upgrades, biome unlocks, claims, placements and tutorial completion persist.
4. Check all menus at desktop, laptop and mobile sizes. Exercise protected auto-delete, delete confirmation, respawn, long teleports, admin-room follower recovery, placement edges/rotations, collision rejection, idle collection and restoration.
5. Run a four-player weather/resource performance soak and watch FPS, memory and cleanup. The existing allocator has four plots and rejects a fifth player; five-player admission requires an additional authored plot, or release capacity must stay at four. No new plot geometry was fabricated.
6. Stop Play, rerun cleanup, and download/save a fresh full authored-place `.rbxl`. The current Rojo source build passes but does not contain every authored map object. Existing full-map backups remain intact.

No publish/deployment was performed. The remaining acceptance work and full-place save require an unlocked Studio session; the implementation and local validations are complete.
