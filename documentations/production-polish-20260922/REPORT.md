> Latest results: see the **2026-09-23 production pass** appended below. The earlier pass is preserved as history.

# Animal Kingdom production polish — implemented foundation and outstanding work

Status: **partial implementation, not production sign-off**. Completed work was applied to the connected non-zero-ID Studio place and tested in four single-client Play sessions. Nothing was published, no Save As was forced, and Studio was left in Edit mode with device simulation stopped.

The master UI reference image did not arrive in the conversation. Because the request explicitly requires inspecting it before touching UI, all thirteen StarterGui source files remain unchanged. The complete wood/parchment UI V2, shared UI animation framework, and associated final visual pass are still outstanding. The current game still has visible prototype UI and missing content; this report does not call it finished.

## Project, place, and preservation

| Field | Verified value |
| --- | --- |
| Local project | `/Users/jefferypryor/Documents/SuperbulletAI/Real_Animal_K` |
| Active Rojo project | `default.project.json`, project name `Real_Animal_K` |
| Rojo server | Existing Rojo 7.7.0 process, port 34872 |
| Initial Edit `game.Name` | `Real_Animal_K`, recorded in the baseline |
| Final Edit `game.Name` | `Animal Kingdom[TESTING}` |
| `game.PlaceId` | `132313449035787` throughout the audited sessions |
| `game.GameId` | `10764288431` |
| Studio instance ID | `2bd458fd-cd4c-4fa8-9c7d-2fd24f746bb3` |
| StreamingEnabled | false |

The display/name field varied by Studio context; IDs were used to verify the target. No rename operation was issued by this pass. No PlaceId=0 or recovery copy was used.

No Git repository was present. Before-copies are under `before/<original relative path>` in this directory; all eleven changed existing source files have backups matching their initial SHA-256. Of the initial 140 mapped sources, 129 are unchanged, eleven changed, and none were removed. Seven runtime sources and five asset-folder metadata files were added. The final 147 mapped source files match live Edit sources by byte length and source hash. No temporary QA instances remain.

The existing profile, economy, income, ownership, challenge, weather, admin and reward authorities were preserved. Play used the existing `StudioMockSnapshot` mode: a read-only saved snapshot loaded into mock profile memory. No saved player inventory was rewritten for QA.

All 320 physical wooden `PetSlot_XX` models remain. The sampled 80 Plot 1 pedestals and thirteen floor parts match their baseline transforms, dimensions, transparency and collision properties. Only the explicitly reviewed Town structural collision properties were changed live. The Rojo build artifact is a syntax/mapping check, not a replacement place: the mapping also contains old blockout floors, so it must not be used to overwrite the authored map.

## A. UI system

No screens were replaced or disabled during this pass. The actual hierarchy is:

```text
AnimalKingdomUI
  Main → HUD / Currencies / Navigation / Tutorial
       → GameplayMenu / Content
       → Notifications / ActionDialog / GardenReveal / GardenFade
  GameplayWidgets — active primitives, colors, viewports
  PetMenus — Pets, Index
  ProgressionMenus — Biomes, Challenges, Upgrades, Settings
  GardenMenus — existing Garden flows and shop
  PlotMenu — plot management and real furniture/decor shop
  HatchPresentation — existing pet reveal
  Theme / Components / ExampleData — unused by active Main
WeatherEventUI — separately active weather presentation
```

The existing runtime `Version="2.0.0"` attribute predates this work and does not mean the requested V2 exists. Editing the unused Theme alone would not restyle the active UI. Main already has one active-menu variable, which should be retained or wrapped by the eventual MenuManager.

Actual supported UI includes Pets, Index, Garden, Biomes, Challenges with daily/weekly periods, Upgrades, Plot shop, Settings, notices, confirmations, tutorial, and pet reveal. No complete Codes/Quests/Friends system was found; none was fabricated.

The detailed hierarchy, component gaps, screen/back-end ownership, safe-area settings, and refactoring targets are in [ui-and-content-audit.md](ui-and-content-audit.md). Phone, tablet, Xbox layout and all four requested desktop sizes were captured as **existing UI audit screenshots**, not new V2 screenshots.

## B. Animation system

Completed non-UI motion work: frame-independent follower translation/heading, restrained phase-offset idle movement, controlled teleport recovery, and smooth Garden pet presentation. Reduced-motion settings are respected by these renderers.

Not implemented: the requested shared UI Motion module, animated menu opens/closes, currency counting, standardized hover/press/focus, reward hierarchy, animated toasts, pending buttons, and transition/camera refinements. Existing reveal and notice behavior was audited but not changed. Sound asset IDs are currently blank in the existing effects catalog; no invented sound assets were added.

## C. Pet system visuals

- **Canonical resolver:** `Shared.Gameplay.PetModelResolver` resolves definitions through the existing strict Meadow provenance path or `ReplicatedStorage.PetAssets`, with existing `Assets.Pets` compatibility. It never substitutes primitive animals. Imported scripts/invalid templates are rejected; clone geometry is anchored, non-colliding, non-querying and non-touching.
- **Shared geometry:** `PetVisualGeometry` measures visible bounds, excludes invisible roots/explicit ignored bounds, validates contextual orientation, scales clones, fits footprints, and grounds the rotated bounds. Canonical source models are not distorted or repivoted.
- **Definitions:** `PetDefinitions` exposes PetTypeId, ModelKey and BaseIncome aliases and one `imported` list for future normal species. Exceptional context scale/rotation/Y offsets stay in data.
- **Sanctuary:** the existing display adapter and authoritative DisplayedPetIds are preserved. It measures actual neighbor spacing, fits each clone, and raycasts the complete wooden display surface. This matters because the authored tier meshes overlap: an individual slot's bounding-box top is not always the actual surface beneath its pet. Lowest bounds sit approximately .04 studs above support. Optional authored surface attachments and data overrides are supported.
- **Display size:** on Plot 1, each clone's neighbor-limited footprint is capped at about 3.37 studs, versus the former 2.8-stud longest-dimension normalization. Pedestal geometry is unchanged. Tall models can be taller while respecting the size cap. Seven existing displayed pets were observed with correct support and no obvious overlap.
- **Followers:** server-equipped state remains authoritative. One client RenderStepped manager renders all eligible players' pets, with stable formations, model-aware spacing, exponential interpolation, smooth heading, throttled downward raycasts, visibility budget, cleanup and controlled long-distance catch-up. No per-pet server physics or per-frame movement RemoteEvents were added.
- **Garden:** the same resolver and geometry support Garden clones, a 3.2-stud contextual size, support from authored soil, smooth heading and movement, nonnegative idle offsets, and bounded missing-asset retries.

Viewport clone resolution benefits from the shared appearance path. Universal UI framing is **not complete**: the unchanged widget still gives special framing/texture fallback to canonical Meadow pets, ignores PreviewRotation, and the Index/display action retain Meadow-specific gates.

The development validator reports **14 available models for 319 definitions**, with **276 errors and 42 warnings**. Those counts include missing active models, legacy missing entries and compatibility duplicates. Honey Lop is missing; its existing guarded Meadow reward pool remains blocked. No substitute model was inserted. See [pet-visual-implementation.md](pet-visual-implementation.md).

## D. World

**Town:** an explicit role/part-name policy restored CanCollide and CanQuery on 62 inspected structural parts: the four actual building visuals, two market counters, cart, well and named fences/posts. Tiny trim, leaves and decorative overlays were excluded. Original collision/query values were recorded as attributes and in [town-collision-before.json](town-collision-before.json). The policy makes no transform, material, mesh or fidelity changes.

Actual Humanoid walking tests blocked movement through west/east/back fences, well, all four tested building fronts and both counters. The Town entrance was traversable. The second counter's first target ended at its approach face; moving the test target beyond the counter confirmed it blocked traversal. This was a corrected test target, not an unreported geometry change.

**Plots/Garden:** existing four real player floors remain the ownership units. Garden assignment now uses actual plot numbers with preflight validation, including noncontiguous numbering, rather than sorted-list position. Unverified authored geometry is retained; only verified generated markers are treated as locators. Imported crop meshes no longer depend on one internal part name. Visit/Return use the established safe support/clearance utility and preserve the return location on failure. Empty world slot signs now say AVAILABLE; the occupied test slot says READY!.

No global ground-snap, map regeneration, building relocation or biome redesign occurred. A complete walk around every staircase, bridge rail, doorway and every biome/prop has **not** been finished. General prop, sign and prompt consistency still needs the requested world polish sweep.

## E. Performance

Follower visuals use one frame loop, periodic visibility ranking, cached bounds, cached model rotations and throttled grounding. Garden renders movement every frame while crop/status work runs at 10/4 Hz. Unchanged display state avoids repeated clone/scale/pivot work. Clone particles are bounded. Canonical storage does not depend on Workspace streaming.

Studio-only samplers record callback CPU time, counts, raycasts and clone churn every five seconds. In an observed three-pet steady-state sample, the follower callback averaged **0.092 ms**, peaked at **0.160 ms**, and created **zero clones** during the window; raycasts were about **22/sec** in that low-FPS sample. Another fresh Play sample averaged **0.118 ms**, peak **2.379 ms**, over 297 frames. Garden with one visible pet averaged **0.077 ms**, peak **0.396 ms**, over 279 frames in an observed window. Later sessions varied; these are measurements of selected callbacks, not full CPU/GPU, memory, or platform benchmarks.

The follower stress run itself rendered around 15 FPS in this Studio environment. Pets updated on every sampled movement frame, but that does not establish smooth high-FPS behavior on all hardware. Frame-rate independence was also checked deterministically at 30/60/144 Hz.

A confirmed Studio logger feedback loop was removed: failed transport warnings no longer feed back into the log queue; offline retries back off up to 30 seconds; buffers and shutdown are bounded, and legitimate logs recover when the backend returns. Final Play logs contain no repeating logger failures. This alone does not establish the cause of low whole-game FPS.

Remaining performance work includes full-scene CPU/GPU profiling, viewport virtualization and removal of Main's full content rebuild on currency updates. Collision fidelity was not changed without measured justification. No new per-frame network traffic was introduced.

## F. Content pipeline

The rendering foundation is prepared; complete import-once parity across all unchanged UI is not yet achieved.

**New pet:** import a textured Model/MeshPart into `ReplicatedStorage.PetAssets`; add one entry to the local `imported` table in `PetDefinitions.lua` with stable PetTypeId, DisplayName, Biome, Rarity, BaseIncome and ModelKey; configure/inspect its authoritative reward pool; run development validation and in-game checks. Existing non-Meadow pools derive from matching definitions, but also contain legacy generated entries and should be curated when introducing real content. Meadow retains explicit validated three-pet pools and requires deliberate pool/provenance registration. No follower, Garden or placement-algorithm rewrite is needed. Index and Sanctuary UI gates still need removal in V2.

**New biome:** add the unique progression/economy entry to `AnimalKingdomConfig.Biomes`; register its display-name-to-ID mapping in `BiomeTeleport/Destinations`; author its actual floor and safe spawn in a supported region path; register real pets and curate rewards; optionally register biome card art/tree families. Biome menus render definitions automatically. The hardcoded 300-pet assertion and twelve-child teleport startup check were replaced with configuration-derived validation. All existing 300 generated records remain identical. EnvironmentAssets/BiomeAssets are organizational folders, not an automatic world-instantiation system.

**New ordinary shop item:** import its model into `ReplicatedStorage.Assets.<Category>`; add one `ShopDefinitions` entry with DisplayName, Category, ModelName, supported Currency, Cost, Size and MaxOwned; test purchase and server placement. Existing Plot shop cards are catalog-driven. Seasonal and upgrade-as-shop presentation have existing limitations and are not claimed complete.

**Upgrade:** add a definition using an already consumed modifier key; current Upgrades UI renders it automatically. A new gameplay effect still needs its authoritative consumer. Capacity and immediate WalkSpeed handling contain existing ID-specific logic.

Exact field names, supported paths, reward restrictions and tests are documented in [ui-and-content-audit.md](ui-and-content-audit.md). PetAssets, EnvironmentAssets, GardenAssets, BiomeAssets and UIAssets folders now preserve unknown/imported instances. Existing Garden assets were retained.

## G. Actual Play results

| Area | Actual result and limits |
| --- | --- |
| Join/profile | Four single-client starts; existing mock snapshot became Ready, observed .68–1.54 seconds in measured starts. No saved-profile writes. |
| HUD/weather | Currency and weather context rendered; active rain and clear states observed. Garden still displays the previous Town biome label, so context handling remains incomplete. |
| Town collision | Entrance passable; three fences, well, four building fronts and two counters blocked test traversal. Full all-structure circuit outstanding. |
| Plots | Four actual floors recognized; current player assigned/spawned on Plot1Floor, GardenPlot1. |
| Sanctuary | Seven saved display pets rendered; larger, correct surface, no obvious overlap. Full 80-slot stress and all plots not exercised. |
| Followers | Maximum current count of three tested: straight travel, sharp turn, jump, stop/resume and two >400-stud relocations. Three clones stayed separate and recovered within .5 seconds; sampled minimum separation 3.57 studs and minimum support clearance .05 studs. |
| Pet geometry | 409 engine checks passed across all fourteen available species, contextual sizes, rotations, grounding, collision flags, source preservation, invisible roots and missing models. |
| Pets | Opened using actual nav; eleven canonical pet viewports present. Missing legacy species remain blank/unavailable. |
| Index | Opened and filtered to Meadow; eleven discovered canonical previews present. Generic/unavailable entries still expose existing limitations. |
| Garden | Actual Visit and Return succeeded; correct assignment and one actual ready pet visible; followers recovered. Final signs: eleven AVAILABLE, one READY!. New send/boost/claim/purchase transactions were not fully replayed. |
| Biomes | Screen opened and rendered. All unlock/travel transactions not replayed. Twelve runtime destinations loaded after catalog fix. |
| Challenges | Screen opened and rendered; claim/double-claim not tested in this pass. |
| Shop | Existing Plot shop cards rendered with real costs; purchase/placement and Garden purchases not exhaustively tested. |
| Upgrades/Settings | Both screens opened; every purchase, setting persistence and controller flow not retested. |
| Reward/tutorial | Source audited; end-to-end pet-finding/reveal and tutorial completion not exercised in this pass. |
| Desktop resolutions | Pets visual review at requested 1920×1080, 1720×1080, 1600×900 and 1366×768. Smaller desktop has admin-return/nav overlap. Simulator reported some dimensions one pixel below preset. |
| Phone | iPhone 17 Pro landscape simulated; cramped menu and admin-return/nav overlap confirmed. Input automation under device scaling was inconclusive. LandscapeSensor is configured, so portrait not applicable to current game settings. |
| Tablet | iPad Pro M5 13-inch layout inspected; admin return still crowds navigation. Full touch flows not tested. |
| Controller | Xbox layout simulated with GamepadEnabled=true. Virtual B injection was rejected by Studio as a CoreGui-bound action. Controller pass is not established. |

Local verification: all **453 Lua/Luau source files compile**, including dependencies. Focused formation, Garden scheduling, Garden ownership/geometry/travel, logger failure/recovery and content-catalog adapters pass. Rojo builds succeed. The existing general Gameplay test still fails an obsolete free-tree expectation, identically with the original source backups; this is recorded as a pre-existing test mismatch, not a green full suite.

Evidence includes [follower stress](follower-stress-play-results.json), [geometry results](pet-geometry-final-play-results.json), [Town walks](town-walk-play-results.json), [building walks](town-building-walk-play-results.json), [final startup/labels](final-startup-and-labels.json), [final console](final-play-console.txt), and [source/geometry parity](final-parity-result.json). Screenshots are in this directory, including [Sanctuary](sanctuary-first-play.png), [final Garden](garden-final-labels.png), [Pets](pets-existing-ui.png), [Index](index-existing-ui.png), [Biomes](biomes-existing-ui.png), [Challenges](challenges-existing-ui.png), [Plot shop](plot-shop-existing-ui.png), and [phone Pets](phone-pets-existing-ui.png).

## H. Two-player testing

**Not run.** The connected tooling exposed single-client Play start/stop, not a two-client session launcher. Separate-ownership adapter checks passed, but they are not a substitute for two live clients. The existing multiplayer observer test remains available for a real two-client Studio session. Separate plots/Garden data, remote followers, display ownership and UI isolation still require that test.

## I. Remaining issues and next required input

The missing master reference image is required before the authorized UI rebuild can proceed under the stated instructions. UI V2, shared animation, responsive navigation, universal controller focus/back, pending/error/loading states, generic viewport support, reward polish and old-UI cleanup remain substantial work.

Other known issues: most catalog definitions lack real assets; Honey Lop and its guarded pool are unavailable; prototype/generated content names remain visible; Garden biome context is stale; phone/small-desktop admin overlay overlaps navigation; currency changes rebuild entire menu contents; full world alignment/prompt/audio sweep, whole-scene performance investigation, two-player tests and full transaction/reward QA remain unfinished.

No claim is made that the game is perfect, finished, or ready for production publication. The completed changes form a preserved, tested basis for the remaining phases. Reattach the master UI image to unblock that work.


---

# 2026-09-23 production pass — UI V2, real Forest companions, showcase and playability

This section supersedes the earlier outstanding-work list while preserving the previous report as history. **A substantial implementation and repeated Play/visual/repair pass is complete; this is not a whole-game production sign-off.** The active Meadow and Forest collection loop now uses real models throughout. Later biomes still lack real pet imports, and physical controller certification remains outstanding. Nothing was published.

The master reference was found and inspected at [ui-v2/master-reference.png](ui-v2/master-reference.png). The final UI follows its wood, parchment, foliage, flowers, gold and green language using shared uploaded 2D artwork. The game's real currencies, definitions and services provide the content.

The correct Studio instance was repeatedly listed and verified: `fcaf207c-b0eb-4315-b49a-d2b57866c5a1`, Animal Kingdom[TESTING}, **PlaceId 132313449035787 / GameId 10764288431**. No recovery or PlaceId=0 instance was used. Rojo remains on port 34872. Final Edit state is recorded in [final-edit-state.json](completion-20260923/final-edit-state.json).

All destructive gameplay QA used the existing Studio mock snapshot path, with assertions for the real PlaceId and `AKUseMockProfiles=true`. It reads the existing saved profile and changes an in-memory mock. Existing datastore names, stored currencies, pets, Index, Garden, levels, mutations, unlocks, challenges, settings and plot state were not reset. Deterministic reward control exists only on the server when `RunService:IsStudio()` and mock profiles are enabled; it has no client Remote and is absent in production.

## A. UI V2

The active hierarchy uses the existing ScreenGui and modules instead of a parallel competing interface:

```text
AnimalKingdomUI (Version 2.2.0)
  AnimalKingdomUIV2
    Theme / Components / Motion / MenuManager / HUD / Viewport / Overlays
  Main
  PetMenus / ProgressionMenus / GardenMenus / PlotMenu / HatchPresentation
  Interface [runtime]
    HUD — branding, biome/weather, two currencies, utility and main navigation
    Screens — one authoritative major menu, shared content/scroll region
    Overlays — toasts/history, confirmations, profile, travel fade
    Tutorial
  CompanionReveal [runtime, personal]
  KingdomPrompt [runtime, projected world interaction]
```

Theme centralizes wood/parchment/green/gold colors, canonical rarity colors, fonts, sizes, spacing, radii, strokes, shadow parameters, image assets and animation durations. Components provide surfaces, headers, buttons/tabs/navigation, currency pills, badges, search, progress, rarity badges, lock overlays, tooltips, cards and model previews. Semantic card names share the same primitives; they are not separate hand-styled menu systems. Toasts and modals belong to the shared Overlays module.

Pets, Index, Garden, Biomes, Challenges, Shop, Upgrades, Plot, Settings, Daily, Teleport, tutorial, reward reveal, notifications and confirmation flows use the same presentation. Search, rarity/status filtering, sorting, equipped/favorite states and owned-instance actions are real. The Index has biome navigation, discovery cards, unknown silhouettes and a selected companion panel. Retired undiscovered species no longer make Index completion impossible; previously discovered legacy entries and claimed milestones remain intact. Later active definitions still count toward the full-game Index and need their missing assets.

The Biomes menu reads the actual twelve-definition progression: Meadow, Forest, Jungle, Desert, Snow, Volcano, Ocean, Ancient Ruins, Magical Forest, Sky, Prehistoric and Mythical. Cards use in-place biome thumbnails, actual unlock costs/prerequisites and authoritative travel/unlock requests. Garden retains its backend and exposes Expeditions, Crops, Shop and Boosts, three slots, baskets, timers, Claim/Recall/Send and Visit/Return. Daily displays the existing daily challenges. No complete Quests or Codes backend was found, so no fake systems were added. Social uses Roblox's real invite capability.

The old Main-created prototype HUD/menu/reveal paths are replaced. Legacy example/configuration modules remain compatibility files and are not production renderers. Separate old plot/announcement popups forward into the V2 toast/history system. The protected weather cards and admin control room remain separate. The admin return button is styled consistently and avoids compact layouts/major menus.

Visual iterations corrected mobile navigation overlap, desktop menu/navigation clearance, card/action clipping, selected-pet sizing, Garden density, Shop button visibility, the flower-pot preview pivot, a missing spotlight texture, overlaid pet labels and callback retention. Loading, empty, unavailable and pending states are intentional. Raw service errors are not shown to players.

## B. Forest pets and authoritative reward pools

All eleven imports were found in **My Models**, inserted into the verified place, visually matched and archived. Canonical models are local Rojo `.rbxmx` assets; original imports remain in `ServerStorage.ForestImportArchive`. No sphere, generic animal or fabricated replacement was registered.

| Order | PetTypeId | Display name | Rarity | Base Forest Coins/sec | Canonical model |
| ---: | --- | --- | --- | ---: | --- |
| 1 | `ForestRaccoon` | Raccoon | Common | 10 | `ReplicatedStorage.PetAssets.ForestRaccoon` |
| 2 | `ForestBlackBearCub` | Black Bear Cub | Common | 12 | `ReplicatedStorage.PetAssets.ForestBlackBearCub` |
| 3 | `ForestSkunk` | Skunk | Uncommon | 15 | `ReplicatedStorage.PetAssets.ForestSkunk` |
| 4 | `ForestBadger` | Badger | Uncommon | 18 | `ReplicatedStorage.PetAssets.ForestBadger` |
| 5 | `ForestTreeFrog` | Tree Frog | Rare | 22 | `ReplicatedStorage.PetAssets.ForestTreeFrog` |
| 6 | `ForestRiverOtter` | River Otter | Rare | 28 | `ReplicatedStorage.PetAssets.ForestRiverOtter` |
| 7 | `ForestBrownBat` | Brown Bat | Epic | 36 | `ReplicatedStorage.PetAssets.ForestBrownBat` |
| 8 | `ForestWoodlandOwl` | Woodland Owl | Epic | 45 | `ReplicatedStorage.PetAssets.ForestWoodlandOwl` |
| 9 | `ForestCrestedOwl` | Crested Owl | Legendary | 55 | `ReplicatedStorage.PetAssets.ForestCrestedOwl` |
| 10 | `ForestLeafAntler` | Leaf-Antler Guardian | Legendary | 70 | `ReplicatedStorage.PetAssets.ForestLeafAntler` |
| 11 | `ForestEmeraldWing` | Emerald-Wing Guardian | Secret | 90 | `ReplicatedStorage.PetAssets.ForestEmeraldWing` |

Every Forest import has **one real MeshPart with its original TextureID**; these eleven particular imports have zero SurfaceAppearance objects. Existing Meadow PBR appearances are retained. The [verified manifest](completion-20260923/FOREST-MANIFEST.md) lists all eleven My Models asset IDs, current original-import paths, MeshIds, textures and readiness; its [JSON](completion-20260923/forest-model-manifest.json) includes measured bounds, pivots, sizes, colors and materials. Forest orientation is normalized through definition data (`ModelRotation=-90`), without rotating the source meshes.

There are **29 physical Forest trees**, eight imported art families and **five economic reward tiers**. The tier order follows the existing Forest asset/configuration order, not alphabetical names. All retain the existing 750 Forest Coin search cost.

| Tier / pool | Physical families (copy counts) | Three rewards, in weight order | Weights |
| --- | --- | --- | --- |
| 1 / `Forest_Shakeable_01` | Tree_Oak_1 (4) | Raccoon, Black Bear Cub, Skunk | 65 / 25 / 10 |
| 2 / `Forest_Shakeable_02` | Tree_Oak_2 (4) | Skunk, Badger, Tree Frog | 65 / 25 / 10 |
| 3 / `Forest_Shakeable_03` | Tree_Cedar_1 (2), PineTree_3 (4) | Tree Frog, River Otter, Brown Bat | 65 / 25 / 10 |
| 4 / `Forest_Shakeable_04` | Tree_Pine_1 (4), tree_pineRoundA (4) | Brown Bat, Woodland Owl, Crested Owl | 65 / 25 / 10 |
| 5 / `Forest_Shakeable_05` | Tree_Pine_2 (3), Willow_5 (4) | Crested Owl, Leaf-Antler Guardian, Emerald-Wing Guardian | 70 / 25 / 5 |

This is eleven unique species, fifteen slots and four intentional adjacent-tier overlaps. The old generic Forest pool is retired from new rewards; saved legacy pets remain readable. Forest base income is monotonic and averages **36.45/sec**, versus **4.18/sec** across the fourteen active real Meadow species. Income is calculated by server services.

**Honey Lop was skipped as requested.** It remains a readable legacy definition, is retired from new rewards, and its blocked Meadow starter entry uses an explicit existing Red Squirrel overlap. No substitute bunny model was invented.

Before accepting a paid search, the server validates the entire advertised pool: definitions, biome, rarity, positive finite income/weights, canonical mesh/texture bindings and client loading acknowledgment. A broken candidate makes the whole pool unavailable, logs the exact reason and charges nothing; candidates are never silently removed to alter odds. Startup loading uses four concurrent jobs and bounded acknowledged retries. It is now definition-driven for future imports, without a Meadow/Forest species gate.

Evidence: [all 25 real species](completion-20260923/reward-final-playtest-results.json), [all 29 Forest copies and failure cases](completion-20260923/forest-tree-copies-qa.json), [10,000 weighted samples per pool](completion-20260923/forest-weight-sampling.json), [natural non-forced rewards](completion-20260923/natural-tree-rewards.json), and [final catalog/pool/reward check](completion-20260923/final-catalog-reward-qa.json).

## C. Animations, reveal, teleport and feedback

Shared motion uses approximately .23-second opens, .18-second closes, .11-second hover and .08-second press responses, with focus/selection styling, progress animation, currency pulses, reveal entrances and toast transitions. Reduced motion is supported. Existing suitable audio is reused at restrained volume; this is not a new bespoke sound library.

A tree search has an atomic server claim, approximately .8-second shake with leaf/rustle feedback, exact transform restoration, then a personal egg reveal. The ornamental egg wobbles/cracks and gives way to the real textured pet in roughly 1.3 seconds. The warm, darkened showcase has a soft spotlight treatment, rarity accent, gold/wood stage, bounds-framed model and **10-second turntable rotation**. Only the showcase clone rotates. Name, canonical rarity, base income and a truthful first-discovery indicator accompany Continue, Skip and Equip Now.

The pet and Index entry are committed server-side before the presentation payload. Continue, Skip, death and later travel do not control ownership or saving. During presentation, search prompts are disabled locally and server cooldown/claim guards remain authoritative. A first full-slots Equip test correctly did not equip; a separate available-slot test verified successful Equip Now on the exact awarded UID. The presentation is personal and never takes another player's camera.

Garden Visit/Return, biome travel, Plot travel and Admin Room return use the shared short leaf/title fade and server acknowledgment. The reward sequence is the short personal set piece; ordinary travel stays brief. Notifications, purchases, claims and unavailable actions use shared feedback. Custom tree prompts show actual tree/cost data with E / controller X / Tap, a short hold indicator and a correctly positioned touch target. Actual E and phone-emulator tap each awarded one pet and opened the showcase.

Evidence: [reveal lifecycle, including death](completion-20260923/reveal-lifecycle-qa.json), [successful Equip Now](completion-20260923/equip-now-qa.json), [keyboard/mobile prompt input](completion-20260923/prompt-input-qa.json), [travel/camera checks](completion-20260923/teleport-camera-qa.json).

## D. Camera and movement

`CameraOwnership` provides acquisition/revocation/release and lifecycle cleanup for existing camera owners. Normal play restores Custom, the current character Humanoid, mouse behavior and mouse icon. There is no RenderStepped loop forcing Custom. The hatch uses a ViewportFrame and does not take the world camera.

Normal reveal, Skip, Continue, Equip Now, immediate death cleanup, respawn and teleport were exercised. Native mouse delta injection while right-dragging changed camera direction, and releasing returned normal mouse behavior. Admin Room arrival, opening the existing Forest camera, exiting it and returning to the plot were tested. That test found the camera Exit overlay below the new HUD; a targeted DisplayOrder fix now makes Exit clickable. A second mouse-look test after Exit passed. Admin camera positions and the physical room were not redesigned.

A further Play-discovered movement bug compared a float32 Humanoid.WalkSpeed against an exact Luau double. Fractional modifiers could repeatedly reapply themselves. The targeted fix uses a write guard and numeric tolerance. A 16.96 target remained 16.959999 through 100 refreshes; an external base of 20 correctly became 21.200001. WeatherState, EventDefinitions, weather timing and effect definitions were preserved.

Evidence: [admin exit/return/mouse-look](completion-20260923/admin-camera-travel-qa.json), [Index/movement checks](completion-20260923/index-movement-shop-final-qa.json).

## E. Pets, viewports, Sanctuary and Garden

One chain resolves owned UID → PetTypeId → PetDefinition → canonical model across inventory, Index, reveal, followers, Sanctuary and Garden. Profile data stores owned-instance IDs, never Roblox model instances. Generic bounds, orientation and lighting support antlers, wings, tails, tall ears and wide bodies. Textures, mesh geometry and SurfaceAppearance survive cloning.

The existing follower foundation was retained. Measured excess following delay justified a small smoothing/velocity-lead refinement. The final native-input run used **12 equipped pets**: running, sharp turn, jump, stop, teleport and respawn. Minimum separation remained about **4.52 studs**. Maximum sampled formation error was **1.85 studs while running**, **3.59 on the sharp turn**, .58 while jumping and zero after settling, teleport recovery and respawn. Decorative collision/touch flags were off. One centralized renderer, phased idle variation and throttled grounding remain; no per-frame server CFrame remotes were introduced.

The current imported Sanctuary is an **8×8, 64-pad structure**, not the old wooden pedestal arrangement. Its visible mesh was measured because convex collision does not accurately describe the stepped surfaces. `SanctuaryDisplayDefinitions` holds one normalized layout and measured row surfaces; `SanctuarySlotLayout` prefers explicit `PetDisplaySlots` markers for future structures. Invisible anchors are separate from visible geometry. Wooden `PetSlot_XX` objects were not deleted by name.

The display renderer uses 82% of usable footprint, actual bounds, height limits, normalized facing and roughly .04-stud ground clearance. In the 64-pet test, clearance ranged from **.03999877 to .04000187 studs**, with zero collidable pet parts. All 25 current species were included, including small, large, winged, long-tail and antler models. Add/remove and foreign-owned rejection passed; no duplicate clones remained. The server's displayed-UID income was **929/sec**, exactly the expected sum, and did not change when followers were unequipped. Inventory-only pets do not contribute to that calculation.

One centralized Sanctuary idle manager uses staggered grounded yaw, reduced update rates with distance and no offscreen idle. It handles replication arriving in stages and limits initialization work. Name labels are limited to the closest relevant model rather than sixty overlapping labels.

All 25 species were also sent through actual Garden expeditions in groups of three, checking owned UID, species, mesh, texture and collision flags. Garden geometry, crop state, expedition authority and ownership assignment were preserved.

Evidence: [64-slot display/income/ownership](completion-20260923/sanctuary-playtest.json), [surface measurements](completion-20260923/sanctuary-surface-measurements.json), [final follower run](completion-20260923/follower-final-qa.json), [25 Garden species](completion-20260923/garden-species-qa.json).

## F. World and placement

The prior Town collision repair was preserved and retested with actual Humanoid walking: entrance traversable; west/east/back fences, well, both counters and the Trading Hall, Blacksmith, General Store and Daily Rewards building fronts blocked traversal in eleven checks. A visual circuit covered Town, Meadow, Forest, Garden, player plots and Sanctuary.

The existing Shop's Wooden Chair and Flower Pot were missing models and fell back to generic cubes. They now have recognizable local models, and buying/placing an unavailable catalog model returns a friendly failure. Both fit their declared footprint and sit at the measured floor top. The flower-pot pivot was corrected after visual review showed it sideways. No new shop items or currencies were invented.

No map regeneration, global ground-snap, authored biome relocation, plot geometry replacement, Garden geometry redesign or admin-room redesign was performed. The broad world still contains rough authored/import areas; every bridge, rail, stair and remote biome prop was not individually certified.

Evidence: [Town walking](completion-20260923/world-walk-final.json), [shop model bounds/grounding](completion-20260923/shop-model-qa.json), [world screenshots](completion-20260923/world-final).

## G. Mobile

Actual Studio device sizes used include iPhone 17 Pro **750×361 landscape / 401×778 portrait** and iPad Pro 11-inch **1209×834**. Landscape main navigation sits above the menu; portrait uses four columns × two rows, with all eight destinations visible. Safe-area offsets, menu height, card height, horizontal biome/upgrade actions, selected-pet scrolling and Garden slot density were iterated from screenshots rather than uniformly shrinking desktop UI.

The phone prompt tap completed a real server search and hatch. Main navigation, Garden Send selection, reveal Continue and scrollable menus were exercised through the emulator's pointer input. Final phone previews report loaded real models. Portrait and tablet screens were also visually reviewed. These are Studio emulator checks, not physical-phone certification or a low-end mobile GPU benchmark.

Evidence: [mobile previews](completion-20260923/mobile-preview-final-qa.json), [phone/tablet screenshots](completion-20260923/ui-final), [phone tree showcase](completion-20260923/showcase-final/input-MobileTap.png).

## H. Controller

Xbox simulation reported GamepadEnabled and the ten-foot interface. All important screen buttons are Selectable, directional NextSelection links are assigned, scroll containers follow selected controls and gold focus rings are visible. The eleven real screens and profile modal were checked for focus graph completeness and modal focus containment. B is bound to close/back through the central menu manager, including nested pet/Garden flows and overlays.

**Physical A/B gameplay input is not verified.** Studio's VirtualInput rejected B as a CoreGui-bound key, and keyboard injection of gamepad-named keys is not equivalent to controller hardware. The final graph test intentionally used production UI callbacks and GuiService focus; it is labeled that way in [controller-final-qa.json](completion-20260923/controller-final-qa.json). A real controller or native Controller Emulator pass remains required for acceptance.

## I. Performance

Static previews use one .2-second visibility scheduler with a **24-model budget**. Closed/offscreen pet previews are released; static previews have no per-preview RenderStepped callback. Only active reveal animation uses turntable updates. Main menu contents no longer rebuild for every currency tick, and local timers do not poll remotes.

A 20-cycle actual menu open/close stress test ended with **zero live/registered previews, zero retained destroyed-button callbacks and eighteen live HUD callbacks**. Explicit cleanup fixed two measured retention issues: a button callback registry cycle and grid-resize connections retaining destroyed grids. Total UI instances varied from 260 to 276 due to transient sounds/prompts; this is not claimed as a zero-allocation run.

| Studio sample | Frames | Median frame interval | 95th percentile | Maximum |
| --- | ---: | ---: | ---: | ---: |
| Menus closed, 12 followers | 128 | 16.67 ms | 17.07 ms | 17.35 ms |
| Pets open | 128 | 16.65 ms | 17.21 ms | 19.70 ms |
| 64 Sanctuary pets visible, 12 followers, Snowfall | 128 | 16.65 ms | 18.12 ms | 18.68 ms |

These are CPU-timeline frame intervals in this Studio environment, not pure script CPU cost or cross-device FPS guarantees. The Sanctuary scene sample contains about **1.21 million rendered triangles / 332 draw calls** including shadows/effects. The follower callback averaged .35 ms in that capture window; its 5.43 ms peak included creating twelve clones after travel, so it is not presented as a steady-state maximum. The earlier steady closed sample averaged .30 ms and peaked at .56 ms. Menus-closed preview count was zero during the measured performance captures.

Script memory profiling is unavailable in this Studio build (STUDIOPLAT-37936 flag restriction). Whole-scene instance composition and visible triangle data were collected, but low-end mobile GPU/memory certification remains outstanding.

Evidence: [closed](completion-20260923/performance-closed.json), [Pets open](completion-20260923/performance-pets-open.json), [Sanctuary](completion-20260923/performance-sanctuary-final.json), [Sanctuary scene](completion-20260923/scene-sanctuary-triangles.json), [UI lifecycle](completion-20260923/ui-lifecycle-stress.json).

## J. Transaction QA

Tree acceptance locks the resource/player before animation. After final validation, selection, charge, owned-pet insertion and Index commit occur synchronously under the server claim. Client presentation is not a save acknowledgment. Every tested physical Forest tree restored its exact saved part CFrames.

Sixteen repeated copies of the same request ID were sent for Shop Buy, Upgrade, Challenge Claim, Garden Send, Garden Claim and Claim All. Each changed state exactly once; cached receipts could be resent sixteen times, while the client presented one result. Representative results: one chair for 500 coins; one upgrade for 500; one challenge payout of 1,000 coins/10 tokens; one Garden trip; one claim removing one trip; Claim All removing two trips once. Twelve/thirteen rapid tree attempts produced one accepted claim and one owned pet. Broken candidate, insufficient currency, capacity, locked biome and distance failures were rejected; the broken-model test produced zero charges and zero pets.

This verifies duplicate request replay and the tested guards. Independent deliberate purchases with different request IDs remain legitimate separate transactions; those are not conflated with retries.

Evidence: [transaction results](completion-20260923/transaction-qa.json), [tree copies/failures](completion-20260923/forest-tree-copies-qa.json), [final rapid tree check](completion-20260923/final-catalog-reward-qa.json).

## K. Two-player QA

A **real two-client Studio session** ran through `StudioTestService:ExecuteMultiplayerTestAsync(2, ...)`, not only simulated ownership tables. Both clients loaded twenty-five real pet assets. Profiles, plots, Garden plots, currencies, inventories, Index state and displayed UIDs were separate. Foreign-owned equip/display/Garden-send requests were rejected. Player A's forced Brown Bat reward and personal showcase did not change Player B's inventory/currency/camera. Garden claims remained isolated; local/remote followers matched their owners.

The temporary multiplayer observer scripts were removed from Edit. The retained [two-player result](completion-20260923/two-player-qa.json) includes both client states, ownership checks, PlaceId and GameId. QA scripts in `completion-20260923/qa` are documentation artifacts and are not Rojo-mapped production scripts.

## L. Screenshots, iterations and verification

Final desktop captures: [HUD](completion-20260923/ui-final/desktop-HUD.png), [Pets](completion-20260923/ui-final/desktop-Pets.png), [Index](completion-20260923/ui-final/desktop-Index.png), [Garden](completion-20260923/ui-final/desktop-Garden.png), [Biomes](completion-20260923/ui-final/desktop-Biomes.png), [Challenges](completion-20260923/ui-final/desktop-Challenges.png), [Shop](completion-20260923/ui-final/desktop-Shop.png), [Upgrades](completion-20260923/ui-final/desktop-Upgrades.png), [Plot](completion-20260923/ui-final/desktop-Plot.png), [Settings](completion-20260923/ui-final/desktop-Settings.png), [Daily](completion-20260923/ui-final/desktop-Daily.png), [Teleport](completion-20260923/ui-final/desktop-Teleport.png).

Reward: [egg](completion-20260923/showcase-final/egg.png), [final real reward](completion-20260923/showcase-final/final-reward.png), [Epic bat](completion-20260923/showcase-final/ForestBrownBat.png), [Legendary antler guardian](completion-20260923/showcase-final/ForestLeafAntler.png), [Secret winged guardian](completion-20260923/showcase-final/ForestEmeraldWing.png), plus [every species](completion-20260923/rewards-final).

World: [64-pet Sanctuary](completion-20260923/world-final/Sanctuary-64.png), [close display](completion-20260923/world-final/Sanctuary-close.png), [12 followers](completion-20260923/world-final/Followers-12.png), [Town](completion-20260923/world-final/Town.png), [Meadow](completion-20260923/world-final/Meadow.png), [Forest](completion-20260923/world-final/Forest.png), [Garden](completion-20260923/world-final/Garden.png).

Devices: [phone Pets](completion-20260923/ui-final/phone-Pets.png), [phone Garden](completion-20260923/ui-final/phone-Garden.png), [phone Biomes](completion-20260923/ui-final/phone-Biomes.png), [portrait HUD](completion-20260923/ui-final/phone-portrait-HUD.png), [tablet](completion-20260923/ui-final/tablet-Biomes.png), [Xbox focus](completion-20260923/ui-final/controller-focus.png), [Xbox modal](completion-20260923/ui-final/controller-modal.png). Earlier `baseline-*`, `ui-iteration3`, and other iteration files are preserved as history, not final acceptance screenshots.

All **470 Lua/Luau files compile**, including **164 production sources**. Rojo build succeeds. All 164 mapped non-package script sources match the live Edit sources exactly. The local change manifest records 41 changed existing files, 23 new non-package files and no removed baseline files; prior copies remain available. The source-only Rojo `.rbxlx` build is a validation artifact, **not a replacement for the authored place**. It was not opened or published.

Evidence: [compile](completion-20260923/final-compile.json), [mapped source parity](completion-20260923/mapped-source-verification.json), [change manifest](completion-20260923/source-change-manifest.json), [clean final Play state](completion-20260923/final-play-state.json), [final Edit state](completion-20260923/final-edit-state.json).

The final clean startup loaded all twenty-five active real models. Native mouse clicks opened and closed Pets, Garden, Shop, Index and Biomes; afterward there were zero live/registered previews, Custom camera on the current Humanoid, normal mouse behavior and enabled search prompts. The raw [final console](completion-20260923/final-play-console.txt) retains the known missing-asset/audio warnings and one corrected QA inspection typo (`Utility_Shop` instead of `Nav_Shop`); no production runtime exception or WalkSpeed recursion appeared. The [restored Edit viewport](completion-20260923/final-edit-viewport.png) is captured with simulation stopped.

## M. Remaining issues and future content workflow

1. **Later-biome pet content is still missing.** The full validator finds 25 available models across 330 definitions, with 250 missing/invalid active model errors and 68 legacy/asset warnings. The active real Meadow/Forest set is ready; later missing-model pools are unavailable rather than awarding placeholders. Real imports and curated pools are required before claiming all twelve biomes are playable collection content.
2. **Physical controller A/B and real-device mobile testing remain required.** Layout, focus, pointer interaction and emulator checks are documented with their limits. No console hardware or low-end phone performance guarantee is claimed.
3. **World polish remains uneven outside the reviewed routes.** Authored import staging/rough areas are still visible, and every remote rail/bridge/stair has not been certified. Protected world geometry was preserved.
4. **Audio content is incomplete.** Existing UI sounds and weather audio transitions were reused. The existing weather audio manifest still has unassigned upload slots; the weather engine was not rebuilt. No full bespoke sound pass or broad ambient remix is claimed.
5. **Legacy pets without models remain archived/unavailable.** Their saved instances, placement records, levels and Index entries were preserved. Honey Lop is intentionally retired from new rewards under the user's instruction.
6. **Script memory/GPU/platform coverage is incomplete.** The available Studio profiler provided useful frame and scene measurements; unsupported memory APIs and hardware limits are explicitly recorded.

For future pets, import the real model into `ReplicatedStorage.PetAssets`, add a definition to `Definitions/ImportedPetDefinitions.lua` (PetTypeId, DisplayName, ModelKey, Biome, existing Rarity and BaseIncome), then add the species to its authoritative reward pool. Optional ModelAssets pins mesh/texture/PBR provenance; optional orientation/context overrides handle unusual imports. The resolver, asset readiness, reveal, inventory, Index, follower, Sanctuary and Garden paths are generic. A Studio-only probe with a real Badger clone and no Meadow/Forest flags passed client preload and server readiness, then was removed: [generic import pipeline check](completion-20260923/generic-import-pipeline-qa.json).

New biomes continue through the actual biome configuration, safe spawn/world registration and authoritative pool definitions; the UI renders definitions automatically. New permanent Shop items use the existing catalog plus a real category/model asset and server placement validation. New display structures should supply organized `PetDisplaySlots/Slot_NNN` parts or attachments with facing, usable footprint, row and optional height limits; no per-pet placement CFrames are required.

**Final state: Edit mode, device simulation stopped, normal Studio viewport restored, no temporary QA instances, no publication.** The follow-up work is primarily missing content and platform certification; the two high-priority real-pet experiences have been implemented and repeatedly exercised.


---

# 2026-09-23 targeted follow-up — side action button edges

Replaced the small 9-slice side shell with a shared `AnimalKingdomUIV2/SideActionButton` for Shop, Daily, Teleport, Friends, Updates and Profile. The root image is empty/transparent; matched native corners, one active rim, contained focus/badges and eight-pixel layout gaps prevent edge bleeding. The original large wood image now contributes only interior grain. Hover never expands the hit target, and press motion shrinks inward. A second phone review reduced the compact badge to 16 pixels and verified portrait navigation clearance. Quests/Codes have no live backend and were not invented.

Desktop native hover/press/selected/rapid-cancel checks, all three utility menu actions, Xbox focus/selected/badge visuals, phone landscape and temporary portrait checks passed. Disabled/pending state cleanup retained the transparent root. Four affected modules compile and exactly match Studio; Rojo build succeeds. Studio is in Edit with the original camera and default device view. Nothing was published. Full cause, implementation, screenshots and evidence: [side button dev note](../ui-side-buttons-20260923/README.md).


## September 23 add-on — Individual weight, Held Pets, swaps and selling

The subsequent pet-system pass is documented in [the full A–Q report](../pet-ownership-weight-20260923/REPORT.md). It extends the existing OwnedPets/canonical resolver with persistent individual weight, five Held slots, exclusive pet locations, safe Sanctuary swaps, server-derived income/value and confirmed selling. Studio loop, statistical, size, mock persistence, phone/tablet and controller-focus evidence is linked there. Two-client launch and hardware-controller/performance limitations are explicitly recorded. No live data was reset and no publishing occurred.
