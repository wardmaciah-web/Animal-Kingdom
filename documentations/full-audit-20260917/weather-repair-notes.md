# Weather audit and repair notes

Source audit and Luau verification completed September 17, 2026. Live visual verification is tracked by the main audit, separately from these source findings.

## Problems found

- WeatherEventService enabled TEST_MODE and forced automatic/admin events to 20 seconds with 10-second breaks.
- Blood Moon, Rainbow, Aurora, and Void used a LocalCFrame list repositioned from the camera each RenderStepped. Their world locations changed with camera rotation and movement.
- Meteor and lightning creation used the camera-oriented precipitation rig, changing the apparent weather direction whenever the player turned.
- Precipitation inherited camera rotation, tilting its emission volume when looking up/down.
- Every custom event image card omitted the dynamic countdown; only the unused fallback card had one.
- The visual controller eagerly created neutral Lighting/Terrain effects during the initial Break, without removing them until an event had finished.
- Existing automated/live admin tests assumed the obsolete 10/20-second timing.
- Live testing exposed an additional preload API issue: all 18 raw-string image preload requests reported Failure. Roblox documents typed instances as the supported preload input, and its engine team identifies generic content strings as unreliable for image preloading.

## Changes

- Production service now declares TEST_MODE=false, BREAK_DURATION=5*60, EVENT_DURATION=7*60. No short-duration override remains. EventDefinitions uses 7*60 for all normal and secret event durations. WeatherState exposes TestMode, BreakDuration, and EventDuration for diagnostics.
- BloodMoonAnchor is permanently positioned at **(-6338, 8008, -23752)** during its event. A 1900-stud world BillboardGui, parented to the anchored Workspace part, draws a shaded disc/craters. AlwaysOnTop=false permits scene occlusion. Each normal Sky MoonAngularSize is captured, hidden during Blood Moon, and restored on every event transition/end/reset.
- RainbowAnchor is permanently positioned at **(-500, 60, -2200)**. Fourteen curved Beams make seven colored semicircular bands; the outer radius is 1204 studs, band spacing 24.64, and width 24.08. Their attachments never move. Each Beam uses 64 segments, zero LightEmission, and 0.15 transparency. The initial much farther anchor was not visibly rendered in Studio and was corrected after screenshot verification. Rainbow visibility uses a clearer atmosphere and long fog distance appropriate to its horizon location.
- AuroraAnchor is fixed at **(-500, 850, -1700)**, with five curved ribbons, 64 segments, and faded endpoints. Its geometry was reduced by half and the preset now uses FogEnd 100000 and Atmosphere density 0.15 following live rendering verification. VoidAnchor is fixed at **(-338, 108, 18)** with seven deterministic wisps.
- Meteors originate around **(-338, 1508, -1952)** and travel along a consistent world direction. Lightning originates around **(-338, 658, -852)**. Temporary strikes, trails, bursts and sounds remain event-owned and generation-guarded.
- Only the local precipitation volume tracks camera position, without camera rotation, at 20Hz. No RenderStepped or per-frame sky-part loop remains. Spirit orbs spawn in this local weather volume and then animate through world space without following view rotation.
- Custom image cards receive a readable countdown footer using replicated EndsAt minus Workspace:GetServerTimeNow(). No independently accumulated client countdown exists.
- Effects are created only when an event starts. Existing Lighting/Terrain snapshots and generation-safe cleanup remain intact.
- Image preloading now passes temporary ImageLabel instances carrying the original artwork IDs, then destroys the preload instances. No uploaded artwork IDs were replaced.

## Verification

- Passed `python3 tests/run_admin_command_tests.py --luau /private/tmp/ak-phase2-luau-build/luau`. Tests cover explicit production timing, manual duration, automatic cycling, queue transition/clear, pause/resume, emergency reset, and stale timer cancellation, along with existing permission/dispatcher/spectate tests.
- All four changed runtime files and both Studio test files compile with the native Luau compiler.
- Added `tests/WeatherAudit.studio.client.lua`: run in CLIENT Command Bar during a fresh Studio Play session's initial Break. It checks all 18 event starts/ends, effect collision flags, authoritative countdowns, Lighting/Atmosphere/Clouds/Sky restoration, sound destruction, fixed anchors during camera rotation/translation, rainbow Beam count, and rapid replacement cleanup. This test injects state locally; the admin suite separately covers authoritative server behavior.
- Updated `tests/AdminCommandCenter.studio.client.lua` to end a queued event through the existing admin remote and assert production deadlines instead of waiting for obsolete test durations.
- The all-event Studio lifecycle test completed at 22:02:57 UTC: **18 events, 134 assertions passed, 0 failures**. The exact output is preserved in `weather-live-test-results.txt`. This verifies cleanup, timers, anchors, and replacement behavior against the actual controllers.
- Final screenshot assessment confirms the revised Rainbow, Aurora and Blood Moon are visible in world space; see `rainbow-final.png`, `aurora-final.png`, and `blood-moon-final.png`, with separate away-facing evidence for Rainbow/Blood Moon. The preserved custom artwork and live countdown are also visible in these captures. Aurora remains a stylized ribbon effect.
- After final visual adjustments, the complete lifecycle test ran again and completed at **22:58:34 UTC: 18 events, 0 failures**. Exact output: `weather-final-live-test-results.txt`.

## API references checked

The world BillboardGui uses a stud-sized canvas and ordinary 3D occlusion as documented in [BillboardGui](https://create.roblox.com/docs/reference/engine/classes/BillboardGui/LightInfluence). The rainbow uses [Beam cubic control points](https://create.roblox.com/docs/reference/engine/classes/Beam). Normal moon hiding uses [MoonAngularSize=0](https://create.roblox.com/docs/environment/skybox), with restoration of its original value after the event.

Image loading follows the current [ContentProvider API](https://create.roblox.com/docs/reference/engine/classes/ContentProvider) and [Roblox engine team's explanation of typed image instances](https://devforum.roblox.com/t/contentproviderpreloadasync-does-not-preload-image-or-texture-assets-in-either-assetid-form-or-instance-form-appears-to-be-a-regression/1637450/25).

Final render corrections: Rainbow radius1204/bandwidth24.08,64segments,LightEmission0,transparency0.15. Aurora scaled0.5 with endpointfade. BloodMoon fogdistance100000/density0.2 preserves red lighting while revealing lunar surface detail; Aurora fogdistance100000/density0.15 prevents its world ribbons being lost in haze.
