# Animal Kingdom profile preparation repair — 2026-09-22

The current connected Studio place now allows the player to enter. Two consecutive actual Studio Play sessions reached Ready, opened the Garden UI, and released cleanly. No publishing was performed. A local repaired place copy is saved beside this report.

## A. Proven root cause

The running migration module had reverted to `Version = 2`, while the existing saved player profile had `DataVersion = 3` and `SchemaVersion = 3`. The migration's forward-version protection rejected that profile.

The same older sources existed in the actively synchronized local project. Comparison with the retained pre-redesign Studio source snapshot found eight Garden-related source rollbacks and three missing Garden modules. This source-version mismatch caused the failure; the Garden landscape geometry was not involved. The synchronized files and current Studio source now match (see `source-sync-verification.json`).

## B. Exact kick source and load path

- Issuing script: `ServerScriptService.ServerSource.Server.ProfileService`.
- Function: `HandlePlayerAdded`, originally line 84; the retained failure kick is now line 170.
- Condition: the protected preparation call failed after a profile session was acquired. Preparation called `AddUserId`, `Reconcile`, and `NormalizeAnimalKingdomData → ProfileMigrations.Apply`.
- Failing migration: `ReplicatedStorage.Shared.Gameplay.ProfileMigrations`, originally line 12, rejected saved versions newer than its supported version.

The full path is:

`SuperbulletServer → service registration → KnitStart → Players.PlayerAdded → ProfileService.HandlePlayerAdded → ProfileStore.StartSessionAsync → AddUserId → Reconcile(ProfileTemplate) → ProfileMigrations.Apply → Profiles[player] assignment → Sanctuary timestamp initialization → Ready/Loaded signal → DataController.GetPlayerData → gameplay UI`.

“Prepared” means the loaded data has been reconciled and migrated successfully, then made available through the active profile registry. Previously readiness was represented by that registry plus the existing `Loaded` signal and `WaitUntilProfileLoaded` API. The repair also exposes diagnostic `ProfileReady` and `ProfileLoadState` attributes.

Actual storage library: `ServerScriptService.ServerSource.Externals.ProfileStore`.
Actual store: `OriginalData1`, unchanged. Player key: `Player_3009757271`, unchanged.
The legacy `Externals.ProfileService` module is an unused compatibility wrapper, not a second active player loader. The existing duplicate-load guard remains; both tests observed exactly one loaded profile.

GardenExpeditionService has no eager PlayerAdded profile migration. Its operations use `PlayerDataService:Get`, which returns only active, prepared profiles, and handle unavailable data. The client waits through the existing DataController readiness path. No arbitrary startup delay was added.

## C. Captured preceding server error

The unmodified failing Play session produced:

```text
[ProfileService] Data preparation failed for Maciahxcx1: ReplicatedStorage.Shared.Gameplay.ProfileMigrations:12: Profile version is newer than this server
```

The data-preparation kick followed that migration exception. DataStore API access succeeded; this was not a request timeout or failure to acquire the session. Original evidence is in `failure-evidence.json` and `baseline-sources.json`.

## D. Changes

Core repair:
- `src/ServerScriptService/ServerSource/Server/ProfileService.lua`: honor Studio mock mode; seed it from a read-only snapshot of the same existing profile when APIs are available; prepare on a copy and restore original data on failure; log stage/version/traceback; validate saved types; expose readiness; retain genuine failure kicks; release on departure and shutdown.
- `src/ServerScriptService/ServerSource/Server/ProfileService.meta.json`: preserve the existing `AKUseMockProfiles = true` attribute through source sync.
- `src/ReplicatedStorage/Shared/Gameplay/ProfileMigrations.lua`: restore schema v3 compatibility, additive Garden defaults and recovery of malformed optional Garden values; preserve valid trips/cosmetics and fractional Sanctuary timestamps.
- `src/ReplicatedStorage/SharedSource/Datas/ProfileTemplate.lua`: restore Garden defaults.

Restored existing Garden integration from the retained good Studio snapshot, without redesigning rewards or expedition rules:
- `src/ServerScriptService/ServerSource/Server/GardenExpeditionService.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/GardenDefinitions.lua`
- `src/StarterGui/AnimalKingdomUI/GardenMenus.lua`
- `src/StarterGui/AnimalKingdomUI/Main.client.lua`
- `src/ServerScriptService/ServerSource/Server/GameplayService.lua`
- `src/ServerScriptService/ServerSource/Utilities/GameplayRequestPolicy.lua`
- `src/ReplicatedStorage/Shared/Gameplay/Definitions/CurrencyDefinitions.lua`
- `src/ReplicatedStorage/Shared/Gameplay/PetAppearance.lua`
- `src/ServerScriptService/ServerSource/Server/PetService.lua`

Mirrored the unchanged live `GardenPlotVisuals` into `src/StarterPlayer/StarterPlayerScripts/GardenPlotVisuals.client.lua` so source sync retains it.

Disabled the leftover Studio test harness `ServerScriptService.AKMeadowLiveVerification`, which grants test currency and changes tutorial state, and its temporary companion `StarterPlayer.StarterPlayerScripts.AKMeadowLiveObserver`. Their sources remain in the local place; they were not gameplay profile loaders.

Added manually run audit scripts under `tools/profile/`; these are outside the game source tree. Temporary runtime observers were removed automatically on Stop.

## E. Garden migration and saved types

Garden migration was involved because the v3 migration had been rolled back, not because the observed saved Garden data was malformed. The profile already contained 223 Harvest, FlowerCrown ownership, and an equipped FlowerCrown on a pet.

Defaults work when old profiles lack Garden fields. Valid existing Garden trips, unknown/future pet identifiers, extra fields, cosmetics, and timestamps survive. Malformed optional Garden data is archived under `RecoveryData.GardenMigration` rather than silently discarded. Recovery representations contain only serializable values.

Reviewed Garden writes: Harvest is numeric; cosmetic ownership is a string-to-boolean table; equipped cosmetics are string IDs on pets; trips contain primitive values/tables. Runtime character/model/CFrame values used for teleporting are not stored in the player profile. Crop split results are feedback payloads; Harvest is the persisted reward.

Nine regression cases passed, including actual v3 saved data preservation, migration idempotence, pre-Garden v2 defaults, legacy v0 fields, valid future trips, malformed optional fields, stable trip-ID defaults, unsafe optional value serialization, and rejection of future schema v4 before mutation. See `migration-test-results.json`.

## F. Studio mode and session locking

Session locking was not the cause. The read-only saved metadata had no active or force-load session. No lock was manually stolen or force-released.

The place already had `AKUseMockProfiles = true`, but the reverted loader ignored it and used live storage when APIs were enabled. The repair honors it in Studio using ProfileStore.Mock. It reads the existing saved profile once, without acquiring a live session, and exercises migrations against that copy. Subsequent gameplay changes stay in memory. If Studio APIs are unavailable, it explicitly reports use of the in-memory template.

Production continues using the same existing store. No API access setting was changed, no alternate persistent datastore was introduced, and no profile was reset. The vendor's generic API-available log is independent of the selected mock profile mode; the service logs and audited `is_mock = true` confirm both repaired tests used mocks.

Both Stop cycles fired Releasing, ended the session, removed the service's profile reference, and completed the mock final save. The second session loaded without a session-lock delay.

## G. Existing data preservation

Deep comparison of the full persistent `Data` before and after the repaired tests was equal. Saved metadata was also unchanged: `SessionLoadCount = 120`, `LastUpdate = 1790128144`, with no active lock.

Both tests loaded:
- Forest Coins: 671,917
- Friendship Tokens: 34
- Harvest: 223
- Pets / OwnedPets: 26 / 26
- Pet Index entries: 15
- Unlocked biomes: 2
- Displayed Sanctuary pets: 7
- Uncollected Sanctuary Coins: 66,109
- GardenCosmetics.FlowerCrown: true
- Existing equipped Garden cosmetic and all other saved fields preserved.

See `saved-profile-before.json`, `saved-profile-after.json`, and `persistent-data-comparison.json`. No currency refund/reset or other corrective edit was made to persistent data.

## H. Actual consecutive Play results

| Check | Session 1 | Session 2 |
|---|---|---|
| Entered without preparation kick | Pass | Pass |
| Ready / active single profile | Pass | Pass |
| Load time | 0.24 seconds | 0.11 seconds |
| Saved currencies, pets, index, Sanctuary loaded | Pass | Pass |
| Garden data and visible Garden UI | Pass | Pass |
| Mode | StudioMockSnapshot | StudioMockSnapshot |
| Stop / release / inactive / registry removed | Pass | Pass |
| Final mock save | Pass | Pass |

The second Play session reloaded the same existing saved snapshot after the first released. Screenshots: `session-1-garden.png` and `session-2-garden.png`. Runtime summaries and release Output logs are saved alongside them.

One unrelated pre-existing client issue remains: `StarterPlayer.StarterPlayerScripts.MeadowPetPreloader` references a missing `ReplicatedStorage.Shared.Gameplay.PetModelValidation` module. It does not prevent profile Ready, entry, or Garden UI operation; this repair does not reconstruct that separate Meadow preloader system.

Saved local place: `AnimalKingdom-Profile-Preparation-Repaired-20260922.rbxl` (10,114,073 bytes). Studio is left in Edit mode. Nothing was published.
