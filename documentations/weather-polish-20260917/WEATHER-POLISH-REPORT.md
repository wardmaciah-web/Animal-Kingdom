# Animal Kingdom — weather VFX and SFX polish

**Status: final sources installed; the 18-event sweep and extended live sequence/celestial checks passed. The dedicated meteor lifetime check, live admin regression and full-place recovery save remain pending.** This report distinguishes completed tests from the remaining verification.

The existing weather service, admin architecture, queue, emergency reset, commands, event cards, replication contract and production timing are preserved. This phase changes client presentation only. It does not add pets, eggs, gathering, economy, progression, challenges, furniture or decoration placement.

The final eight presentation sources were installed in EDIT mode at **2026-09-18 00:51:05 UTC** (September 17, 5:51:05 PM Pacific). A fresh Studio Play sweep completed at **00:55:34 UTC** with **181 assertions, zero failures** across all 18 events, 360-degree camera rotations, real character walking, cosmetic safety, object/audio budgets, cleanup, baseline Lighting/wind restoration and rapid Low-quality switching. This run includes the revised Void planets, Aurora ribbons, world stars, readability changes and aligned audio stages. The [final sweep log](final-studio-sweep.txt), [installation log](final-source-install.txt) and [refreshed event captures](views/) provide the evidence. The [extended live test](extended-studio-test.txt) then completed at **2026-09-18 01:05:02 UTC** with **100 assertions, zero failures**, in 114.08 seconds. It observed actual thunderstorm strikes, complete Chaos/Admin combination stages, celestial projection/rotation/translation behavior, continuous object/audio peaks and full baseline cleanup. The dedicated meteor lifetime and live admin checks remain pending.

Six existing audio recordings successfully loaded in live Studio. **69 specialized SFX slots remain unassigned**, so finished, unique audio for all 18 events is not claimed. Empty slots safely use a documented appropriate fallback or remain silent. No headphone listening or subjective sound-mix review was performed; loading/synchronization tests do not establish how polished the mix sounds. The full assignment list is in [MISSING SFX ASSETS](AUDIO-MANIFEST.md#missing-sfx-assets).

## 1. Files created

Five presentation modules:

| File | Responsibility |
|---|---|
| [WeatherCelestialEffects.lua](../../src/ReplicatedStorage/Shared/WeatherCelestialEffects.lua) | Fixed world moon, rainbow, flowing Aurora, stars, distant planets, orbital satellites and Admin sky beams |
| [WeatherEnvironmentEffects.lua](../../src/ReplicatedStorage/Shared/WeatherEnvironmentEffects.lua) | World mist/particles, ground accents, orbs, lightning, fire/magic bursts and event combination stages |
| [WeatherVFXQuality.lua](../../src/ReplicatedStorage/Shared/WeatherVFXQuality.lua) | Cosmetic quality/intensity resolution, independent of server state and audio |
| [WeatherSoundDefinitions.lua](../../src/ReplicatedStorage/Shared/WeatherSoundDefinitions.lua) | Central sound IDs, missing upload slots, fallback mappings, 18 mixes, cue variants and ranges |
| [WeatherAudioController.lua](../../src/ReplicatedStorage/Shared/WeatherAudioController.lua) | Layered global ambience, positional cues, synchronized thunder, fades, voice budgets and cleanup |

New verification scripts:

- [WeatherPolish.studio.client.lua](../../tests/WeatherPolish.studio.client.lua): all-event walk/rotation/budget/cleanup sweep and Low switching.
- [WeatherPolishExtended.studio.client.lua](../../tests/WeatherPolishExtended.studio.client.lua): longer storm/Chaos/Admin observation, celestial projection checks, positional audio, scene queries and complete baseline restoration.

Documentation/evidence: [AUDIO-MANIFEST.md](AUDIO-MANIFEST.md), this report, [final source installation](final-source-install.txt), [final Studio sweep](final-studio-sweep.txt), [earlier Studio sweep](first-studio-sweep.txt), [live audio asset checks](audio-assets-live.txt), [audio lifecycle tests](audio-mock-results.txt), [extended Studio test](extended-studio-test.txt), [build/regression results](final-build-and-regression.txt), and [final-source images](views/).

## 2. Files modified

| File | Change |
|---|---|
| [WeatherVisualController.client.lua](../../src/StarterPlayer/StarterPlayerScripts/WeatherVisualController.client.lua) | Connects the existing weather state to the focused VFX/audio modules; keeps transition/baseline ownership; uses bounded weather updates and quality-scaled precipitation |
| [MeteorShowerEffects.lua](../../src/ReplicatedStorage/Shared/MeteorShowerEffects.lua) | Varied fast world meteors, large strikes, cosmetic 30-second craters, fire/trails/smoke/shockwaves and centralized positional sound hooks |
| [SpiritNightEffects.lua](../../src/ReplicatedStorage/Shared/SpiritNightEffects.lua) | More local ghosts/wisps, fixed logical world paths, scalable particles and actual ghost-position pass/whisper cues |
| [WeatherAudit.studio.client.lua](../../tests/WeatherAudit.studio.client.lua) | Updated managed-container/world-effect expectations |
| [WeatherPhenomena.studio.client.lua](../../tests/WeatherPhenomena.studio.client.lua) | Updated meteor/spirit verification for the current modules |

The server [WeatherEventService.lua](../../src/ServerScriptService/ServerSource/Server/WeatherEventService.lua) remains authoritative. Its defaults remain `TEST_MODE = false`, `BREAK_DURATION = 5 * 60`, and `EVENT_DURATION = 7 * 60`.

## 3. VFX architecture

The existing `WeatherVisualController` reads `WeatherState` and starts one presentation runtime per event. It continues to own the Lighting, atmosphere, clouds, post-processing and wind baseline. Helper modules expose `Start(...)` and return idempotent cleanup callbacks; only modules needing animation connect a bounded Heartbeat update.

```text
Workspace
  WeatherWorldEffects                 client-only, one active event
    CelestialEffects
    WeatherEnvironment
    MeteorShowerEffects               when applicable
    SpiritNightWorld                  when applicable
    WeatherEmitterRig                 precipitation when applicable
    EventAudio                        fixed positional audio anchors

SoundService
  AK_WeatherAudio
    WeatherMix
    <EventId>
      Ambience / WeatherLoops / WorldSFX / ImpactSFX
      MagicalSFX / CelestialSFX / TransitionSFX
```

Logical celestial centers and weather choreography use world coordinates and the server clock. Nearby particles use a finite set of world cells selected by character position. The precipitation rig advances between world grid cells as the character travels; camera rotation never moves or rotates environmental objects. Spawned particles are not locked to moving emitters.

No new server gameplay timer, remote protocol, event scheduler or admin system was introduced.

## 4. Effects added to all 18 events

| Event | Current visual presentation |
|---|---|
| **Sunny Skies** | Bright clear daylight, light clouds moved by global wind, subtle sun rays, sparse golden pollen and soft petal glints |
| **Rainy Day** | Visible falling rain, gray clouds, moderated blue-gray atmosphere, low mist and ground splash particles |
| **Thunderstorm** | Heavier/faster rain, wind streaks, dark clouds, fixed world lightning bolts, cosmetic strike sparks/mist/shockwave and a brief illumination flash |
| **Snowfall** | Snow with size variation and drift, pale cold lighting, winter ground mist, periodic stronger local snow gusts |
| **Foggy** | Readable near-field fog, rolling low mist and elongated drifting wisps, subdued light and reduced distance visibility |
| **Windy** | Fast wind streaks, rotating leaf glints, dust, stronger gust bursts and moving clouds; map props remain stationary |
| **Heatwave** | Warm sun, dry dust, rising horizon shimmer, restrained oscillating blur and dry gust accents; no map-wide fire |
| **Aurora** | Night sky, fixed-region flowing green/cyan/purple ribbons with soft glow bands, twinkling world stars and occasional ground magic glints |
| **Blood Moon** | Large distant red moon with crater details/corona, red sky/cloud/fog treatment, world stars, floating red embers, shadow wisps and subtle light pulses |
| **Meteor Shower** | Repeated diagonal glowing meteors, varied sizes/speeds/paths, fire/smoke/Trails, occasional large ground strikes, expanding impact flash/ring, dust and temporary scorched/rubble/crack details |
| **Spirit Night** | Blue/green/purple low mist, more firefly-like sparkles, nearby glowing cartoon ghosts with faces, drifting wisps and floating movement on fixed world paths |
| **Rainbow** | One large seven-color world horizon arc, bright clear light, local rainbow glitter and occasional colored sparkle bursts |
| **Chaos** | Smooth unusual color shifts, colored orbs/sparks, sparse meteors and a four-stage rain/lightning → fire → snow/magic → energy sequence |
| **Inverted** | Unnatural green/monochrome treatment, rising white/falling black flecks, rotating geometric objects and a synchronized geometric magic accent |
| **Nightmare** | Dark purple/red fog, crawling shadow mist, black ash, distant pairs of glowing eyes, occasional red lightning and restrained dark pulses |
| **Void** | Dark purple cosmic atmosphere, distant ringed planet and blue moon, orbital satellites, world stars, nebula mist, ground energy orbs/dust and purple energy strikes |
| **Golden** | Warm golden lighting, gold dust, soft world golden rays, glitter/haze and bright local star bursts |
| **Admin Abuse** | Controlled strongest combination: rainbow, distant ringed celestial object, animated colored sky beams, stars/nebula, meteors, colored orbs and a faster four-stage lightning/fire/snow-magic/energy sequence |

Map surfaces/materials are never permanently changed by these events. Meteor scars are temporary cosmetic objects resting above valid support, not excavated Terrain or gameplay destruction.

### SFX by event

The table describes the implemented mix and synchronized hooks. Specialized empty slots do not produce invented sounds. “Fallback” means one of the verified existing recordings; the complete per-layer volumes, variants and missing assignments are in [AUDIO-MANIFEST.md](AUDIO-MANIFEST.md).

| Event | Ambience loops | Randomized / positional / impact cues | Start cue | Cleanup |
|---|---|---|---|---|
| Sunny Skies | Day bed (soft wind fallback), foliage slot | Bird variants when assigned | Ambience fade | Shared cleanup below |
| Rainy Day | Moderate rain, distant rain slot, breeze | Drip slot; positional splash with built-in fallback | Rain fade | Shared cleanup |
| Thunderstorm | Heavy rain, storm wind, rain impact bed slot | Visible-strike close/distant thunder with distance delay and slight pitch variation | Storm fade | Shared cleanup |
| Snowfall | Cold wind, winter ambience slot | Wind cue when snow gust occurs | Cold fade | Shared cleanup |
| Foggy | Quiet drone (eerie-wind fallback), low wind | Rare distant forest cue slot | Subdued fade | Shared cleanup |
| Windy | Wind, foliage rustle slot | Actual gust-position wind variants | Wind fade | Shared cleanup |
| Heatwave | Dry-wind fallback, insect ambience slot | Actual dust-gust positional cue | Dry fade | Shared cleanup |
| Aurora | Aurora-pad/shimmer slots, soft night air | Airy sweep slot; chimes at actual sparkle bursts | AirySweep slot | Shared cleanup |
| Blood Moon | Ominous drone fallback, distant wind | Rare pulse/dark texture/howl slots | BloodMoonStart slot | Shared cleanup |
| Meteor Shower | Sky-rumble slot, night air | Moving meteor whoosh; landing impact; rock debris/fire burst/crackle slots; larger cues have greater reach | First actual meteor flyby | Shared cleanup |
| Spirit Night | Spirit bed fallback, air, shimmer slot | SpiritPass every about 11s near an actual ghost path; rare SpiritWhisper every third cue when assigned | Spirit-bed fade | Shared cleanup |
| Rainbow | Pleasant magic/glitter slots, breeze | Crystal/chime cue at actual glitter burst | RainbowStart slot | Shared cleanup |
| Chaos | Warp fallback; rain/cold wind match visual stages | Actual lightning, meteor, fire, magic and energy hooks; rare reversed sweep slot | Warp fade | Shared cleanup |
| Inverted | Warped ambience fallback, cold air | Reverse sweep slot; MagicZap tied to visible geometric accent | ReverseSweep slot | Shared cleanup |
| Nightmare | Dark-drone fallback, cold wind | Rare pulse/stinger slots and red-lightning thunder | Drone fade | Shared cleanup |
| Void | Cosmic ambience fallback, rumble/shimmer slots | Cosmic tone slots; EnergyStrike at actual purple lightning | VoidStart slot | Shared cleanup |
| Golden | Treasure/shimmer slots, warm air | Golden chime variants at actual star bursts | GoldenStart slot | Shared cleanup |
| Admin Abuse | Warp fallback; rain/cosmic stage layers | Actual thunder, meteor, fire, magic/energy cues, sparse warp/cosmic sweeps | AdminStart slot | Shared cleanup |

Shared audio cleanup: stop accepting new cues, cancel delayed cues, destroy world sounds with their event objects, fade global ambience over 1.2 seconds, then disconnect/destroy every owned voice and container. A direct event replacement immediately clears the preceding audio session before starting the new one. Optional `EventEnd` is an empty slot governed by the same cleanup deadline.

## 5. World-space effects

Blood Moon, Rainbow, Aurora paths, stars, planets/satellites, meteors, impact scars/fire/dust, lightning, environmental orbs/ghosts, golden rays, ground mist and weather cells all exist under the client Workspace runtime.

BillboardGui is used as a rendering surface for distant celestial objects. Its parent/Adornee is a fixed Workspace anchor, its size is in studs, and `AlwaysOnTop = false` allows map occlusion. It is not a ScreenGui or PlayerGui overlay. Beam `FaceCamera` keeps thin ribbons readable without relocating their anchored paths.

Planet satellites orbit their distant world centers intentionally. Aurora attachment motion bends ribbons within the same sky region. These animations are driven by server time, not camera transforms.

## 6. Screen-space effects

Supplemental screen presentation is limited to the existing event cards, existing UI, ColorCorrection/Bloom/SunRays and small weather blur/dark-light pulses. Lightning briefly raises illumination for approximately 0.32 seconds. Heatwave blur is restrained. No persistent screen image represents the moon, rainbow, meteor, lightning, planet or impact.

## 7. Blood Moon implementation

Fixed anchor: **`(-6338, 8008, -23752)`**.

A **5600 × 5600-stud** anchored world BillboardGui contains a shaded red face, nine crater details and five faint pulsing corona rings. The visible face occupies 79% of that square. Its large world size makes it appear distant and recognizable across the map rather than hovering beside the player.

The celestial helper snapshots each normal Sky's `MoonAngularSize`, hides the normal moon during Blood Moon, and restores the original value during cleanup. It also handles a Sky added while the event is active. Camera movement does not update the anchor or billboard size. Looking away naturally removes it from view; buildings can occlude it.

## 8. Rainbow implementation

Fixed anchor: **`(-500, 60, -2200)`**.

Seven colors use two curved quarter-circle Beams each: **14 Beams total**, outer radius **1204 studs**, with deliberate horizon placement. The world arc is also reused by Admin Abuse. Attachments and the anchor remain fixed for the lifetime of the event. Arc objects are destroyed on end/reset/replacement.

## 9. Meteor Shower implementation

Small meteors follow seeded world trajectories derived from the authoritative event start time. They cross diagonally at different heights, sizes and durations, with glowing bodies, Trail, fire sparks and smoke. High quality uses two small flight lanes; Low reduces the decorative count while retaining recognizable activity.

A large meteor is scheduled from about five seconds into the event, then approximately every **14 seconds** (every 28 seconds in Chaos). Its flight lasts **2.25 seconds**. An impact is created only if a raycast finds a sufficiently open supported location; blocked locations are skipped. A maximum of 18 flights is allowed at High quality, reduced at lower settings.

Large impacts create a brief flash, expanding shockwave ring, fire/dust burst, warm embers, scorch circle, cooling glow, grounded rubble and small cosmetic cracks. Each impact's lifetime is **30 seconds from impact**, with the final four seconds fading away. No authored part is recolored, resized, unanchored or deleted; no damage or physical Explosion is used.

Flyby sounds parent to the moving meteor. Impact cues originate at the exact hit position. The current fallback for a meteor explosion is filtered existing thunder; dedicated rock/impact/fire recordings remain upload slots. Audio guards prevent a duplicate fire request from stacking.

**Final-revision live observation of an entire 30-second crater lifetime remains pending.** Source lifetime checks and the earlier meteor-specific test do not replace that final live observation.

## 10. Thunderstorm lightning

Approximately every 8.5 seconds, a seeded safe open ground location is selected. Candidates within 45 studs of a player are rejected. Eight Beam segments connect an elevated world origin to the hit point, then fade over approximately 0.75 seconds. Sparks/mist and a brief cosmetic shockwave mark the strike; it does not damage players or structures.

Close or distant thunder is requested at the same fixed position as the visible bolt. The audio controller applies the listener-distance delay once (`distance / 1100`, clamped 0.05–2.5 seconds). Thunder rolloff reaches 1900 studs for close-strike cues or 2600 studs for distant cues. Heavy rain and storm wind remain quieter supporting layers.

## 11. Aurora

Fixed region anchor: **`(-500, 850, -1700)`**.

High quality uses five continuous ribbon rows, each with a main band and a faint wider glow: **10 Beams**. Low uses three rows/six Beams. Each ribbon spans roughly 3000 studs, with smooth server-time changes to endpoints, tangent direction, width and curve. This replaces visibly segmented interior joints with continuous strips. Fixed distant stars twinkle around the region.

The final-source Studio sweep passed Aurora lifecycle/rotation/walking/cleanup checks, and [the refreshed Aurora capture](views/Aurora.png) shows the revised continuous ribbons and stars rendering over the map.

## 12. Void celestial effects

| Body | Fixed world center | Visible body diameter |
|---|---|---:|
| Void ringed planet | `(-3600, 1700, -7000)` | 930 studs |
| Void blue moon | `(1300, 2600, -9200)` | 820 studs |
| Admin celestial body | `(-1850, 2000, -4700)` | 680 studs |

The latest version uses shaded world billboards after far physical spheres were unreliable under some Studio rendering settings. Ring segments are bounded lightweight quads inside the world billboard; the ring and shading slowly animate, while each primary center remains fixed. Small satellites follow deliberate world orbits around those centers. Twinkling stars use fixed anchors 4800–7200 studs from the world center; a faint nebula adds depth.

At High quality the revised Void/Admin celestial helper has at most **38 BaseParts**; Admin adds **17 Beams** (14 rainbow + 3 prism). It does not construct thousands of physical stars or rings. The final-source sweep passed their lifecycle/rotation/walking/cleanup checks. Refreshed [Void](views/Void.png) and [Admin Abuse](views/AdminAbuse.png) captures show the distant planet billboards and stars rendering. The extended live test also verified the moon/rainbow/planet anchor projections toward and away from the camera, fixed centers and billboard stud sizes through rotation/translation, noninteractive scene queries, and full cleanup. It did not measure an entire satellite orbit.

## 13. Cleanup and transitions

The controller increments an event generation token before cleanup. Each module stops its bounded animation connection, destroys only its owned runtime children and becomes safe to call again. Runtime destruction is a second cleanup path. Pending old event callbacks cannot reactivate a replaced event.

Normal Lighting, Atmosphere, post effects, clouds, moon settings and `Workspace.GlobalWind` are restored from the real pre-event snapshot. Newly created post effects transition to neutral and are removed. Normal visual transitions take about **2 seconds**. Event-specific world objects disappear when the event ends.

Audio has its own lifecycle: **1.5-second fade-in**, **1.2-second fade-out**, Ended disconnection, hard one-shot lifetimes, pending-cue cancellation and immediate old-session removal on replacement. No effects are permanently attached to map parts.

## 14. Performance protections

- Cosmetic BaseParts are anchored, non-collidable, non-touchable, non-queryable and do not cast shadows.
- Environment cells are capped at **2–6**, selected every two seconds with cached ground queries and selection hysteresis. Transient environment bursts are capped at four.
- High-quality ghosts are capped at **12**, Low at four; their paths are computed once and selected locally. Ghost particles scale with quality/intensity.
- Meteors have a hard active-flight cap; impacts expire after 30 seconds; flashes/shockwaves expire promptly.
- Celestial animation updates at **15 Hz**, environment at **20 Hz**, meteor/ghost movement at **30 Hz**, main weather motion at **5 Hz**, and audio scheduling at **5 Hz**. There is no RenderStepped loop per effect and no Workspace descendant scan every frame.
- Audio allows at most **3 loops + 8 one-shots / 11 total voices**, with at most 12 pending delayed cues. Identical resolved loop IDs are deduplicated.
- Chaos and Admin cycle visual/audio combinations instead of running every effect at maximum intensity. They share the same world-clock stages: Chaos 20 seconds per four-stage sequence; Admin 14.8 seconds, both following the initial two-second lead-in.
- Final-source sweep budgets passed. Continuous High-quality observation also passed during 20 seconds of Thunderstorm and 35 seconds each of Chaos/Admin. The observed peaks are below; these Studio Heartbeat diagnostics are **not render FPS measurements, a low-end-device guarantee or a populated-server benchmark**.

Observed continuous-window diagnostics from [extended-studio-test.txt](extended-studio-test.txt):

| Event | Observation window | Peak VFX BaseParts | Peak weather Sound objects | Mean Heartbeat Hz | Longest sampled Heartbeat gap |
|---|---:|---:|---:|---:|---:|
| Thunderstorm | 20 seconds | 20 | 3 | 59.11 | 171.2 ms |
| Chaos | 35 seconds | 62 | 6 | 59.67 | 71.9 ms |
| Admin Abuse | 35 seconds | 135 | 5 | 59.92 | 88.9 ms |

The storm window captured **three world lightning strikes and three positional thunder voices**. Chaos visited stages `0,1,2,3,0,1,2`; Admin visited `0,1,2,3,0,1,2,3,0`. Rain/snow enablement matched the expected stages. Every observed temporary actor/voice was removed on end, and original Lighting, effects/Sky and wind returned. The isolated Heartbeat gaps above are retained rather than claiming perfectly steady frame time.

## 15. Low graphics preparation

`Players.LocalPlayer` attributes provide the current configuration surface:

```lua
player:SetAttribute("WeatherVFXQuality", "Low") -- Low / Medium / High
player:SetAttribute("WeatherEventIntensity", 0.6)
```

Low/Medium/High map to **0.35 / 0.65 / 1**. Numeric quality is clamped to 0.25–1, intensity to 0.35–1. These values are read when the event starts; change them before restarting an event for verification. A future settings UI can write the same attributes.

Lower settings reduce decorative particles, mist cells, meteor lanes/frequency, crater rubble, ghosts, stars and Aurora ribbon count. Major recognizable world objects remain. Audio does not read these settings or mute its ambience. Server state, event duration and gameplay remain independent.

## 16. Build result

**PASS** at the latest recorded build:

```text
rojo build default.project.json --output documentations/weather-polish-20260917/AnimalKingdom-weather-source.rbxlx
```

[AnimalKingdom-weather-source.rbxlx](AnimalKingdom-weather-source.rbxlx) is a **source-mapped build**, not the complete authored map. Do not use it to replace the live place's authored content.

A full weather-polished `.rbxl` recovery save has **not yet been produced**. The prior complete map audit backup remains available at [AnimalKingdom-after-full-audit-20260917.rbxl](../full-audit-20260917/AnimalKingdom-after-full-audit-20260917.rbxl), but that file predates this weather polish.

## 17. Sourcemap and verification results

**PASS**:

```text
rojo sourcemap default.project.json --output documentations/weather-polish-20260917/AnimalKingdom-weather.sourcemap.json
```

[Sourcemap artifact](AnimalKingdom-weather.sourcemap.json).

| Check | Result and scope |
|---|---|
| Final-source complete Studio event sweep | **PASS — 181 assertions, zero failures**, all 18 events, completed 2026-09-18 00:55:34 UTC after the final EDIT-mode source installation. [Evidence](final-studio-sweep.txt) |
| Earlier complete Studio event sweep | **PASS — 181 assertions, zero failures**, retained as earlier-revision evidence. [Evidence](first-studio-sweep.txt) |
| Six existing audio assets | **PASS — all six fetched successfully and reported loaded in live Studio.** This verifies availability, not subjective mixing. [Evidence](audio-assets-live.txt) |
| Audio lifecycle and 420-second sequence harness | **PASS — 3,559 assertions**, 18 profiles, cleanup, positional targets, thunder delay, caps and complete Chaos/Admin phase alignment. [Evidence](audio-mock-results.txt) |
| Native first-party compilation | **PASS** for the revised weather modules/controller/tests |
| Native admin/system regression harnesses | **PASS**; existing control/server logic preserved |
| Final live admin controls / real remotes | **PENDING** — separate live regression remains |
| Latest celestial render and source integration re-test | **PASS in final sweep** — updated moon, Void planets, Aurora and world stars rendered; fixed anchors survived rotation and cleanup. [Captures](views/) |
| Extended storm/Chaos/Admin and celestial sampling | **PASS — 100 assertions, zero failures, 114.08 seconds**. Three actual storm strikes/three positional thunder voices; all four Chaos/Admin stages; fixed celestial projection/rotation/translation; scene-query safety and total cleanup. [Evidence](extended-studio-test.txt) |
| Current 30-second crater lifetime observation | **PENDING** — full final live lifetime check remains |
| Two real clients / populated-server FPS | **NOT VERIFIED in this polish phase** |
| Finished unique audio for all 18 events | **ASSET DEPENDENCY — 69 slots empty**; no fabricated IDs or recordings; no subjective headphone listening/mix review performed |
| Complete weather-polished place recovery save | **PENDING**; current build artifact contains mapped source only |

One test-only setup guard was corrected to read the authoritative `BreakEndsAt` attribute instead of `EndsAt` before the successful extended run. Its earlier setup failure prevented that test from starting; it was not a gameplay error and did not change production timing.

The refreshed PNGs in `views/` were captured during the final-source sweep and replace the earlier iteration images. They support visual review of the installed revision; individual still images do not prove a complete animation or lifetime. The pending crater/admin/save checks must be updated from their actual results before those checks are reported complete.

## 18. Exact Studio testing checklist

Use the authored Animal Kingdom place with the repaired source synchronized. Start a fresh Play session and inspect Output for project errors. Keep production defaults at **Break 300 seconds / Event 420 seconds / TestMode false**.

For **each** event below: start it through the existing admin controls, verify the named visual cue, rotate a full 360 degrees, walk between Town and an open biome, listen to the available layers, end the event, wait 2.5 seconds, and verify that event world/audio containers are gone and normal light/wind return.

| Event | Required visual/audio observation |
|---|---|
| Sunny Skies | Sparse pollen/petals, pleasant daylight, soft wind; no excessive sparkle curtain |
| Rainy Day | Actual rain and ground splash/mist; relaxing rain mix |
| Thunderstorm | Observe at least three strikes over 25–30 seconds; bolt positions remain world-fixed and thunder comes from the strike direction |
| Snowfall | Snow size/drift variation and a stronger gust; quiet cold wind |
| Foggy | Nearby paths remain readable; low mist moves through world cells |
| Windy | Leaves/dust/streaks and visible gust with its localized whoosh |
| Heatwave | Warm shimmer/dust without map fire or uncomfortable blur |
| Aurora | Look toward the northern sky ribbons, then away/back; smooth continuous ribbon flow and visible stars |
| Blood Moon | Face `(-6338,8008,-23752)`, confirm large cratered red moon; turn away/back and walk sideways; same anchor, clean disappearance, normal moon restored |
| Meteor Shower | Watch at least 45 seconds; small/large world flights, fire/smoke trails, one safe impact, audible matching whoosh/boom; time an impact for 30 seconds and confirm total crater disappearance |
| Spirit Night | Actual nearby ghosts with faces/wisps; walk between cells; paths remain in the world; supplied spirit pass/whisper assets originate near the ghost |
| Rainbow | Face `(-500,60,-2200)` and its elevated arc; seven-color horizon arc stays fixed through rotation/walking and disappears on end |
| Chaos | Watch at least 40 seconds; all four combinations appear and rain/cold wind follow their stages |
| Inverted | Geometric shapes and opposing light/dark particles; visible magic accent matches any assigned zap |
| Nightmare | Dark but walkable scene, distant eyes and rare red lightning; no excessive stingers |
| Void | Face each fixed planet center; observe ringed purple planet, blue moon, satellites/stars/nebula; rotation does not drag bodies around the screen |
| Golden | Golden rays/dust/star bursts remain readable; supplied chimes are restrained |
| Admin Abuse | Observe at least 40 seconds of combined rainbow/planet/prism/meteor/four-stage effects; strongest event remains readable and cleans completely |

Additional required checks:

1. **World occlusion:** walk behind a building with Blood Moon/planet in view; celestial billboards should be occluded naturally, not draw over the building/UI.
2. **Impact integrity:** compare the impacted floor before/after the 30-second scar; no authored parts, Terrain, collisions or materials should change. Walk/raycast across it safely.
3. **Replacement/cleanup:** Blood Moon → end → Break → Rainbow → end → Meteor → emergency reset. Repeat rapid event replacement and confirm no old moon/arc/ghost/impact/fire/audio survives.
4. **Production/admin controls:** manual start duration is 420 seconds; normal break is 300; queue two events, pause/resume the cycle, randomize, end, and emergency reset. Confirm event cards/timers and camera controls still work.
5. **Low graphics:** set `WeatherVFXQuality` to Low before restarting the same heavy events. Confirm fewer details, retained moon/rainbow/planet/large meteors, and unchanged ambience behavior. Repeat Medium/High and a lower intensity value.
6. **Audio positions:** stand left/right of a meteor landing or lightning position; sound should pan and attenuate by distance. Confirm pitch stays natural, no duplicate loops, and no old ambience after switching.
7. **Audio asset assignments:** upload/assign each required slot from [MISSING SFX ASSETS](AUDIO-MANIFEST.md#missing-sfx-assets); then retest every event with headphones. Empty-slot silence is expected until assignment and cannot pass a finished sound-design review.
8. **Two clients:** compare moon/rainbow/planet locations, server event identity and timer; cosmetic quality changes on one client must not alter the other client's server state.
9. **Performance:** inspect frame time/MicroProfiler on a target low-end device during storm, meteor, Spirit Night, Void and Admin Abuse. Compare equal camera positions and quality settings. Do not infer populated-server FPS from the snapshot budget check.
10. **Final saved place:** after the revised-source tests pass, stop Play, save a distinct full-place recovery copy, and reopen it once to verify the authored map and repaired weather sources are present together.

Optional automated Studio client checks: run [WeatherPolish.studio.client.lua](../../tests/WeatherPolish.studio.client.lua) in a fresh production Break. Run [WeatherPolishExtended.studio.client.lua](../../tests/WeatherPolishExtended.studio.client.lua) in another fresh Break with at least 125 seconds remaining. These scripts inject local presentation state; they do not substitute for testing real admin remotes or multiplayer replication.
