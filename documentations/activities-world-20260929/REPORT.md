Implemented the expansion in the connected Animal Kingdom testing place (132313449035787) and its mapped source. All nineteen feature areas have implementations. Release validation remains PARTIAL: actual two-client sessions, durable cross-server delivery, and controller hardware/input could not be verified. Nothing was published.

The source checkpoint and evidence here belong to the current build, after the normal-tree economy pass. There is no Git repository in this project; source changes were compared against the 652-file starting SHA-256 manifest. The expansion adds 11 Lua files, changes 32 Lua files, deletes none, and changes/adds no asset files. Original and staged checkpoints remain in `checkpoints/`. Studio is left in Edit mode, mock profiles enabled, with device simulation stopped.

“IMPLEMENTED + TESTED” below means the stated evidence passed, not that every device, disconnect, and long-term economy case is proven. “PARTIAL” identifies implemented features whose essential multiplayer/durability or complete player-input validation remains outstanding.

| Feature | Status | Evidence and limits |
|---|---|---|
| A1 Tree Rush | PARTIAL | Real normal-search transactions, one pet/charge, targets, timer, reward receipt, retarget and timeout pass. Full five-target route walked through client input has not been completed; route suites use scripted movement. |
| A2 Hidden Pawprint Hunts | IMPLEMENTED + TESTED | Six ordered proximity/run checks; wrong/repeated markers rejected; free completion at zero coins; paid finale preserves one-use benefit on failure. Actual E input advanced one marker and retained one arrow. |
| A3 Six Rush variants | IMPLEMENTED + TESTED | Speed, Tour, Heavy, Rarity, Different Species and No Repeat all complete through real search commits. RNG outcomes were controlled in these tests; final Heavy tuning separately passes 13 assertions. |
| A4 Biome Adventures | IMPLEMENTED + TESTED | Three-step route completes with actual searches, eligible held pet and successful Sanctuary placement; required slot/capacity checks. Scripted movement. |
| A5 Pet Missions | IMPLEMENTED + TESTED | Exact UID search mission, XP/claim replay and held-UID switch during search pass. Garden/visit/displayed-income event fixtures pass; real Garden settlement also verified separately. |
| A6 Biome Goals HUD | IMPLEMENTED + TESTED | Same daily goal IDs/progress/claim state in HUD and Activities; cap-safe claim; portrait/landscape review. |
| A7 Five Hot Trees | IMPLEMENTED + TESTED | All five real search effects measured; expiry after acceptance preserves snapshot; 12/20-second restoration and tree pose checked. |
| A8 Cooperative Kingdom Goals | PARTIAL | Two simulated contributors, independent receipts, minimum contribution, mock inbox delivery/retry and session restoration pass. Actual two-client/disconnect/cross-server delivery is BLOCKED. |
| A9 Server-session records | IMPLEMENTED + TESTED | Canonical acquisition records and current versus peak Sanctuary rates exercised in mock Play; no global leaderboard datastore. |
| A10 Daily Kingdom Journey | IMPLEMENTED + TESTED | Four gameplay steps and final claim; 28-assertion final migration suite retains old Daily and stale Weekly progress/rewards exactly once. |
| A11 Tree-family mastery | IMPLEMENTED + TESTED | Stable family counters, discoveries, weight record, rank caps, separate actual searches/mastery points, normalized family-only odds tested. Existing Index source details extended. |
| A12 Lucky presentation | IMPLEMENTED + TESTED | Actual Forest event/pulse/shared notice, single model and personal counter; both biomes' three free attempts/rewards regression passes. |
| B1 Kingdom Shop | PARTIAL | All six offers/effects, distance, price, replay, limits, active-effect rejection, expiry, actual fertilized trip and Blessing accrual pass. Actual durable cross-server/reconnect failure matrix remains BLOCKED. |
| B2 Shared announcements | IMPLEMENTED + TESTED | One queue; duplicate ID/reveal suspension/resume verified; restock observed. |
| B3 Living trees/search effects | IMPLEMENTED + TESTED | Distance-limited lights/particles, committed burst, reduced-motion cleanup; search/cooldown pose restoration verified. No ambient tree CFrame changes. |
| B4 Meadow/Forest ambience | IMPLEMENTED + TESTED | Client pollen/petals/leaves/fireflies/mist; weather and reduced-motion rates measured at zero. Existing materials/textures only. |
| B5 Physical Town shortcuts | IMPLEMENTED + TESTED | All five locations pathfind reachable; actually walked between Town prompts and opened the same Activities/Shop/Index/Biomes routes; Garden action arrived successfully. |
| B6 Cosmetic micro-events | IMPLEMENTED + TESTED | Three configured moments, one coordinator slot; local effects measured under simulated event state, yield to major weather; no rewards. |
| B7 Other-player accomplishments | IMPLEMENTED + TESTED | Shared canonical record/acquisition/mastery messages and coalescing exercised with mock events. Actual second-client reception remains BLOCKED with the multiplayer matrix. |

The first Hot test artifact has `Passed=false`: all five Hot searches had already passed before an unrelated mission fixture tried an invalid placement. It is deliberately retained, together with the corrected 38-assertion missions/cooperation continuation. This is segmented evidence, not a claim that the failed whole run passed.

Menu and Town entry map

| Existing route | Final presentation | Physical entry |
|---|---|---|
| Challenges; Activities alias | Activities → Play / Goals / Records | Existing Rewards board: VIEW ACTIVITIES |
| Shop; KingdomShop alias | Kingdom Shop → Boosts / Furniture / My Decorations | Existing General Store: BROWSE SHOP |
| Index | Existing collection and tree/source details, family mastery | Existing MarketStand1: VIEW INDEX |
| Biomes | Existing travel and biome mastery; Lucky destination pulse | Existing TownWelcomeSign: VIEW BIOMES |
| Existing Garden action | Existing Garden destination and Garden Shop | Existing MarketStand2 near Garden approach: VISIT GARDEN |

No new primary tabs were added. The old Challenges renderer delegates to Activities. Redundant Daily presentation becomes Journey plus retained claimable legacy rewards; Weekly and Contracts remain within Goals. Internal route aliases remain compatible. Held SELL HELD PET and STORE PET remain.

Shop stock can be inspected remotely; purchases, including furniture bought through this Kingdom Shop, require server-validated distance within 16 studs of the actual General Store anchor. Other menus keep their own rules. No existing Town teleport route was found, so the instruction is to walk to the store; no new teleport screen was invented. Prompts use existing touch/controller-capable infrastructure. All five new entry anchors are tiny invisible noncolliding technical parts outside existing landmarks.

Activities and scheduling

ChallengeService owns the coordinator and existing profile fields. Successful awarded searches, actual active held UID at commit, valid placement, actual Sanctuary credit, settled Garden trip and verified arrival drive progress. Search award identity prevents replay credit. Activity coin payouts do not recurse into collection objectives. No new pet ownership, currency, datastore, Garden system or Sanctuary accumulator exists.

| System | Final defaults |
|---|---|
| Public invitation | First after 90 seconds with eligible players; every 240 seconds; 180-second invitation; alternate Paw/Rush |
| Guided personal route | At most one accepted Rush, Paw or Adventure; never replaced by a new invitation |
| Speed Search | Five different copies of the cheapest reachable family; 120 seconds |
| Tree Tour | Five real named families in order; 180 seconds |
| Heavy Hunt | One pet ≥1.35× BaseWeight; 240 seconds; affordability checked against twelve searches |
| Rarity Hunt | Rare+; 240 seconds; eight-search affordability check; only supporting pools |
| Different Species | Three canonical species; 240 seconds; guides three distinct dedicated pools |
| No Repeat | Four different families; 180 seconds |
| Paw Hunt | Six markers; 360 seconds; 600-second personal cooldown; free basic trail |
| Adventure | Three steps; 1,800 seconds; once per biome per daily bucket |
| Hot Tree | First after 90 seconds; one per server, every 300 seconds, lasts 120 seconds; cycles five effects |
| Cooperative goal | One 900-second goal; target frozen for 1–12 eligible players at start |
| Cosmetic moment | Every 420 seconds when eligible and clear; Meadow breeze 30 seconds, Forest fireflies 60, restless Forest 30 |
| Shop | Shared UTC 600-second rotations; deterministic visible Mystery choice |
| Existing Lucky/weather | Schedules preserved; micro-events yield to major weather and Lucky presentation |

Route construction uses real family prices, live available copies, pathfinding and a travel/search time allowance. A route is rejected when cost/capacity/path constraints cannot be met. Basic Paw Hunts remain free. Selected missing/unavailable trees are re-resolved to equivalent copies without erasing progress. No auto-spend, teleport or camera movement is introduced. Tutorial guidance wins; reveal/menu/death suspend activity guidance.

Rush completion pays 10% of the displayed search budget, capped at 750 coins, plus two Tokens. Paw pays 50 Meadow / 150 Forest coins plus one Token; an occasional optional seventh-step tree finale charges the normal price and snapshots +0.10 higher-band weight bias into its successful search. Adventure pays 300/1,000 coins and three Tokens. The three daily biome goals pay 200/800 and two Tokens once per set. Journey pays 300 and five Tokens. Mission reward is 100 existing XP on the exact UID, respecting level cap and one mission per pet per daily bucket.

Cooperative variants target searches, Rare+, heavy finds, actual collected coins, completed expeditions or family variety. Per-player scaled targets are 12 searches, 2 Rare+, 2 heavy finds, 1,000 collected coins or 1 expedition; variety is bounded by available families. Minimum contribution is respectively 2, 1, 1, 100, 1, or one family. Qualified contributors each receive their own pending 200 coins/three Tokens reward. Disconnect does not remove their in-memory contribution. The existing ProfileStore message inbox transports earned claims; pending claims are capped at 32 and currency-cap failures leave claims available. Transport retries every ten seconds and shutdown flush is bounded. Server/API failure before durable inbox acceptance remains a validation risk.

Tree mastery uses actual recorded searches from this update onward; no invented history. Ranks at 5/15/35/70/120 points add 1% normal Luck per rank for that family, maximum 5%. Hot Mastery adds a point while the displayed actual search count increments once. Existing biome mastery is separate and retained.

Shop tuning and modifier rules

| Offer | Exact price | Effect and duration | Limit |
|---|---:|---|---|
| Lucky Clover | 250 Forest Coins | ×1.10 normal-search Luck, 300 seconds; normalized odds, not percentage points | 1 per rotation |
| Heavy Charm | 250 Forest Coins | +0.15 higher-weight-band bias, 300 seconds; only new rolls | 1 per rotation |
| Search Charm | 100 Forest Coins | Personal post-reveal recovery 1.5 → 1.05 seconds for 300 seconds; shared tree regrowth unchanged | 1 per rotation |
| Sanctuary Blessing | 20 Friendship Tokens | +15% newly accrued Sanctuary income for 600 seconds, through the existing weather/offline integration | 1 per rotation |
| Garden Fertilizer | 8 Friendship Tokens | +15% Harvest on next successfully started expedition; trip snapshot, no bonus XP | 1 pending use |
| Mystery Deal | 75% of selected offer price, rounded down | One of the five named effects is visible before buying; same duration/entitlement | 1 per rotation |

Mystery prices are 187 Coins for Clover/Heavy, 75 Coins for Search, 15 Tokens for Blessing, or 6 Tokens for Fertilizer. UI shows actual original and discounted price (the 250→187 rounding is a 25.2% discount).

Buying an already-active underlying effect is rejected without spending; no refresh or extension. Mystery cannot create a duplicate stack. Compatible different effects combine. Rotation counts and request receipts persist in the existing profile across servers, retaining 144 rotations. Reusing a request ID reconciles its old receipt even when the supplied current rotation changed. Stale new purchases reject. Garden fertilizer is consumed only after valid trip start and remains pending on rejection.

The ordered normal-search pipeline retains permanent upgrades, weather, existing streak and Lucky boosts, then applies scoped Shop/family/Hot effects once. New scoped Luck factors are capped at ×1.5 combined. Weight biases add and cap at 0.40. Personal recovery has a 0.75-second floor. Accepted searches snapshot all temporary effects; expiry cannot change that accepted reward or charge twice. Hot effects are +0.15 weight bias, ×1.15 scoped Luck, 10% price bonus capped at 250 coins, this tree's 12-second regrowth, or +1 biome/family mastery point. Other trees retain 20-second regrowth.

Index and the sampler use the same normalized NormalTreeOdds with published family and current Hot-copy contexts. Special Lucky category odds do not enter this pipeline.

Economy calculations and pacing

Exact calculations are in `economy-calculations.json`; these are calculations, not thousands of live searches. At neutral Luck, Blossombark Common/Rare/Legendary odds are 81.001473% / 17.673049% / 1.325479%. Clover makes them 80.040414% / 18.491132% / 1.468454%. Clover + five family ranks + Hot Lucky gives 78.021457% / 20.183687% / 1.794856% (×1.32825 Luck).

Neutral mean unrounded weight ratio is 1.1035; Heavy Charm changes it to 1.114942, maximum combined bias to 1.132216. Exact species weight rounding makes the starter-pool ≥1.35× probability 5.0111% neutral, 6.4126% with Heavy Charm, and 8.5285% at maximum bias. The final neutral twelve-search Heavy Hunt success chance is 46.0395%, compared with 21.0887% for the earlier 1.5×/eight-search proposal. Rarity Hunt has about 81.47% chance over eight starter pulls. These remain optional, uncertain objectives, not promised rewards.

The real weakest-starter Play test started at 250 coins, spent exactly 250, awarded one 0.10 kg Field Mouse, placed it for free, accrued at 2.5/sec, and collected 250 after 100.179 seconds. The tutorial completed after this first pet's collection and the recovered money funded another search. The 1:40 initial pause is noticeable; no subsidy or Lucky payout was used to hide it.

| Fixed displayed Sanctuary example | Base coins/sec | Ten-minute income | Twenty-minute income |
|---|---:|---:|---:|
| One weakest starter | 2.5 | 1,500 | 3,000 |
| Five weakest starters | 12.5 | 7,500 | 15,000 |
| Developed Meadow, ten pets | 81 | 48,600 | 97,200 |
| Those Meadow pets plus two Raccoons | 125 | 75,000 | 150,000 |
| Developed Forest, fifteen typical pets | 783 | 469,800 | 939,600 |

These examples use base weights, no temporary boosts, no coin claims, and a fixed roster. They do not assume a full 70-slot stand or simulate acquiring the displayed roster instantly. At 81/sec the unchanged 2,500 Forest unlock plus 6,000 first Forest search takes 104.94 seconds of income. At 125/sec Fernwood takes 80 seconds. At 783/sec Mooncap takes 63.86 seconds. Entering Forest with only five starter pets still leaves an eight-minute first-search wait; building a stronger Meadow Sanctuary matters.

A ten-minute Blessing adds 225 / 1,125 / 7,290 / 11,250 / 70,470 coins to those respective setups. It costs Tokens, affects only newly accrued Sanctuary income and never multiplies collection or saved balance.

Illustrative twenty-minute developed-Meadow activity budget: four Speed routes cost 5,000 coins and return 500; two free Paw completions return 100; a separately completed two-search Adventure costs at least 500 and returns 300; daily biome/Journey claims add 200+300; up to two fast cooperative completions add 400. That is 1,800 new activity coins against at least 5,500 paid-search cost, plus Sanctuary earnings and ordinary pet acquisitions. It assumes sufficient travel time, Garden eligibility and Journey rarity success; it is an upper-choice scenario, not a measured continuous session. At ten minutes, one set of daily/Adventure claims is still bounded and cannot repeat as an infinite grant. A free repeatable trail alone pays at most 100 Meadow / 300 Forest coins over twenty minutes from an immediately available first trail.

Existing Contracts, biome mastery, Weekly and Lucky rewards were not nerfed. Existing price-based contracts can return one or two family search prices; only the existing three active contracts progress. Meadow mastery milestones retain 500/1,375/3,125 rewards; Forest retains 12,000/33,000/75,000. Existing Weekly milestones can pay 25,000–50,000 coins and 300 Tokens, creating much larger occasional steps than the new activities. Retained old claimable rewards also remain payable once. These existing rewards and occasional 5,000/20,000 Lucky payouts are excluded from the recurring baseline and need observation in longer sessions. Ordinary paid searches still grant one pet; the previously removed exploitable legacy gathering rebate remains removed.

Save and ownership behavior

Changes are additive within the existing ProfileService/ProfileTemplate lifecycle. Existing UIDs, weights, BaseWeights, XP, mutation, flags, ownership/location, Items, purchases, saved placements, contracts and biome mastery are retained. Derived income still uses PetStats and PetService publication. Accumulated UncollectedSanctuaryCoins are preserved; Blessing divides accrual intervals across start/expiry and placement changes instead of multiplying saved money.

Old partial or claimable Daily progress is retained separately once. Stale pre-migration Weekly progress is retained once; current-week entries remain in their existing ledger, avoiding duplicate payout. Claimed legacy entries remain claimed. Journey and biome sets use the existing daily bucket. Completed unclaimed rollover rewards move to bounded pending claims; a full pending queue retains the completed set. Exact grant semantics reject currency-cap loss. Pet missions invalidate safely when their UID ceases to be owned.

Death suspends guidance without granting or erasing pets. Abandonment/timeout removes the uncompleted route and its guidance, retaining normal rewards. Rejoin/server change restores serialized route IDs, deadlines, goals, missions, boosts, entitlement and receipt state; world Instances are resolved afresh. Expired deadlines are settled on the existing lifecycle. Server records and shared event instances stay session-only. Purchases with interrupted responses retain their request ID and reconcile receipts; no client-side ownership grant or automatic duplicate buy occurs. Co-op inbox receipts are deduplicated and pending claims survive delivery even if collection is delayed.

Presentation and performance

The existing announcement queue now handles Lucky, records, mastery, shop and cosmetic messages. Priority examples: Secret 95, cooperative completion 80, Legendary 65, Shop 45, rate record 35, invitation 10, cosmetic 5. The server sends at most one world message per eight seconds, with Achievement 20-second, rate 90-second, invitation 120-second and cosmetic 240-second category limits. Queues cap at twelve; IDs deduplicate for fifteen minutes. Award IDs coalesce multiple accomplishments from one pull. Client tutorial/reveal/modal suppression defers notices; Lucky waits for its assets. No extra Lucky announcement banner remains.

One compact tracked-objective HUD shows accepted route/progress/timer, otherwise current biome goals, with a shared boost line. A cooperative summary uses spare space when no personal route/boost occupies it. Other opportunities stay inside Activities. Tutorial owns the existing arrow first; personal activities reuse that owner. Phone rotation/rebuild preserves route state.

Tree cosmetics use existing sparkle and smoke textures, Highlights and client-only noncolliding anchors. No tree geometry is pivoted or split for ambient motion. Ready/target pulse and leaf bursts add life while the existing search animation remains the geometry owner. Three nearby highlights, 90-stud effect range, 65-stud labels, four updates/second and a shared continuous twelve-particles/second budget bound cost. Search bursts are 4 anticipation / 12 committed particles, throttled to one burst per 0.25 seconds; lifetime ≤1.3 seconds. Forest mist is 0.25 particles/second with at least 95% transparency and is included in the budget. Reduced motion/low effects clears added particles; major weather disables biome ambience. Micro effects are cosmetic and restore on expiry. Existing water/terrain effects and weather selection/timing are unchanged.

Verification evidence

| Evidence | Result and test type |
|---|---|
| `stage1-test.json` | 113 runtime foundation assertions: additive profile preservation, dedup, modifiers, family caps, Blessing integration, 49 tree snapshots |
| `stage7-migration-passed.json` | 28 final mock assertions: legacy Daily/Weekly, Journey, goals, UID mission, currency cap and serialization |
| `stage3-passed.json` | 182 Play assertions; all six Rush variants, free six-marker hunt and Adventure; real search/placement, scripted movement and controlled new reward RNG |
| `stage7-heavy-tuning-passed.json` | 13 Play assertions on final 1.35×/twelve-budget Heavy variant |
| `stage5-shop-passed.json` | 66 assertions; all six stocks, real 60-second fertilized expedition, measured Blessing expiry/collection, Town pathfinding |
| `stage4-hot-results.json` | All five Hot search results recorded before later mission-fixture failure; do not interpret whole artifact as passing |
| `stage4-missions-coop-passed.json` | Corrected continuation, 38 assertions; missions, records, simulated two contributors, mock inbox/retry |
| `stage7-tutorial-trees-passed.json` | 456 checks; actual first E search/reveal, weakest-pet 100-second accrual, ten families/49 copies, Lucky both biomes, release gates and ownership |
| `stage7-edge-passed.json` | 34 assertions; held UID at commit, capacity, target replacement, timeout, paid Paw finale, actual Mock ProfileStore close/reopen and offline mock inbox |
| `stage6-ui-world-observations.json` | Actual walking/prompt/UI/purchase; observed stock rotation; phone/tablet/desktop review; queue and cosmetic state tests |
| `stage7-final-checks.json` | 173 synced Lua sources compile without syntax errors; five cross-rotation receipt assertions; actual client mist/weather/reduced-motion checks |
| `economy-calculations.json` | Exact weighted odds and rounded weight CDF, fixed-roster pacing; calculations only |

Failures corrected during implementation: an in-flight search was incorrectly retargeted while its tree shook; free Paw candidate filtering mishandled an unspecified family; exact-UID mission credit used accepted rather than committed held state; short landscape Shop/Activities text overlapped; Lucky destination text competed with mastery details; old Weekly progress needed explicit migration preservation; cross-rotation purchase identity needed receipt reconciliation. Test fixture failures were separately corrected to use Equip → SwapSanctuary and Pickup/Store, and to wait for real tree regrowth. They were not bypassed by changing gameplay validation.

The linked flows cover tutorial → first pet → income; all Rush variants and other activity transactions; Town walking → same Shop → purchase → real effect; Garden and Sanctuary; Lucky; and mock session restoration. They were run in controlled separate sessions, not one uninterrupted 32-step player-input playthrough. No legitimate owned UID was lost, duplicated or moved unexpectedly in the before/after fixture audits; intended acquisitions were separately counted and original mock data restored.

Remaining validation blockers and limitations

- Actual two-client Paw/Rush independence, shared goal contribution/rewards, other-player announcement delivery, per-player Shop limits, Sanctuary theft rejection and Lucky attempt independence need a multi-client Studio session. Simulated contributor tests do not substitute for this.
- Durable cross-server ProfileStore persistence, API outage/shutdown during reward acceptance, and real reconnect after network response loss remain unverified. Mock ProfileStore close/reopen and inbox delivery passed, but are not production durability evidence.
- Controller ButtonB injection is BLOCKED by Studio VirtualInput's permanently bound CoreGUI action restriction. Focus/back source was reviewed. Real controller and real touchscreen testing remain outstanding.
- Desktop, small-phone landscape, forced portrait and tablet were visually reviewed; this is device simulation, not hardware performance profiling. Existing LandscapeSensor orientation remains.
- Full walking/touch completion of every timed route and a single continuous 32-step end-to-end session remain outstanding. Pathfinding and real transaction tests establish much of the flow, not travel enjoyment or timer fairness on all devices.
- Console history contains a Superbullet startup diagnostic and unavailable localhost backend notices, plus existing asset-audit warnings (25 released models available out of a planned 330). Released-pool model checks pass. The unrelated console history is not presented as a clean-log result.
- Long-term economy balance is not proven. Monitor the 100-second first recovery, underdeveloped Forest entry, existing large Weekly/mastery rewards, and combined activity/Token spending.

No new 3D assets, models, buildings, imports, downloads, generated images or pet wildlife were added. Existing Town/biome layouts and tree transforms were preserved. Lucky remains one approved biome-specific event tree, three free tries per player, fixed 5% Secret / 40% Coins / 55% Luck, 5,000/20,000 coins and five-minute +35%/+55% boosts. Jungle and later ContentReady gates remain false. Nothing was published.


Exact source files

New Lua files:

- `src/ReplicatedStorage/Shared/Gameplay/Definitions/KingdomActivityDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/KingdomShopDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/KingdomProgress.lua`
- `src/ServerScriptService/ServerSource/Utilities/ActivityCoordinator.lua`
- `src/ServerScriptService/ServerSource/Utilities/ActivityRoutes.lua`
- `src/ServerScriptService/ServerSource/Utilities/KingdomShopStock.lua`
- `src/ServerScriptService/ServerSource/Utilities/KingdomWorldActivities.lua`
- `src/ServerScriptService/ServerSource/Utilities/TownInteractions.lua`
- `src/StarterGui/AnimalKingdomUI/ActivityMenus.lua`
- `src/StarterGui/AnimalKingdomUI/ActivityPresentation.lua`
- `src/StarterGui/AnimalKingdomUI/KingdomShopMenu.lua`

Changed Lua files:

- `src/ReplicatedStorage/Shared/Gameplay/GardenProgress.lua`
- `src/ReplicatedStorage/Shared/Gameplay/PetWeight.lua`
- `src/ReplicatedStorage/SharedSource/Datas/ProfileTemplate.lua`
- `src/ServerScriptService/ServerSource/Server/ChallengeService.lua`
- `src/ServerScriptService/ServerSource/Server/EggService.lua`
- `src/ServerScriptService/ServerSource/Server/GameplayService.lua`
- `src/ServerScriptService/ServerSource/Server/GardenExpeditionService.lua`
- `src/ServerScriptService/ServerSource/Server/LuckyTreeService.lua`
- `src/ServerScriptService/ServerSource/Server/ModifierService.lua`
- `src/ServerScriptService/ServerSource/Server/NotificationService.lua`
- `src/ServerScriptService/ServerSource/Server/PetService.lua`
- `src/ServerScriptService/ServerSource/Server/ProfileService.lua`
- `src/ServerScriptService/ServerSource/Server/ProgressionService.lua`
- `src/ServerScriptService/ServerSource/Server/ResourceService.lua`
- `src/ServerScriptService/ServerSource/Server/SanctuaryService.lua`
- `src/ServerScriptService/ServerSource/Server/ShopService.lua`
- `src/ServerScriptService/ServerSource/Utilities/GameplayRequestPolicy.lua`
- `src/StarterGui/AnimalKingdomUI/AdventureStatus.lua`
- `src/StarterGui/AnimalKingdomUI/AnimalKingdomUIV2/HUD.lua`
- `src/StarterGui/AnimalKingdomUI/AnimalKingdomUIV2/Overlays.lua`
- `src/StarterGui/AnimalKingdomUI/LuckyTreePresentation.lua`
- `src/StarterGui/AnimalKingdomUI/Main.client.lua`
- `src/StarterGui/AnimalKingdomUI/PetMenus.lua`
- `src/StarterGui/AnimalKingdomUI/PetOwnershipMenus.lua`
- `src/StarterGui/AnimalKingdomUI/PlotMenu.lua`
- `src/StarterGui/AnimalKingdomUI/ProgressionMenus.lua`
- `src/StarterGui/AnimalKingdomUI/RemoteBridge.lua`
- `src/StarterGui/AnimalKingdomUI/TutorialGuidance.lua`
- `src/StarterPlayer/StarterPlayerScripts/AnimalKingdomAnnouncements.client.lua`
- `src/StarterPlayer/StarterPlayerScripts/KingdomPrompts.client.lua`
- `src/StarterPlayer/StarterPlayerScripts/PetFollowing.client.lua`
- `src/StarterPlayer/StarterPlayerScripts/TreePresentation.client.lua`

Current normal tree economy retained

The expansion did not reassign species, change base incomes, change search prices, rename families or change release gates. The earlier requested balance pass used the requested prices without adjustment. Its full changes, baseline and tests remain in [the tree economy report](../tree-economy-20260929/REPORT.md). Current neutral-Luck, base-weight values are reproduced here; percentages are rounded only for display.

| Biome | Existing tree | Stable family ID / tier | Price | Pets: rarity, base probability, base coins/sec | Min / typical / max | Expected coins/sec |
|---|---|---|---:|---|---:|---:|
| Meadow | Blossombark | `Meadow_Shakeable_01` / 1 | 250 | Field Mouse (Common): 81.001473% → 2.5/s<br>Patchwork Lop Bunny (Rare): 17.673049% → 3.5/s<br>Blossom Bunny (Legendary): 1.325479% → 6/s | 2.5 / 2.5 / 6 | 2.723122 |
| Meadow | Honeybloom | `Meadow_Shakeable_02` / 2 | 500 | Meadow Chick (Common): 75.614367% → 4/s<br>Meadow Fawn (Rare): 22.684310% → 5/s<br>Cloudtail Fox (Legendary): 1.701323% → 8/s | 4 / 4 / 8 | 4.294896 |
| Meadow | Clover Crown | `Meadow_Shakeable_03` / 3 | 1,000 | Red Squirrel (Uncommon): 68.459658% → 6/s<br>Fluffy Lop Bunny (Rare): 29.339853% → 8/s<br>Prism-Antler Deer (Legendary): 2.200489% → 12/s | 6 / 6 / 12 | 6.718826 |
| Meadow | Sunpetal | `Meadow_Shakeable_04` / 4 | 2,000 | Meadow Goat (Uncommon): 77.777778% → 9/s<br>Meadow Buck (Epic): 11.111111% → 12/s<br>Daisy-Crown Bunny (Epic): 11.111111% → 14/s | 9 / 9 / 14 | 9.888889 |
| Meadow | Whisper Willow | `Meadow_Shakeable_05` / 5 | 4,000 | Daisy Hedgehog (Epic): 99.975006% → 14/s<br>Celestial Lamb (Secret): 0.024994% → 22/s | 14 / 14 / 22 | 14.002000 |
| Forest | Mossheart | `Forest_Shakeable_01` / 1 | 6,000 | Raccoon (Common): 82.088327% → 22/s<br>Tree Frog (Rare): 17.910180% → 36/s<br>Emerald-Wing Guardian (Secret): 0.001493% → 180/s | 22 / 22 / 180 | 24.509783 |
| Forest | Fernwood | `Forest_Shakeable_02` / 2 | 10,000 | Black Bear Cub (Common): 85.714286% → 32/s<br>Brown Bat (Epic): 14.285714% → 52/s | 32 / 32 / 52 | 34.857143 |
| Forest | Duskleaf | `Forest_Shakeable_03` / 3 | 17,500 | Skunk (Uncommon): 87.500000% → 46/s<br>Woodland Owl (Epic): 12.500000% → 70/s | 46 / 46 / 70 | 49.000000 |
| Forest | Elderbark | `Forest_Shakeable_04` / 4 | 30,000 | Badger (Uncommon): 88.607595% → 66/s<br>Leaf-Antler Guardian (Legendary): 11.392405% → 100/s | 66 / 66 / 100 | 69.873418 |
| Forest | Mooncap | `Forest_Shakeable_05` / 5 | 50,000 | River Otter (Rare): 93.023256% → 95/s<br>Crested Owl (Legendary): 6.976744% → 140/s | 95 / 95 / 140 | 98.139535 |
