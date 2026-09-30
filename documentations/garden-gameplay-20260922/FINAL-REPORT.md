# Animal Kingdom — Garden gameplay implementation

Implemented in `/Users/jefferypryor/Documents/SuperbulletAI/Real_Animal_K` and the connected Animal Kingdom Studio place.

- Studio instance: `3f8f99bb-3810-4b74-8fb6-9c4189c06f38`
- PlaceId: `132313449035787`
- GameId: `10764288431`
- No publishing, datastore changes, or profile resets.
- Existing Garden environment, pond, bridge, vegetable beds, fences, paths and trees retained.
- Two fresh preflight Play joins reached Ready before implementation. Five gameplay/visual Play sessions followed.
- Existing `ProfileService`/`OriginalData1` and `StudioMockSnapshot` behavior retained. The complete saved profile envelope remained identical to the pre-task snapshot.

## A. Player Plot → Garden Plot mapping

The existing `AK_PlotAssignment` and `PlotLocator.getPlots()` remain authoritative. Garden assignment reads the player's existing `PlotId`; it does not introduce another PlayerAdded assignment script.

| Actual player plot | Matching Garden plot |
|---|---|
| `Workspace.PlayerPlots.Plot1Floor` | `Workspace.PetGardenRealm.GardenPlot1` |
| `Workspace.PlayerPlots.Plot2Floor` | `Workspace.PetGardenRealm.GardenPlot2` |
| `Workspace.PlayerPlots.Plot3Floor` | `Workspace.PetGardenRealm.GardenPlot3` |
| `Workspace.PlayerPlots.Plot4Floor` | `Workspace.PetGardenRealm.GardenPlot4` |

Owner signs reuse the existing sign GUI: `DisplayName's Garden` and `@username`, or `AVAILABLE GARDEN`. The actual test player received Player Plot 1 and Garden Plot 1. Release clears owner attributes and replicated visual state; saved expeditions remain.

## B. Number of Garden plots

**4**, matching the **4 actual player plots**. Fences, displays and spawn markers are excluded by the existing plot locator. Startup checks the counts.

## C. Forage slots per player

**3**: `ForageSlot_1`, `ForageSlot_2`, `ForageSlot_3` inside each Garden plot; **12 slots server-wide**. Each contains a pet anchor, five invisible crop markers, a status plaque and a small basket. Existing soil and plot geometry remain in place.

## D. Crop model paths

| Canonical template | Parts | Appearance |
|---|---:|---|
| `ReplicatedStorage.GardenAssets.Crops.Carrot` | 6 | Orange root and green leaves |
| `ReplicatedStorage.GardenAssets.Crops.Tomato` | 5 | Red fruit, green stem and leaves |
| `ReplicatedStorage.GardenAssets.Crops.Pumpkin` | 11 | Seven orange ribs, stem and leaves |
| `ReplicatedStorage.GardenAssets.Crops.Starberry` | 10 | Pink berry, five-point star detail, subtle sparkle |
| `ReplicatedStorage.GardenAssets.Crops.Moonmelon` | 11 | Mint melon, pale crescent, very faint light |

The inserted Vegetable Garden was inspected: it contains beds and fencing, not separate crop geometry. Separate imported carrot/pumpkin meshes were gray and untextured. Lightweight colored crop templates were therefore authored, with no scripts inside them. Original landscaping assets were preserved.

The obsolete duplicate Studio `GardenPlotVisuals` controller was traced, renamed `GardenPlotVisuals_LegacyDisabled`, and disabled. Its green/gold `CropStage` balls no longer appear. Internal markers have Transparency 1 and cannot collide.

## E. Crop rarity table

| Crop | Rarity | Base event weight | Visual regrow time |
|---|---|---:|---:|
| Carrot | Common | 40% | 5 s |
| Tomato | Common | 30% | 5 s |
| Pumpkin | Uncommon | 18% | 8 s |
| Starberry | Rare | 9% | 11 s |
| Moonmelon | Very Rare | 3% | 14 s |

Luck is calculated once. Moonmelon is capped at **8% per event**, including the strongest combined bonuses. A 10,000-event deterministic check yielded 3,999 Carrots, 2,998 Tomatoes, 1,792 Pumpkins, 901 Starberries and 310 Moonmelons at base weights.

## F. Persistent crop schema

The existing flat profile convention was extended additively:

```lua
Currencies.GardenHarvest -- existing Harvest balance, unchanged location
GardenCrops = {Carrot=0, Tomato=0, Pumpkin=0, Starberry=0, Moonmelon=0}
GardenUpgrades = {KeenNose=0, QuickForager=0, BountifulBeds=0,
                 RareCropAlmanac=0, HarvestSatchel=0}
GardenBoosts = {LuckySprout=expirationTimestamp, ...}
GardenExpeditions = {...} -- existing collection
GardenCosmetics = {...}   -- existing ownership
Pets[i].Cosmetic          -- existing equipped cosmetic
```

Migration initializes missing fields, preserves valid existing totals and unknown fields, and is idempotent. Malformed known values are preserved in `RecoveryData.GardenMigration` before safe defaults are applied. No competing `Garden` currency/table replaces the existing schema. Additive fields retain profile version 3 compatibility.

## G. Expedition data schema

Existing `UID`, `TripId`, `PetId`, `DurationId`, `Duration`, `StartedAt`, and `ReadyAt` remain compatible. Added fields:

```lua
{
    ForagingVersion = 1,
    PetInstanceId = UID,
    SlotId = 1,                    -- server-selected 1..3
    EndsAt = ReadyAt,
    LastProcessedAt = StartedAt,
    ProcessedCycles = 0,
    CycleWork = 0,                 -- fractional cycle progress
    Seed = deterministicNumber,
    Power = serverComputedPower,
    QuantityCarry = 0,
    PendingCrops = {Carrot=0, Tomato=0, Pumpkin=0, Starberry=0, Moonmelon=0},
    PendingHarvest = 0,
    PendingXP = 0,
    Upgrades = numericUpgradeSnapshot,
    Boosts = expirationSnapshot,
    LastHarvest = {Crop="Carrot", Node=1, Amount=1, At=timestamp, Cycle=1},
}
```

Only datastore-safe values are saved. Models and CFrames stay outside profile data. A single server scheduler processes timestamp progress; offline catch-up uses the same pure calculation, splitting at boost expirations. Purchases process elapsed time before updating trip bonus snapshots, preventing retroactive bonuses.

Base cycles are 6 seconds. Sprout Run/Garden Shift/Grand Harvest remain **60/300/900 seconds**, producing **10/50/150 base cycles**. Pet power uses existing rarity, level, mutation, shiny and prismatic multipliers, capped at 150x. Crop quantity uses the square root of that power and the bounded quantity modifier; Harvest uses the existing 8-per-minute power basis. Existing Garden XP remains 10/minute before XP boosts.

Claim transfers the basket and Harvest once under the action lock, then removes the trip. Early recall pays half of earned progress, rounded down per crop and for Harvest/XP. Completed trips must be claimed for their full reward. Equipping or deleting an actively gardening pet is blocked.

## H. Shop catalog

All prices use existing Harvest. Supplies activate immediately; repeat purchases extend the same expiration.

| Supply | Cost | Effect | Duration |
|---|---:|---|---:|
| Lucky Sprout Potion | 60 | +20% rare crop weighting | 10 min |
| Golden Clover Tonic | 180 | +40% rare crop weighting | 10 min |
| Forager's Tea | 80 | +25% crop quantity | 10 min |
| Bountiful Brew | 220 | +50% crop quantity | 10 min |
| Swift Paws Elixir | 100 | +25% cycle speed | 10 min |
| Starberry Scent | 140 | +75% Starberry weighting | 10 min |
| Moonmelon Charm | 300 | +100% Moonmelon weighting, subject to 8% cap | 10 min |
| Garden XP Treat | 120 | +25% existing Garden pet XP | 15 min |

All eight supplies were purchased successfully in the actual Play test; combined price was **1,200 Harvest**.

Existing cosmetics remain account-wide: Flower Crown **40**, Strawberry Hat **90**, Leafy Aura **150**, Golden Bloom **300**, Rainbow Sprout **500** Harvest. The Cosmetics tab supports purchase, choosing any owned pet to wear an owned cosmetic, and removal. Strawberry Hat purchase/equip passed in Play.

## I. Permanent upgrades

Each has five levels costing **150 / 300 / 600 / 1,000 / 1,600** Harvest.

| Upgrade | Per level | Maximum |
|---|---|---|
| Keen Nose | +4 studs from base 24 | 44 studs |
| Quick Forager | +5% cycle speed | +25% |
| Bountiful Beds | +5% crop quantity | +25% |
| Rare Crop Almanac | +4% rare crop weighting | +20% |
| Harvest Satchel | +5% claim Harvest | +25% |

Every upgrade was bought through level 5 in Play; level 6 was rejected. Total cost for all five fully upgraded paths was **18,250 Harvest**. Level 1 Keen Nose gave 28 studs and survived the mock rejoin test.

## J. Active boost architecture

`GardenBoosts[SupplyId]` stores a server expiration. The server snapshots the relevant values into trips after processing past progress. Same-item reuse extends expiry rather than adding another effect. Different compatible supplies combine once.

Caps: effective rare luck bonus +110%; total quantity multiplier 2x; speed multiplier capped at 1.75x (current full catalog reaches 1.5x); XP 1.25x; Moonmelon probability 8%. A supply cannot be extended beyond a queued full day's allowance. The client displays countdowns and never supplies prices, durations, rewards, modifiers or crop totals.

## K. Scripts changed

Twelve runtime source files changed; two are new helper modules, not new services:

- `src/ServerScriptService/ServerSource/Server/GardenExpeditionService.lua` — extended existing backend, shared action lock/receipts, cycles, claims, shop, profile lifecycle integration.
- `src/ServerScriptService/ServerSource/Utilities/GardenPlotRuntime.lua` — **new** authored-plot adapter, owner signs, three slots, canonical crops, replicated visual state.
- `src/ReplicatedStorage/Shared/Gameplay/GardenProgress.lua` — **new** pure migration, modifiers, deterministic crops and offline progress.
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/GardenDefinitions.lua` — existing tuning, crop/supply/upgrade catalogs.
- `src/ReplicatedStorage/Shared/Gameplay/ProfileMigrations.lua` — additive Garden migration call.
- `src/ReplicatedStorage/SharedSource/Datas/ProfileTemplate.lua` — three new empty Garden dictionaries.
- `src/ServerScriptService/ServerSource/Server/GameplayService.lua` — existing dispatcher integration.
- `src/ServerScriptService/ServerSource/Utilities/GameplayRequestPolicy.lua` — strict Garden action payloads and request IDs.
- `src/ServerScriptService/ServerSource/Server/PetService.lua` — minimal equip/delete guards for gardening pets.
- `src/StarterPlayer/StarterPlayerScripts/GardenPlotVisuals.client.lua` — shared nearby visual scheduler and real pet/crop rendering.
- `src/StarterGui/AnimalKingdomUI/GardenMenus.lua` — Garden menu rework.
- `src/StarterGui/AnimalKingdomUI/Main.client.lua` — new Garden data refresh fields, claim breakdown, recall display and controller dialog focus.

Studio-only cleanup: obsolete duplicate Garden visual LocalScript disabled and renamed. `tools/audit/garden_progress_test.lua` adds repeatable regression checks outside runtime source. Final source sync was checked against the current Studio place. ProfileService's temporary test fixture hook was removed; ProfileService itself has no permanent changes from this task.

## L. Remotes used/changed

Existing `ReplicatedStorage.AnimalKingdomRemotes.UIRequest` and `GameplayFeedback` are reused. No parallel remote system was introduced.

Existing actions retained: `StartExpedition`, `ClaimExpedition`, `CancelExpedition`, `ClaimAllExpeditions`, `BuyGardenCosmetic`, `EquipGardenCosmetic`, `VisitGarden`, `ReturnGarden`.

Added dispatcher actions: `BuyGardenSupply` and `UpgradeGarden`. Mutating Garden requests carry a `RequestId`; the server applies rate limits, validates strict payload shapes, shares an action lock and rejects repeated request IDs. No client owner/price/reward/level fields are accepted. Public plot attributes replicate only visual state; private profile mutations always use the requesting player's loaded profile.

## M. UI controllers changed

GardenMenus, Main's Garden integration, and GardenPlotVisuals. Main tabs: Expeditions, Crops, Shop, Boosts. Shop subtabs: Supplies, Upgrades, Cosmetics. Three slot cards show actual real-model viewports, rarity/power, progress, countdown and live basket. Send flow includes all owned pets with pagination and explicit Equipped/Foraging/Locked/model-unavailable states, duration selection and a calculated estimate. Claim, recall, Claim All, styles, upgrades, boosts and teleport work through existing requests.

Garden action buttons are 44 pixels high and selectable. At 366-pixel panel width, the inspected Garden layouts had no text-height clipping. Controller A was used through the real send, shop, upgrade, claim and claim-dialog confirmation flows. Controller selection is preserved across updates. B is bound to back/close, with dialog-first behavior; the automation tool cannot inject that reserved CoreGUI key, so a physical-controller B test remains outstanding.

One server scheduler and one client visual scheduler serve all slots. Clients animate only near the Garden, at up to 24 updates/second. No Humanoids or per-crop scripts are used. Five crop nodes rotate per slot, leaving at least the required rare-crop regrowth interval even at capped speed. There are 60 visual crops for the four-plot realm, plus at most 12 pet clones. New slot/crop/pet parts are noncolliding.

## N. Actual Play test results

| Requested check | Result/evidence |
|---|---|
| 1–4: Join, player plot, matching Garden plot, owner sign | **PASS**. Ready; Plot1Floor → GardenPlot1; `KaiKai's Garden / @Maciahxcx1`. Four real player/Garden plots audited. |
| 5: Send from Meadow without visiting Garden | **PASS** through actual client `StartExpedition`. No Town/proximity requirement. |
| 6–9: Real pet, movement, harvest visuals, increasing basket | **PASS**. Real Meadow Fawn, Cloudtail Fox and Meadow Buck; moving/foraging states and changing positions; server basket cycles increased. |
| 10–14: All five crop types | **PASS**. Final full-stack claims contained 52 Carrots, 39 Tomatoes, 26 Pumpkins, 31 Starberries and 16 Moonmelons. |
| 15–19: Actual 60-second completion, claim, permanent totals, currency, duplicate denial | **PASS**. Unboosted Fawn paid 17 Harvest plus its basket; second claim rejected. A separate full UI Field Mouse claim paid 8 Harvest and included all five crops. |
| 20–22: Three pets; fourth denied; real physical models | **PASS**. Three distinct owned-pet UIDs matched three physical slots. Fourth request denied. Zero legacy CropStage balls. |
| 23–25: Recall, half reward, pet reusable | **PASS**. Recall paid expected 12 Harvest and half of each earned crop count. Second recall denied; same pet was sent again later. |
| 26–29: Lucky Sprout, charge once, timer, luck once | **PASS**. Exactly 60 deducted; repeated ID rejected; a second intentional purchase extended expiry by 600 seconds while luck remained +20%. |
| 30–33: Keen Nose level 1/range/rejoin/persistence | **PASS in serialized mock rejoin**. 28-stud radius; level remained 1 in the next actual Play session. |
| 34: Existing cosmetic purchase/equip | **PASS**. Strawberry Hat purchased and equipped; existing Flower Crown retained. |
| 35–37: Visit assigned Garden and return | **PASS**. Secure service paths moved the actual character; assigned owner plot visible; return moved back to kingdom. |
| 38–40: Two simultaneous players and cross-player interactions | **NOT RUN as a two-client session**. Foreign pet/claim/recall UIDs and forged price fields were rejected in the actual server. Full two-client visual/assignment testing remains outstanding. |
| 41–44: Leave active, rejoin, timestamp catch-up, rebuild | **PASS in serialized mock rejoin**. Same TripId and Slot 3; cycles 12 → 24; basket exactly matched independent offline calculation; physical pet rebuilt. |
| 45–47: Stop, Play again, profile loads | **PASS**. Repeated fresh joins reached Ready without the data-preparation kick; mock session release logged. |
| Claim All | **PASS**. Two completed actual 60-second trips paid 57 Harvest, then second Claim All rejected. Final full-stack three-trip Claim All paid 104 Harvest; controller A dismissed its correctly focused breakdown. |
| All supplies/upgrades, caps | **PASS** in actual Play. Eight purchases and every upgrade level; over-max purchases rejected. |
| Mobile and controller | **Phone-width Play layout and A: PASS**. Physical phone/Xbox hardware and reserved B injection: not verified. |
| Regression checks/build | **PASS**. Rojo build, Luau compilation, additive/idempotent migration, invalid-value recovery, expiry-boundary online/offline parity, duration progression, boost caps and regrowth spacing. |

Read `session-1.json`, `session-2.json`, `session-3-ui.json`, `session-4.json`, `session-5-vfx.json`, `progress-regression-tests.json` and `final-play-output.txt` for recorded evidence. The final effects-only pass confirmed ReadyGlow enabled, ready particles at 0.5/second, Starberry sparkle at 0.3/second and Moonmelon light brightness 0.12 (`ready-final.png`). It used a backdated disposable mock trip to inspect these effects; the preceding completion/claim tests waited real 60-second durations.

## O. Save/rejoin results

No test purchased against or wrote to live player data. All gameplay tests used the existing Studio mock profile mode. One mock profile was serialized, then temporarily fed through the existing loader in the next actual Play session. This exercised reconciliation, migration, Ready, offline progress and visual reconstruction without a new datastore or live save. The temporary hook and fixture were then removed; subsequent joins used the normal read-only production snapshot path.

The full live stored envelope was compared before/after and was identical, with no differing fields. Coins remained **671,917**, Friendship Tokens **34**, and saved Harvest **223**. All pets, levels, mutations, index, biome unlocks, Sanctuary, cosmetics and Garden data were preserved. See `saved-data-preservation.json`.

Source changes are saved in the Rojo project. A local Studio copy is saved beside this report as `AnimalKingdom-Garden-Gameplay-20260922-Final.rbxl`. It was created with **Download a Copy**, not publishing. Studio is left in Edit mode. Runtime audit scripts and mock test rewards disappear when Play stops.

## P. Remaining issues / limits

- Two simultaneous clients were not exercised. Owner isolation, foreign-ID rejection and matching-slot logic were checked, but full multiplayer presentation remains unverified.
- Controller A and selection flows passed. Studio refused to inject the reserved B key. B is implemented; a real controller Back test remains outstanding.
- Mobile checks used a phone-width Garden panel in actual Studio Play; no physical phone test was performed.
- Pets without a valid canonical real model are intentionally unavailable for Garden. The pre-existing missing Honey Lop template and placeholder-only legacy pets were not replaced with fake pets. Their saved ownership remains intact.
- No live persistent-write test was performed. The mock serialization/rejoin path and exact live-data preservation comparison were used to respect the data-safety constraint.
- Existing Superbullet localhost logging warnings still appear because that external backend is unavailable; they did not block profile readiness or Garden actions.
- No known Garden gameplay failure remains in the completed single-player tests. This report does **not** claim “100% working” across untested hardware or multiplayer conditions.
