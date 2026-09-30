# Animal Kingdom — Tutorial and Held Quick Actions
Date: 2026-09-26
Project: /Users/jefferypryor/Documents/SuperbulletAI/Real_Animal_K

Implemented in source and synchronized to the connected Studio's matching script instances. Studio is stopped. Nothing was published. Only 17 intended Lua source files changed; the Rojo project mapping and imported Workspace content were not replaced. The Studio-only AK_NewMeadowTreeRuntimeRegister remains present and unchanged.

## Presentation

TutorialGuidance replaces the former Continue-driven tutorial presentation with one compact wood/parchment message and a completion card. It observes the existing replicated profile and server-selected session tree; it does not award, move, sell, or credit anything.

TutorialPointer reuses the existing Pets paw from the Animal Kingdom icon atlas. It smoothly follows runtime targets, clamps to safe-screen bounds (including viewport changes), hovers above button text, gently bobs, and pulses the existing button's MotionScale up to 1.055. Reduced Motion removes bobbing and rotation and uses a near-static 1.0012 scale emphasis. No external asset was imported.

The ground arrow is a client-created model containing three gold parts. All are anchored, non-collidable, non-touchable, and non-queryable. It projects onto ground beneath the character, follows the feet, and turns toward the current target. It is destroyed near the interaction, between steps, on death, at completion, and when the UI is destroyed. A local gold highlight emphasizes the real tree/slot/collector near the target. No server arrow exists.

The first Biomes screen opens automatically after profile, UI, character, and plot readiness. Later navigation uses the existing Biomes button and existing Your Sanctuary destination. Menu closure does not skip objectives; the paw guides reopening or closing the needed screen.

## Persistent steps and authoritative confirmation

| Step | Guidance | Required evidence |
| --- | --- | --- |
| 1 | Open Biomes; point at Meadow Travel | Server BiomeService:AtPosition confirms the living character in unlocked Meadow, outside Garden. |
| 2 | Random valid Meadow tree; arrow then existing Search prompt | Existing EggService.Hatched fires after successful reward commitment with the result's exact owned UID. Server records that UID and the minimum reveal time. The client acknowledges only after reveal presentation closes; server checks exact ownership, matching UID, and elapsed authoritative duration. No button-click completion or extra reward. |
| 3 | Select exact occupied Held slot when needed; Biomes → Your Sanctuary | Exact target UID must be canonical ActiveHeldPetUID in Held, then existing PlotService:IsNearOwnPlot confirms arrival. |
| 4 | Arrow to selected real empty physical Sanctuary slot; existing PLACE | Exact UID must be Location Sanctuary at the selected valid LocationSlot. A different live slot does not satisfy the objective; guidance uses the existing PICK UP action to recover it. |
| 5 | Existing own collection pad | Existing PlotService:Collect emits Collected only after a positive authoritative credit. TutorialService also verifies the target pet remains in the valid Sanctuary slot. Zero credit cannot complete it. |
| 6 | Congratulations; COMPLETE TUTORIAL / RESTART TUTORIAL | Complete sets the existing TutorialCompleted flag. Restart resets only tutorial guidance. Both requests require server-verified step 6. |

A client reveal acknowledgement is presentation feedback, not proof of a pet award: the award UID and timing are already recorded by the server. On reconnect, an already committed reward resumes from canonical ownership; missed/rebuilt presentation can recover without awarding again.

Tree selection uses ResourceService's actual registered AVAILABLE Meadow records, prompt availability, current reward-pool/model readiness, Meadow floor bounds, and a successful PathfindingService approach. Selection is random among validated candidates. Unavailable trees are replaced. The tree reference lives only in a session ObjectValue; no Instance is saved.

## Profile compatibility and interruption recovery

Reused TutorialProgress.Step and TutorialCompleted in the existing ProfileService/player-data pipeline. No new datastore, profile service, inventory, currency, or completion flag.

Small additional fields inside TutorialProgress:
- FlowVersion = 2 distinguishes this flow from the old fourteen-step flow.
- LegacyStep preserves the prior step for incomplete legacy profiles.
- PetUID records the exact canonical tutorial companion.
- SlotId records the selected physical slot.
- RevealReadyAt records the minimum presentation deadline and is cleared after reveal acknowledgement.

Existing completed profiles remain completed. Incomplete old tutorial progress starts the new guidance while retaining old flags/history. ProfileTemplate, ProfileMigrations, ProfileService, and datastore naming were not changed.

Reconciliation waits for character and plot readiness, including initial spawn/respawn. It re-evaluates ownership, location, active UID, valid physical slots, and arrival. Stored target pets are guided back through All Pets; Garden pets are not moved automatically. Missing/unusable targets can use another canonical owned companion. An already placed companion on resume advances to collection. A full pre-existing Sanctuary can demonstrate its existing income. UI targets are found again after menu rebuilds, and prompt presenters reconnect after complete ScreenGui replacement.

Restart clears only the guidance UID/slot/reveal deadline and resets Step to 1, leaving TutorialCompleted false. It does not alter pets, coins, Index, Garden, upgrades, or placements and grants no special starter reward.

Starting balance remains 250 Forest Coins; normal Meadow search costs 250, so no starter-economy grant was added. A replay/recovery below search cost can use an already owned companion. A narrow temporary sale guard keeps the sole tutorial companion if selling it would leave no pet and insufficient coins for another normal search. It also handles an entire Sell All batch. This adds no saved lock flag and ends once the tutorial is completed.

## Held quick actions

The existing five-slot bar remains the only Held hotbar.

Clicking an occupied slot requests the existing Equip action for that exact UID. The popover opens after successful selection and canonical ActiveHeldPetUID agreement; clicking an already active pet opens it directly. Empty slots do nothing. The small wood card sits above the chosen slot and contains exactly:
- SELL HELD PET
- STORE PET

Sell uses the existing PetService:Sell transaction and SellValueCalculator, with an explicit Held mode. Server validates ownership, Held location, exact active UID, canonical protection rules, trip references, value, and currency cap. It removes ownership and credits Forest Coins in the same non-yielding transaction. Replayed sales fail. The existing publish/rebuild clears the Held slot and active overhead UID. Locked, Favorite, Secret, Prismatic, and definition-protected pets remain protected. Sell All remains Inventory-only.

Store calls the existing MovePet request / PetService:Move to Inventory. It preserves the exact owned record and every stat, frees its Held slot, and clears the active UID as needed.

The popover closes on success, outside click/tap, another Held selection, menu opening, reveal opening, or ownership/location/active-selection change. Buttons are 44 pixels tall. The focus graph links the two actions; closing restores the normal HUD graph. Existing Back handling closes it before normal menu navigation. During the guided hold step, canonical selection closes the popover and moves guidance toward Biomes.

## Exact source files

- src/ReplicatedStorage/Shared/Gameplay/Definitions/TutorialDefinitions.lua
- src/ReplicatedStorage/Shared/Gameplay/SellValueCalculator.lua
- src/ServerScriptService/ServerSource/Server/EggService.lua
- src/ServerScriptService/ServerSource/Server/GameplayService.lua
- src/ServerScriptService/ServerSource/Server/PetService.lua
- src/ServerScriptService/ServerSource/Server/PlotService.lua
- src/ServerScriptService/ServerSource/Server/TutorialService.lua
- src/ServerScriptService/ServerSource/Utilities/GameplayRequestPolicy.lua
- src/StarterGui/AnimalKingdomUI/AnimalKingdomUIV2/MenuManager.lua
- src/StarterGui/AnimalKingdomUI/AnimalKingdomUIV2/TutorialPointer.lua
- src/StarterGui/AnimalKingdomUI/HatchPresentation.lua
- src/StarterGui/AnimalKingdomUI/HeldPetActions.lua
- src/StarterGui/AnimalKingdomUI/HeldPetsBar.lua
- src/StarterGui/AnimalKingdomUI/Main.client.lua
- src/StarterGui/AnimalKingdomUI/TutorialGuidance.lua
- src/StarterPlayer/StarterPlayerScripts/KingdomPrompts.client.lua
- src/StarterPlayer/StarterPlayerScripts/SanctuaryInteraction.client.lua

Added test: tests/tutorial-held/Backend.server.lua. It is outside the Rojo source tree and asserts Studio mock profile mode before changing test data.

## Verification

- Rojo build passed: /tmp/AnimalKingdom-tutorial-held-final.rbxlx.
- All 17 changed/new sources compile in Studio and exactly match filesystem source.
- Final backend regression: 41 assertions passed; see backend-results.json.
- Clean/mock first-player UI flow exercised: automatic Biomes, actual Travel clicks, random real registered Tripo Meadow tree, normal E search/charge/reward/reveal, exact Held selection, Sanctuary travel, exact chosen slot PLACE, physical positive collector payout, and Complete.
- Final full-flow reward example: UID 221c2f8d-c49d-4102-b553-ad6ba6f71d0d, Daisy Hedgehog, Weight 1.59, XP 10, Level 1, 4.94 coins/sec. One canonical record moved Held → Sanctuary slot 1. The normal search charged 250 and existing loot returned the balance to 151. Physical collection credited 77 and retained its fractional balance. No special tutorial pet or currency was granted.
- The same exact pet was picked up, stored through the actual quick-action UI, re-held, and sold through that UI. Store retained UID and stats. Sale credited its existing value of 29 once, cleared the slot and active UID, and removed the record. Locked Sell was disabled.
- Backend regression additionally checked early completion/restart rejection, forged reveal UID rejection, duration gating, legacy compatibility, wrong-slot rejection/recovery, zero-credit rejection, restart preservation, mock save/readback, completed-profile suppression, protected Held sales, sale replay, inactive UID rejection, Store stat preservation, Inventory-only Sell All, onboarding sale safety, and UID uniqueness.
- Restart clicked through actual UI preserved pets, currency, and placements and restarted guidance.
- Tree unavailability caused reselection of a different valid registered tree.
- Death/respawn preserved the exact tutorial UID/major step and restored guidance.
- Closed Biomes guided reopening; rebuilt runtime target objects rebound.
- Saved step 4 was read from the existing mock ProfileStore, transferred into the same existing mock profile pipeline in a fresh Studio Play session, and resumed with the same UIDs/stats. This was a simulated reconnect test, not a production datastore/network rejoin.
- Repeated full ScreenGui destruction/recreation retained prompt binding and Back binding. Exact PLACE still worked afterward. Stale old UI observers were fixed and the final rebuild run produced no related runtime errors.
- Reduced Motion verified: paw rotation zero, no bobbing, real prompt still targeted.
- Desktop and iPhone portrait simulator screenshots inspected for message, paw, completion card, and quick actions.
- Two-action focus links and return to HUD navigation verified. Synthetic ButtonB is blocked by Studio/CoreGUI, so physical controller Back remains untested.
- Popover closes on actual reward reveal and outside click. During tutorial selection, the final test changed paw target HeldSlot_1 → Nav_Biomes with the popover closed.
- Server confirmed no TutorialGroundArrow; local arrow components had collision/touch/query disabled.
- Final Edit inspection found no temporary QA scripts/arrow objects; Studio stopped.

Limitations: no physical phone/controller testing and no production/network rejoin test. No publishing or intentional live datastore writes. Existing unrelated startup notices about unavailable future pet assets remain outside scope. No implementation blocker remains for these features.

## Safety and rollback

Source snapshots of the current cleanup baseline are under before/. baseline-sha256.json identifies the original files. changed-files.json records the final 17 paths and hashes; changes.patch contains the full source diff. The three new modules can be removed and the fourteen modified source files restored from before/ if rollback is needed, followed by the same explicit script-only Studio comparison/sync.

The paused Rojo server was not resumed. Imported world content, the custom Meadow registration script, Town, weather, Garden, player plots, Sanctuary geometry, and world scale were not modified by this task. The existing collector and existing travel/placement/reward pipelines remain in use.
