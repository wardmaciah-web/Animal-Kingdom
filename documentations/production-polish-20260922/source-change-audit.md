# Source preservation and final compile audit

Local audit completed 2026-09-23T07:27:52Z. Project: `/Users/jefferypryor/Documents/SuperbulletAI/Real_Animal_K`. No source or Studio changes were made during this audit. The project has no Git repository; targeted before-copies provide the change boundary.

## Preservation result

- Initial manifest: **140** source files, all recorded as matched to the connected Studio place before this pass.
- **129 unchanged**, **11 changed**, **0 removed**, and **7 intended new** non-Package runtime files.
- Every changed file has a before-copy whose SHA-256 exactly matches the initial manifest: **11/11**.
- All **13 StarterGui UI source files remain byte-for-byte unchanged**. This pass did not replace those screens or their theme.
- No changed or new non-Package source outside the intended list below was found. Package files were not in the initial preservation baseline; their current hashes are recorded without claiming before/after equality.

## Changed existing source

All paths below are relative to the project. Each exact initial backup is at `documentations/production-polish-20260922/before/<path>`.

| Source | Reviewed change |
| --- | --- |
| `src/ReplicatedStorage/Shared/Gameplay/Definitions/PetDefinitions.lua` | Adds canonical visual aliases and an empty future-import configuration list; existing species definitions retained. |
| `src/ReplicatedStorage/Shared/Gameplay/PetAppearance.lua` | Uses the canonical resolver and bounds-based contextual clone sizing/cosmetics; removes fabricated pet fallback visuals. |
| `src/ReplicatedStorage/SharedSource/Datas/PetDatabase.lua` | Derives count validation from the existing biome/rarity configuration and checks duplicate identifiers; existing generated records retained. |
| `src/ServerScriptService/BiomeTeleport/init.server.lua` | Checks each configured destination marker instead of assuming exactly twelve children. |
| `src/ServerScriptService/ServerSource/Server/GardenExpeditionService.lua` | Reuses safe landing for Garden visit/return; preserves the saved return on failure. Transaction/reward/profile lifecycle blocks unchanged. |
| `src/ServerScriptService/ServerSource/Utilities/GardenPlotRuntime.lua` | Matches Garden ownership by actual plot number, protects unverified geometry, marks generated locators, and supports custom crop mesh names. Empty slots now read AVAILABLE. |
| `src/ServerScriptService/ServerSource/Utilities/MeadowSanctuaryDisplay.lua` | Bounds/surface-aware display sizing and placement, canonical visuals, cached layout, and coalesced visual refresh. Existing authoritative displayed IDs retained. |
| `src/ServerScriptService/SuperbulletServerLogger/init.server.lua` | Prevents recursive transport diagnostics, bounds retry delays/buffering/shutdown, and resumes log delivery after backend recovery; Studio only. |
| `src/StarterPlayer/StarterPlayerScripts/GardenPlotVisuals.client.lua` | Smooths grounded cosmetic movement, separates status/crop update rates, cleans up streamed/removed slots, and adds Studio profiling. Empty slots now read AVAILABLE. |
| `src/StarterPlayer/StarterPlayerScripts/PetFollowing.client.lua` | Client-only smooth formations/heading/grounding/catch-up, bounded visibility/asset retries, and Studio profiling; authoritative equipped state unchanged. |
| `src/StarterPlayer/StarterPlayerScripts/SuperbulletClientLogger/init.client.lua` | Filters logger diagnostics and limits log payload size; retains the existing Studio-only rate limit. |

## New runtime source

| Source | Purpose |
| --- | --- |
| `src/ReplicatedStorage/Shared/Gameplay/FollowerFormation.lua` | Pure formation, stable phase, and frame-rate-independent interpolation rules. |
| `src/ReplicatedStorage/Shared/Gameplay/PetAssetValidator.lua` | Development asset/definition validation. |
| `src/ReplicatedStorage/Shared/Gameplay/PetModelResolver.lua` | Canonical model lookup and safe visual cloning. |
| `src/ReplicatedStorage/Shared/Gameplay/PetVisualGeometry.lua` | Shared visible bounds, orientation, normalization, fit, and grounding. |
| `src/ServerScriptService/AK_TownCollision.server.lua` | One-time application of inspected Town collision policy. |
| `src/ServerScriptService/PetAssetDiagnostics.server.lua` | Studio-only bounded diagnostic output and structured report. |
| `src/ServerScriptService/ServerSource/Utilities/TownCollisionPolicy.lua` | Explicit Town structural roles; collision/query restoration with original-value attributes, without transform/geometry edits. |

## Protected behavior and source

The profile service, external profile libraries, profile migrations/template, PlayerDataService, economy, Sanctuary income service, challenge service, biome/shop/upgrade/Garden data catalogs, PlotLocator, plot assignment, admin tools, and weather source all retain their initial hashes. The existing pet catalog generator has only configuration-based assertions added; its record construction is unchanged. PetDefinitions retains its initial definitions and appends visual aliases/configuration support.

The complete Garden transaction/reward/cosmetic block and profile lifecycle/scheduler block were also compared directly and are exactly unchanged. The Garden service diff is confined to a safe-landing dependency and visit/return movement. Collision policy changes only explicitly selected parts’ CanCollide/CanQuery and recording attributes; it contains no CFrame, size, geometry regeneration, or collision-fidelity mutation. Existing pedestals are read by the display adapter, not removed or replaced.

## Compilation and tests

All **453/453 current source files have matching-hash native Luau compiler passes**, with **0 failures**. The full scan completed 2026-09-23T07:20:44Z; the two final Garden label edits were recompiled at 2026-09-23T07:27:52Z, and the other **451 hashes were verified unchanged**. Coverage includes **147 non-Package files** and **306 package files**. Compiler: `/private/tmp/ak-production-luau-build/luau-compile`. This is syntax/bytecode compilation, not a substitute for engine or Play testing.

Targeted regression files added for this work include `tests/GardenPresentation.spec.lua`, `tests/StudioLogger.spec.lua`, `tests/GardenVisualScheduler.spec.lua`, `tests/FollowerFormation.spec.lua`, and `tests/ContentCatalog.spec.lua`, plus their runners and `tools/audit/pet_visual_geometry_test.lua`. Garden presentation and logger regression adapters passed directly during implementation. The owning catalog agent reports its existing-300-record comparison, 13th-biome/325-record case, duplicate guards, marker startup checks, and Rojo build passed; the owning visual agent reports its scheduler checks passed. Actual Studio results are recorded separately.

## Audit artifacts and limits

`current-source-manifest.json` records SHA-256, size, status, compile result, baseline hash where available, and exact backup hash for each changed source. Current hashes for `default.project.json` and package control files are recorded too; the initial source manifest did not include them, so this audit does not assert a session-long hash comparison for those controls.

This audit establishes local source preservation within the initial manifest. Live Studio source parity, saved place geometry, actual performance, visual quality, mobile/controller behavior, and two-client results require their separate evidence. No publish or Save As action was performed by this audit.
