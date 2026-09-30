# Pet ownership, weight, Held Pets, Sanctuary swaps and selling

September 23, 2026. Target: **132313449035787 / 10764288431**, Animal Kingdom testing place. **Not published. Studio is in Edit; original camera restored; device simulation stopped.**

The new ownership loop is implemented in the existing canonical pet architecture. Actual Studio tests covered paid tree rewards, individual weight, real-model showcase, five Held destinations then Inventory, swaps, Garden exclusion/return, weighted Sanctuary income, protected selling and save/read persistence. Phone layouts were inspected and revised. Two-client launch and physical-controller coverage remain limited as described below; this is not a claim that every production/platform acceptance test passed.

## A. Pet data schema

The existing `Pets` array remains authoritative; `OwnedPets` is its compatibility alias. `PetId` identifies a species; existing `UID` / `UniquePetId` identify the same owned copy. No new ownership datastore, duplicate pet record or saved Roblox instance was introduced.

Each owned record retains Level, XP, Mutation, Shiny, Prismatic, Favorite, Locked, Cosmetic and acquisition data; it now includes `Weight`, `Location`, `LocationSlot`, and server-derived `CoinsPerSecond`, `SellValue`, `WeightQuality`. Authoritative locations are `Held`, `Inventory`, `Sanctuary`, `Garden`. Derived UID arrays support existing renderers: `HeldPetSlots`, `SanctuaryPetSlots`, `EquippedPets`, `DisplayedPetIds`.

## B. Weight roll algorithm

`PetWeightDefinitions.lua` and `PetWeight.lua` separate physical/statistical Weight from species `DropWeight`. The server chooses the species first, then its individual weight. Default maximum is **3× BaseWeight**. Conditional bands:

| Ratio | Probability at ordinary luck |
|---|---:|
| 1.00–1.15 | 80% |
| 1.15–1.35 | 15% |
| 1.35–1.75 | 4% |
| 1.75–3.00 | 1% |

Within a band, squared uniform sampling favors its lower end. Values are rounded to .01 kg and clamped to BaseWeight / configured maximum. Legitimate server luck modestly increases tail selection; its influence is capped, with the extreme band about 1.52% at the maximum applied advantage. Invalid legacy values normalize to BaseWeight. No weight or species input is accepted from a client.

## C. BaseWeight definitions

Gameplay kilograms are authored independently of mesh mass or triangle count. Current real Meadow/Forest species:

| PetTypeId (existing `PetId`) | Base kg |
|---|---:|
| `ForestBadger` | 12 |
| `ForestBlackBearCub` | 18 |
| `ForestBrownBat` | 0.3 |
| `ForestCrestedOwl` | 2.4 |
| `ForestEmeraldWing` | 40 |
| `ForestLeafAntler` | 70 |
| `ForestRaccoon` | 6 |
| `ForestRiverOtter` | 9 |
| `ForestSkunk` | 3 |
| `ForestTreeFrog` | 0.2 |
| `ForestWoodlandOwl` | 1.5 |
| `MeadowBlossomBunny` | 3.5 |
| `MeadowBuck` | 55 |
| `MeadowCelestialLamb` | 12 |
| `MeadowChick` | 0.4 |
| `MeadowCloudtailFox` | 7 |
| `MeadowDaisyCrownBunny` | 3.2 |
| `MeadowDaisyHedgehog` | 1.2 |
| `MeadowFawn` | 14 |
| `MeadowFieldMouse` | 0.1 |
| `MeadowFluffyLop` | 2.8 |
| `MeadowGoat` | 18 |
| `MeadowPatchworkLop` | 3 |
| `MeadowPrismAntlerDeer` | 70 |
| `MeadowRedSquirrel` | 0.5 |

Retired Honey Lop keeps 2.2 kg; older named Bunny/Dog/Deer/GoldenFox receive 2.5/12/55/7 kg. Anonymous unimported catalog entries have a 5 kg compatibility default, not an invented animal identity. Give future imported species an explicit BaseWeight when registering them.

## D. Weight → income

`PetStats.Income`: **base species income × (Weight / BaseWeight)^0.75**, rounded to two decimals. It equals base income at base weight and never reduces it. Three times base weight produces about **2.28× income**. Existing species progression remains intact; this pass does not add new mutation/level income bonuses.

Only Sanctuary-located owned instances contribute to passive income. Held labels show potential income. Server `SanctuaryIncomePerSecond` is published to management UI. Accrual happens before moving/swapping displayed pets so prior time is attributed correctly. The existing collect/offline/weather modifier architecture is preserved.

Verified 12 kg / 24 kg Badgers: **18.00 + 30.27 = 48.27 coins/sec**. Raising a Held pet's weight did not change this total.

## E. Weight → clone scale

**clamp(ratio^0.35, 1, 1.6)** after canonical context normalization. Ratios 1, 1.25, 1.5, 2, 3 yield approximately **1, 1.081, 1.152, 1.275, 1.469**. Source models are never scaled.

Sanctuary fitting uses 78% of the existing safe slot bounds at base weight, grows with individual weight, and caps at the slot's safe bounds. Income/weight values remain unchanged when a physical fit caps. Placement recomputes bounds and maintains approximately .04 studs of shelf clearance. Preview/reveal cameras use a common species reference envelope so increasing weight remains visibly larger instead of being cancelled by camera zoom.

## F. Held Pets architecture

Exactly **five** Held slots on every device. New committed rewards fill the first empty slot; otherwise they enter Inventory. Held slots drive the existing equipped/follower group. Existing extra equipped pets are retained in Inventory during migration, after preserving Garden and Sanctuary placement priority.

The previous equipped-slot upgrade is retired from purchasing/rendering. Saved upgrade levels and prior equipped settings remain preserved, with migration recovery metadata. A new Held HUD bar uses real model previews and shows name, rarity, weight and potential income. Desktop cards have more preview space; phone cards fit between touch controls. No separate ownership store exists.

## G. Normal Inventory integration

Inventory filters: Inventory, Held, Sanctuary, Garden, All, Favorite, Locked; canonical rarity filters and name/mutation search. Sorts: Rarity, Weight, Coins/sec, Sell Value, Newest, Name. Details show authoritative weight, income, sale value, current location and level; desktop details include mutation/variant/XP information.

Moves are server-owned, capacity-checked and exclusive. Garden reserves a normal storage space for the return trip, preventing a claim from stranding a pet. Both Held and Inventory full blocks tree charging. Retained saved auto-delete preferences no longer discard new companions; Settings explains the new keep-and-sell flow.

## H. SellValue formula

`SellValueCalculator` centralizes:

**BaseSellValue × rarity factor × ratio^0.8 × [1 + .02 × (level−1)] × existing mutation Power × shiny 1.5 × prismatic 2**.

Default BaseSellValue is four seconds of species base income. Rarity factors: Common 1; Uncommon 1.1; Rare 1.25; Epic 1.45; Legendary 1.75; Mythical 2; Secret 2.2. Whole-coin rounding can make tiny weight differences share a price; larger weights increase value monotonically.

The initial 12-second default made late Forest resale too generous. It was reduced and resimulated with existing ordinary mutation/Shiny/Prismatic probabilities. Each active tree received 10,000 virtual samples:

| Tree | Search price | Average resale | Price recovered |
|---|---:|---:|---:|
| `Forest_Shakeable_01` | 750 | 50.52 | 6.7% |
| `Forest_Shakeable_02` | 750 | 83.27 | 11.1% |
| `Forest_Shakeable_03` | 750 | 143.50 | 19.1% |
| `Forest_Shakeable_04` | 750 | 270.51 | 36.1% |
| `Forest_Shakeable_05` | 750 | 487.45 | 65.0% |
| `Meadow_Shakeable_01` | 250 | 5.17 | 2.1% |
| `Meadow_Shakeable_02` | 250 | 9.62 | 3.8% |
| `Meadow_Shakeable_03` | 250 | 18.57 | 7.4% |
| `Meadow_Shakeable_04` | 250 | 32.07 | 12.8% |
| `Meadow_Shakeable_05` | 250 | 59.01 | 23.6% |

These figures cover pet resale, **excluding the game's existing secondary gathering drops, bonuses and weather rewards**. Rare high-weight/variant individuals can legitimately sell above their search price.

## I. Sell All protections

Both individual and bulk sales use a server quote with count, exact total, eligible UID signature and a 30-second one-use token. Confirmation is mandatory. Favorites, locked pets, Held/equipped, Sanctuary, Garden and unavailable definitions are excluded. The server recalculates eligibility and price at execution; changed protection, location, value or expired/replayed tokens reject the sale.

Removal and coin credit commit synchronously under the shared pet transaction lock before publishing. No client list, price or total is trusted. Coin-balance overflow refuses the sale. Species discovery remains; current ownership count updates. Twelve repeated sale attempts did not duplicate payment. A real phone Sell All confirmation removed one eligible pet and credited exactly 15 Forest Coins.

## J. Sanctuary swap system

The owner receives a **MANAGE SANCTUARY** proximity prompt, plus Inventory/Plot management entry points. Actual display capacity is discovered from current slot anchors (64 here), including asynchronous plot assignment. Phone management uses tap selection; desktop/tablet expose the Held row and paginated display grid.

A swap validates player ownership, distance to their own plot, slot bounds, current expected UIDs and canonical model availability. Empty-slot transfers, direct swaps and moves to Inventory preserve the same owned instances. Stale repeated swaps reject instead of swapping back. Garden pets cannot be moved until claimed/recalled. The old visible display geometry is unchanged.

Actual phone swap: **27 kg Otter ↔ 12 kg Badger**, with the expected Held/display locations and identical owned IDs afterward. The server total changed to **94.10/sec** for the resulting displayed pair. Prompt cleanup handles leaving/reassignment; no old player's prompt callback is reused.

## K. Overhead labels and real-model presentation

`PetLabel` attaches name, formatted kg and potential coins/sec above measured visible bounds, including antlers/ears/wings. Rarity provides a restrained border/name accent. The existing centralized follower and Sanctuary managers reveal the nearest relevant label at close range to avoid walls of text. No per-pet RenderStepped connection was introduced.

All contexts continue through the canonical resolver and preserve authored meshes/textures/SurfaceAppearance. Followers keep the established bounds-based spacing and interpolation; their rendered bounds now include weight. Garden visuals carry the same individual weight/income fields. Index remains species-based.

## L. Existing-pet migration and persistence

Global profile schema **4**, individual pet schema **1**. Missing weight receives BaseWeight once, not a new roll on every join. Valid existing weight persists. Garden takes location precedence, then previous Sanctuary order, then up to five formerly equipped pets. Remaining pets go to Inventory; legacy capacity is expanded if necessary to preserve owned pets and Garden return reservations.

Migration tests preserved eight legacy UIDs, existing individual weight, display state, currencies and levels through repeated migration/JSON reload. A separate actual **existing ProfileStore.Mock Save → Mock:GetAsync → migration** test preserved weight and locations for 40 owned records. No new datastore was created; **OriginalData1** remains the sole existing store. All grants, sales and forced tests used Studio mock snapshots. Live saved profiles were read only.

## M. Mobile / tablet

Inspected iPhone 17 Pro landscape, portrait as an additional layout check, and iPad Pro 11-inch landscape. The game's existing LandscapeSensor preference was restored. Revisions addressed Held/right-control overlap, excessive inventory toolbar height, cropped initial card stats and Sanctuary selection flow. Phone inventory uses wide cards; larger screens use the responsive grid. Confirmations fit the safe viewport and use large buttons. No drag/drop is required.

Screenshots: [phone Held](screenshots/phone-held-v2.png), [phone Inventory](screenshots/phone-pets-v2.png), [phone details](screenshots/phone-details-final.png), [choose Held](screenshots/phone-sanctuary-held-final.png), [choose display](screenshots/phone-sanctuary-displays-final.png), [swap confirmation](screenshots/phone-swap-confirm.png), [sale confirmation](screenshots/phone-sale-confirm.png), [portrait](screenshots/phone-portrait-held.png), [iPad management](screenshots/ipad-sanctuary.png).

## N. Controller

Xbox emulator checks passed for five selectable Held cards, directional selection links, visible focus, inventory actions, Sell All confirmation focus containment and Sanctuary slot selection. The Held bar was added to the main HUD navigation graph. Existing **ButtonB back** binding remains at priority 2100. Virtual ButtonA injection returned success; **ButtonB injection was rejected by Studio's CoreGui restriction**. No physical Xbox controller was available, so hardware A/B behavior is not claimed verified.

[Controller evidence](controller-playtest.json), [Held focus](screenshots/xbox-held-focus.png), [sale modal](screenshots/xbox-sale-confirm.png), [Sanctuary focus](screenshots/xbox-sanctuary-focus.png).

## O. Statistical weight simulation

**60,000 virtual weight rolls**, six representative species, 10,000 each; **60,388 assertions** including migration and resale checks. Minimum never fell below base, no roll exceeded its configured ceiling, and each successive tail band was less frequent.

| Species | <1.15× | 1.15–1.35× | 1.35–1.75× | ≥1.75× | Mean income factor |
|---|---:|---:|---:|---:|---:|
| `ForestBlackBearCub` | 79.55% | 14.83% | 4.64% | 0.98% | 1.0765× |
| `ForestBrownBat` | 78.89% | 15.76% | 4.24% | 1.11% | 1.0774× |
| `ForestEmeraldWing` | 80.11% | 15.08% | 3.96% | 0.85% | 1.0741× |
| `MeadowFieldMouse` | 79.56% | 15.33% | 4.07% | 1.04% | 1.0719× |
| `MeadowFluffyLop` | 79.75% | 15.51% | 3.91% | 0.83% | 1.0731× |
| `MeadowPrismAntlerDeer` | 79.84% | 15.04% | 4.12% | 1.00% | 1.0750× |

Another **100,000 virtual resale samples** covered all active Meadow/Forest pools. Raw evidence: [weight and economy simulation](weight-simulation.json).

## P. Play-test results

- **102 ownership-loop assertions**, repeated after integration changes: six physical tree rewards, first five Held destinations, sixth Inventory; repeated searches; full storage no-charge; swaps; empty slots; Garden send/claim; income; bulk sale; protected pets; stale quotes; foreign UID rejection; save roundtrip.
- **336 size/display assertions** across mouse, bunny, antler deer, bear cub, bat and winged guardian at 1×, 1.25×, 1.5×, 2×, 3× weights. Follower/preview/Garden scaling increased; source pivots/scales stayed unchanged. Thirty comparison pets plus two existing displays rendered without floor penetration; fitted size plateaued safely at slot limits. [Size results](size-final.json), [visual review](screenshots/sanctuary-weight-matrix-final.png).
- Native phone swap and sale passed; crafted client Weight, CoinsPerSecond, SellValue and PetId fields were rejected without changing owned stats.
- A Studio-only, temporary deterministic test forced a **96 kg Secret Emerald-Wing Guardian**. The reveal displayed **MASSIVE! / +173.54 per sec / SENT TO PET INVENTORY**, preserved textures, rotated its clone, and View Pet opened the exact UID. Camera remained Custom with the current Humanoid. This temporary override was not written into production source. [Reveal](screenshots/massive-reveal.png), [same inventory instance](screenshots/massive-inventory-details.png), [client assertions](reveal-client-playtest.json).
- Performance snapshot with 32 Sanctuary pets: five followers; **5 live / 5 registered HUD previews** of budget 24, with menu previews cleared. One existing centralized renderer per visual system remains. This machine's Studio sample averaged **66.67 ms** per frame (about 15 fps), p95 **68.40 ms**, reported memory **5418 MB**. This is a limited Studio/window/emulator measurement, not a claimed target-device frame-rate pass. The environment/world needs a dedicated hardware performance pass before a release claim.
- **Two-player test did not execute:** StudioTestService launched a child server that failed to open `StartServer` with an iostream file error. No two-client correctness claim is made for this pass. Temporary test harnesses were removed. [Failure record](multiplayer-playtest.json).
- **178 source files compiled**, zero failures; **40 changed/new mapped sources exactly match Edit Studio**. No source files deleted. The right HUD replacement component and all weather sources match their pre-pass hashes. No changes to canonical imported models, world geometry, saved profile store, or publishing state.

## Q. Remaining balance / verification concerns

1. Two-player isolation needs rerunning when Studio's child-server launcher works. Single-player ownership/security checks passed, but they do not replace that test.
2. Physical-controller A/B and real mobile/tablet hardware remain untested. Emulator layouts/focus and native phone pointer interactions were verified.
3. Weight adds about 7–8% average base income at ordinary luck; monitor long-term currency generation, existing gathering drops, weather multipliers and high-level variant resale together. Current simulations do not model a whole-season economy.
4. Performance on this Studio machine is not a release-quality FPS result. High-poly imported assets, the existing world and five persistent HUD previews should be profiled on actual target hardware before publishing.
5. Anonymous future/unimported species need sensible explicit BaseWeight entries when registered. Existing unrelated catalog warnings for unimported later-biome models remain outside this pet-system pass.
6. The persistence test used the existing mock store, not a published live-server rejoin; live data was intentionally preserved.

Implementation entry points: `PetWeightDefinitions`, `PetWeight`, `PetStats`, `PetLocations`, `SellValueCalculator`, `PetService`, `OwnedPetCards`, `HeldPetsBar`, `PetOwnershipMenus`, `SanctuaryMenus`, `PetLabel`. Tests live under `tests/Pet*.studio.*.lua` outside the Rojo mapping; test runners additionally require Studio and mock profiles.

Final state: **Edit mode, correct place, original viewport restored, device simulation stopped, zero temporary QA instances, not published.** See [source validation](source-validation.json) and [Studio verification](studio-final-verification.json).
