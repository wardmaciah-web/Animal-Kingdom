# UI and content pipeline audit

Audit date: 2026-09-23. Project: `/Users/jefferypryor/Documents/SuperbulletAI/Real_Animal_K`.

This document describes current source behavior, the small catalog compatibility fixes made during this pass, and remaining work. It does not substitute for the main report's Studio screenshots and Play results. The requested master UI image was not available in the conversation, so no files under `src/StarterGui` were edited. The requested wood/parchment UI rebuild remains unfinished.

## Current UI hierarchy and ownership

```text
StarterGui
├─ AnimalKingdomUI [ScreenGui]
│  ├─ Main.client.lua
│  │  ├─ HUD / Currencies / Navigation / Tutorial
│  │  ├─ GameplayMenu / Content [one shared ScrollingFrame]
│  │  ├─ Notifications
│  │  ├─ ActionDialog / GardenReveal
│  │  ├─ GardenFade / GardenTitle
│  │  └─ TutorialMarker [BillboardGui]
│  ├─ GameplayWidgets.lua [active UI primitive library]
│  ├─ PetMenus.lua [Pets, Index]
│  ├─ ProgressionMenus.lua [Biomes, Challenges, Upgrades, Settings]
│  ├─ GardenMenus.lua [expeditions, crops, shop, boosts]
│  ├─ PlotMenu.lua [plot management, catalog shop, placements]
│  ├─ HatchPresentation.lua [pet reward presentation]
│  ├─ RemoteBridge.lua
│  ├─ BiomeImages.lua
│  └─ Theme.lua / Components.lua / ExampleData.lua [unused by active Main]
└─ WeatherEventUI [separate functioning ScreenGui]
   └─ WeatherEventController.client.lua
```

Admin controls are separately owned by `StarterPlayerScripts/AdminCommandController.client.lua` and `AdminCommandUI.lua`; this pass did not replace them.

`Main.client.lua` requires `GameplayWidgets`, not `Theme` or `Components`. `GameplayWidgets.Color` supplies the active palette, while Garden also declares its own colors. Editing the existing Theme alone would have no effect on the active screens. Theme also contains the legacy rarity name `Mystic`; current gameplay uses `Mythical` and `Secret`.

Main sets a runtime `Version="2.0.0"` attribute, but this is not evidence that the requested visual V2 is implemented. Metadata still declares `1.0.0`. The active UI uses cream and green flat panels with Gotham text and default button color feedback. No central wood theme, complete reusable component family, Motion module, or MenuManager module exists yet. Main's single active-menu variable already prevents normal major-menu stacking and should be retained during refactoring.

The `.before-*` files in the UI source folder are backups, not proof of active duplicate screens. No legacy screens were disabled in this pass. WeatherEventUI remains active and needs coordinated styling and layering when V2 is implemented.

## Actual screen and backend coverage

| Requested area | Current implementation | Existing authoritative connection |
| --- | --- | --- |
| HUD | Coins, Friendship Tokens, biome/weather context, eight bottom tabs | DataController snapshots; WeatherState attributes; CurrentBiome player attribute |
| Pets | Paged owned pets; equip, favorite, lock, delete; Meadow display action | PetService; SanctuaryService through GameplayService |
| Index | Catalog progress, discovery rows, milestone claims | PetDefinitions, IndexRewardDefinitions, IndexService |
| Garden | Expeditions, pet selection, send/recall, crops, supplies/upgrades/cosmetics, boosts | GardenDefinitions, GardenProgress, GardenExpeditionService |
| Biomes | Catalog cards, unlock and travel | BiomeDefinitions, BiomeService, existing TeleportToBiome RemoteEvent |
| Challenges | Daily and weekly challenge cards | ChallengeDefinitions, ChallengeService |
| Upgrades | Cards generated from UpgradeDefinitions | UpgradeService and ModifierService |
| Plot | Income collection, plot level, visitor setting, furniture/decor shop and placement | PlotService, ShopService, PlacementService |
| Shop | Embedded Plot shop and Garden shop; no standalone major Shop screen | ShopDefinitions and GardenDefinitions |
| Settings | Reduced motion, other players' pets, rarity auto-delete | Saved Settings data through GameplayService |
| Pet reveal | Queued HatchPresentation overlay | Server-generated Hatch result; canonical PetAppearance |
| Notifications | A queued transient notice, not an inbox | GameplayNotice and GameplayFeedback |
| Confirmations | Delete modal, Garden send/recall steps, harvest overlay | Existing server actions and delete tokens |
| Tutorial | Fourteen-step card and nearby tree marker | TutorialDefinitions and TutorialService |
| Daily | Daily challenge period, not a separate login-reward feature | ChallengeService |
| Teleport | Biomes, Garden visit/return, separate admin controls | Existing server travel handlers |
| Quests, Codes, Friends/profile menu | No corresponding complete production UI/backend found in this audit | Do not fabricate these systems during styling |

## UI work still required

1. **Activate one design system.** Route GameplayWidgets, all menus, reveal, tutorial, and WeatherEventUI through one Theme and reusable component layer after inspecting the reference. Keep decorative framing outside readable interiors. Add branding, icons, selected states, and only utility controls supported by real systems.
2. **Stop destroying whole menus on currency ticks.** `Main.client.lua` clears `Content` in `render()` and refreshes on every `Currencies` update. This recreates visible pet models/viewports and loses focus. Update the HUD separately; preserve pet cards by UID and apply individual property changes.
3. **Complete motion helpers.** Windows and notices currently toggle visibility; currency and context text change immediately; GameplayWidgets buttons use `AutoButtonColor`. Garden's six-step fade is triggered by post-action feedback, after server travel has occurred. Build interruptible opening/closing, press/focus, card state, counter, notification, modal, and transition helpers.
4. **Complete request feedback.** RemoteBridge is fire-and-forget. Garden's 0.6-second debounce is not tied to completion; other screens lack pending locks. Extend the existing request/feedback contract and request policy coherently; show pending/success/failure states, timeouts, and understandable errors without creating alternative purchase or inventory authority.
5. **Mobile layout is unfinished.** Eight fixed bottom tabs at 390px screen width produce approximately 41px-wide buttons with 12px text. The Sanctuary action is 28px tall. There is no responsive bottom-nav reflow or general minimum touch-target enforcement. The coordinator's phone-landscape Play review reported the admin Return control overlapping navigation and cramped Pets content; phone/tablet quality is not passing.
6. **Controller coverage is incomplete.** Garden alone has explicit A/B actions and selection links. General menus need initial focus, visible focus, logical directional navigation, modal focus ownership, selection restoration, and Back. Garden's persistent ContextAction bindings and Heartbeat timer also need a teardown path during the UI refactor.
7. **Loading and empty states need completion.** HUD can remain at Loading indefinitely on initialization failure; menu clicks return silently before data. No retry/loading timeout UI exists. Current Pets empty text still references hatching. Challenge completion, undiscovered pets, missing assets, and empty Garden flows need consistent states.
8. **Viewports remain partially species-gated.** GameplayWidgets has good aspect-aware bounds framing only for `CanonicalMeadowPet`; other models use a fixed camera. PetMenus.Index only shows models for discovered Meadow pets. The canonical resolver is now generic, but the UI adapter must use it consistently and respect PreviewRotation. The UI was deliberately left unchanged pending the reference.
9. **Reward presentation needs visual review.** Meadow rewards initially wiggle the pet using the old egg motion, then flash the screen, show a static reveal, and auto-close after 2.5 seconds. No rarity-specific reveal hierarchy is implemented. Existing friendly companion wording is already present.
10. **Formatting and audio remain partial.** GameplayWidgets.Format abbreviates numbers, but Garden and several costs/countdowns use independent formatting. Shared hover/click/open/claim hooks are missing; current GameplayEffectsDefinitions sound IDs are blank. Approved sound assets are still needed.

Stored `AnimalKingdomUI/init.meta.json` declares `IgnoreGuiInset=false` and `ScreenInsets=DeviceSafeInsets`. The coordinator's actual client query instead reported AnimalKingdomUI with `IgnoreGuiInset=true`, `ScreenInsets=DeviceSafeInsets`, and `ClipToDeviceSafeArea=true`; WeatherEventUI reported `IgnoreGuiInset=false` and `ScreenInsets=CoreUISafeInsets`. Audit the effective runtime safe-area behavior during V2 work rather than inferring it from metadata alone. Existing saved Settings should remain in the current persistence system. Readable rarity and lock text already supplement color in several screens; carry this forward.

The coordinator captured all four requested desktop sizes in `desktop-1920x1080-existing-ui.png`, `desktop-1720x1080-existing-ui.png`, `desktop-1600x900-existing-ui.png`, and `desktop-1366x768-existing-ui.png`, plus phone, tablet, Xbox, and major-menu images in this directory. These show the existing UI, not a completed visual V2. Xbox virtual Back input was blocked by CoreGui, so a screenshot does not establish a successful controller navigation test.

## Exact current content workflows

### Add a pet using the new canonical foundation

1. Import a textured Model or MeshPart into `ReplicatedStorage.PetAssets` with a stable name. Do not depend on a streamed Workspace model. Existing validated Meadow assets stay under `MeadowPetTemplates`.
2. Add one entry to the `imported` list in `Shared/Gameplay/Definitions/PetDefinitions.lua`, providing `PetTypeId`, `DisplayName`, `Biome`, `Rarity`, `BaseIncome`, and `ModelKey`. Optional `BasePower` and exceptional context scale/rotation fields belong in that entry. IDs must remain unique.
3. Configure the reward pool intentionally in `EggDefinitions.lua`. Non-Meadow pools are automatically assembled from matching biome definitions and rarity weights; inspect the entire resulting pool. Legacy generated entries are also included by that default generator, so a new biome intended to reward only real imported models should provide an explicit curated pool after generation. Meadow's existing five paid, validated three-pet pools are deliberately special; do not bypass their provenance/readiness rules by mislabeling another pet.
4. Run the development asset validator and test discovery, reveal, ownership, equip, Garden, and display placement with the actual asset. The resolver/appearance/follower/Garden/display placement paths now accept generic definitions without species-specific rendering code.

**Remaining UI gate:** Pets offers the display action only for `IsMeadowPet`; Index only renders discovered Meadow previews. The generic Sanctuary renderer can display an authoritative DisplayedPetIds entry, but ordinary users cannot reach that flow for a new generic pet through the unchanged menu. The complete “one entry works everywhere” promise is therefore not fulfilled yet. Do not set `IsMeadowPet=true` merely to bypass these UI conditions: it selects the strict Meadow validation path.

### Add a biome without rewriting its menu

1. Add an entry to `SharedSource/Datas/AnimalKingdomConfig.lua` in intended progression order: unique `Id`, `DisplayName`, `MinIncome`, `MaxIncome`, and `UnlockCost`. `BiomeDefinitions.lua` derives order, previous biome, currency, egg ID, resource-table ID, and base resource reward. Inserting between existing entries changes their prerequisite chain; append for new end-game progression unless deliberately rebalancing.
2. Register `[DisplayName] = Id` in `ServerScriptService/BiomeTeleport/Destinations.lua`. This explicit travel allowlist remains intentional; the current menu sends DisplayName to the existing secured remote.
3. Place the authored biome region at `Workspace.<Id>` or `Workspace.World.BiomeBlockout.<Id>` / `Workspace.World.Biomes.<Id>`. Supply a real collidable floor named `<Id>Floor`, `Platform`, or `Ground`. Preserve manual art direction. Prefer an authored safe marker named `TeleportPoint`, `TeleportSpawn`, `SpawnPoint`, or `<Id>Spawn`; Landing validates support and clearance before creating the runtime destination marker.
4. Add the real pet definitions/assets and curate the `<Id>Egg` pool in `EggDefinitions.lua`. DropTables already derives ordinary resource rewards from BiomeDefinitions. If the reveal still uses an egg visual, import that model under `ReplicatedStorage.Assets.Eggs` using the configured ModelName.
5. For existing tree gameplay, use anchored authored trees with a recognized `SourceAssetName` or `TreeType` from `AuthoredTreeDefinitions.lua`; register a new authored tree family there when required. AuthoredTreeDiscovery assigns trees by real floor footprint and vertical context. A `Biome` or `BiomeName` attribute can disambiguate overlap. Do not tag decorative trees solely to make counts look complete.
6. Add optional card art to `StarterGui/AnimalKingdomUI/BiomeImages.lua`, keyed by DisplayName. The card layout and unlock action are generated automatically by ProgressionMenus.Biomes.
7. Test locked access, prerequisite purchase, safe travel, weather context, tree discovery, rewards, and the resulting Index entries. `EnvironmentAssets` and `BiomeAssets` provide organizational storage; no generic environment auto-instantiation pipeline is claimed.

The previous exact-300-pet assertion is now configuration-derived, with duplicate biome/rarity/pet guards. Teleport startup now checks each destination in the actual catalog, rather than assuming twelve marker children. Current twelve-biome data is unchanged. The legacy generated roster still exists: adding one biome creates its twenty-five legacy definitions as well as any explicitly imported entries. Curated pools and asset validation remain necessary.

### Add a normal Plot shop item without rewriting UI

1. Import a Model or BasePart into `ReplicatedStorage.Assets.<Category>` using its stable ModelName. Existing supported organization includes Furniture, Decorations, and Seasonal.
2. Add one keyed entry to `ShopDefinitions.lua`: `DisplayName`, `Category`, `ModelName`, existing `Currency`, nonnegative finite `Cost`, positive `Size = Vector3.new(...)`, and `MaxOwned`. Size defines the server placement fitting envelope.
3. For an ordinary always-visible item, omit `Season`. PlotMenu renders nonseasonal entries automatically; ShopService validates ownership limits and spends through EconomyService, and PlacementService clones/fits/checks the model on the owned plot.
4. Test purchase failure/success, inventory count, server-authorized placement, removal, and restoration. Missing non-pet assets still fall back to primitive geometry through AssetResolver, so confirm the real model resolves before treating the item as production-ready.

Seasonal shop entries are currently skipped by PlotMenu even during their active season. The server can validate Season, but no complete seasonal shop UI is claimed. `UpgradeId` delegates a shop purchase to UpgradeService; the existing Plot card still offers placement and assumes ordinary Cost/Currency fields, so it is not a complete generic upgrade-shop presentation.

### Add or tune an upgrade without rewriting its card

1. Add a unique entry to `UpgradeDefinitions.lua` using the existing `upgrade(displayName, key, maxLevel, initialCost, growth, effect, currency)` helper, or provide its equivalent fields (`DisplayName`, `Key`, `MaxLevel`, `Costs`, `Effect`, `Currency`).
2. For configuration-only behavior, choose an already consumed multiplicative modifier key such as `Coins`, `FriendshipTokens`, `Luck`, `HatchSpeed`, `GatheringPower`, or `ResourceRewards`. ModifierService applies every purchased definition matching a requested Key. Existing consumers also request `PetXP`, `RareDrops`, `SecretChance`, `MutationChance`, and `Shiny`.
3. ProgressionMenus.Upgrades automatically sorts and renders the new entry. UpgradeService handles cost, max level, and saved level; missing saved keys begin at zero. Test both the purchase and a real action consuming its modifier.
4. Capacity and immediate movement changes have ID-specific handling. Tune the existing `PetStorage`, `EquippedSlots`, or `WalkSpeed` entries when appropriate. A new ID with a capacity key does not automatically expand capacity; a new WalkSpeed-key entry does not itself trigger the existing ID-specific movement refresh. A genuinely new effect needs one authoritative consumer, even though its card needs no layout rewrite.

Garden has a separate existing catalog: add supplies to both `GardenDefinitions.Supplies` and `SupplyOrder`, using a supported Stat (`Luck`, `Yield`, `Speed`, `Starberry`, `Moonmelon`, or `XP`). Garden cosmetic visuals and Garden upgrade effects currently have explicit ID behavior; adding their data alone does not implement a new effect or wearable model.

## Verification and preserved state

The only additional catalog source edits from this audit were `SharedSource/Datas/PetDatabase.lua` and `ServerScriptService/BiomeTeleport/init.server.lua`. Their backups under this report's `before/` tree match the initial local-source manifest SHA-256 values. No existing pet IDs, biome destinations, profile data, or UI sources were changed.

Validation completed:

- Native Luau compilation of both modified catalog/startup sources.
- `tests/run_content_catalog_tests.py`: field-by-field equality of all 300 current generated records; a thirteenth biome yielding 325 records; duplicate rejection; current and expanded teleport catalogs; an unrelated marker child cannot conceal a missing destination.
- `rojo build default.project.json --output /private/tmp/ak-content-catalog-check.rbxlx` succeeded.
- `tests/run_garden_visual_scheduler_tests.py`: full render-rate updates, 30/120 FPS agreement, stable clones/scales, missing/restored marker and template recovery, cleanup, and Studio-only five-second sampler behavior.

The Garden client renderer uses `PetAppearance.Create(pet, "Garden")`, cached shared bounds, the actual authored SoilBase plane, frame-independent smoothing, 10 Hz crop updates, and 4 Hz state/status work. Its Studio sampler writes `AKGardenRenderAvgMs`, `AKGardenRenderPeakMs`, `AKGardenRenderFrames`, and `AKGardenRenderedPets` on PetGardenRealm. Those adapter tests are not measurements of Roblox rendering, GPU work, physics, mobile layout, or controller usability. Use the main Play report for actual observed results and unresolved visual issues.

The final screenshot review also identified misleading empty Garden world signs. The empty-state wording is now `SLOT n · AVAILABLE` in both GardenPlotRuntime's prepare/release/sync paths and the client status renderer; active expeditions retain their real phase or READY label. A scheduler regression verifies the empty label after an expedition clears. This changes world interaction text only, not ScreenGui styling or Garden state.
