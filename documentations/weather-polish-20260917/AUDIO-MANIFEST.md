# Animal Kingdom weather audio polish

This phase adds a centralized client weather mixer and complete cue/asset definitions for all 18 events. It reuses five previously configured weather recordings and the built-in splash found in the live character. **69 specialized asset slots remain empty.** These slots are intentionally silent unless an appropriate documented fallback is available; no Roblox IDs were invented. The full requested birds, chimes, whispers, cosmic tones, fire, and unique activation recordings require uploads/assignments before the intended sound design can be judged complete by ear.

## Integration and ownership

- `ReplicatedStorage.Shared.WeatherSoundDefinitions`: all IDs, empty upload slots, fallbacks, event layers, cue variations, tones, ranges and mix limits.
- `ReplicatedStorage.Shared.WeatherAudioController`: `Start(eventId, startedAt, runtime)` (also `StartAudio`), then session `PlayCue(name, target, options)`, `StopAudio(1.2)`, `CleanupAudio()`, `GetStats()`.
- Global ambience lives in `SoundService.AK_WeatherAudio.<EventId>.<Category>`; one `WeatherMix` SoundGroup caps the weather mix at 0.72.
- Fixed positional sound anchors live in the current weather runtime's `EventAudio.<Category>` folders. Meteor flybys attach to the actual moving meteor; spirit cues originate at the actual spirit path position when emitted. Every sound carries event/category/requested/resolved asset attributes for inspection.
- Categories: Ambience, WeatherLoops, WorldSFX, ImpactSFX, MagicalSFX, CelestialSFX, TransitionSFX.
- VFX calls `PlayCue` when something visible actually occurs. `ThunderStrike`/`ThunderDistant` delay playback by listener distance / 1100 studs per second, clamped 0.05–2.5 seconds. No separate random thunder sound plays without a visible strike.
- `PlayCue` accepts a Vector3, BasePart or Attachment. Options are `{ VolumeScale = 1, Duration = seconds, Delay = seconds }`. Meteor impact cues add synchronized rock/fire follow-up layers when their slots become available.
- Server event state, timing, admin commands, queues, event cards, music and player volume settings are untouched. Audio does not read VFX quality and remains available at every graphics level.

## SFX by event

Names below describe configured layers/cues. Empty specialized slots are listed explicitly at the end; their inclusion here does not claim that recordings exist.

| Event | Ambience / weather loops | Randomized texture | Positional / impact cues tied to VFX | Start cue |
|---|---|---|---|---|
| Sunny Skies | Day ambience (soft existing wind fallback), foliage rustle | Bird1/Bird2, 18–34 seconds | None required | Gentle 1.5-second ambience fade |
| Rainy Day | Moderate rain, distant rain, soft breeze | Gentle rain drip, 14–25 seconds | WaterSplash variants | Rain fade |
| Thunderstorm | Heavy rain, storm wind, rain impact bed | Thunder variant/pitch selected at each visual strike | Close/distant thunder synchronized to visible strikes | Heavy rain/wind fade |
| Snowfall | Cold filtered wind, muffled winter ambience | Gust variant/pitch from visual gust | WindGust | Quiet cold wind fade |
| Foggy | Quiet mysterious drone (eerie wind fallback), low wind | Distant forest cue, 24–43 seconds | None required | Subdued ambience fade |
| Windy | Strong wind, leaf rustle | Wind gust variants/pitch | WindGust synchronized with stronger visual gust | Wind fade |
| Heatwave | Dry wind, hot-weather insects | Dust gust variant/pitch | WindGust at dust gust | Dry wind fade |
| Aurora | Aurora pad, magical shimmer, gentle night air | Airy sweep, 21–36 seconds | MagicBurst / crystal chimes at sparkle | AirySweep |
| Blood Moon | Ominous drone (eerie wind fallback), distant wind | Low pulse/dark magic/rare howl, 22–38 seconds | Global low pulse and dark ambience; no fake positional impact | BloodMoonStart |
| Meteor Shower | Distant sky rumble, night air | Small/large whoosh and impact variants | MeteorFlybySmall/Large attached to meteor; impact at landing; rock debris/fire burst/crackle when assigned | First actual meteor whoosh; no fake detached sky impact |
| Spirit Night | Spirit ambience (eerie wind fallback), air, shimmer | Whisper variants when a visible spirit requests them | SpiritPass and rare SpiritWhisper at actual spirits | Spirit bed fade |
| Rainbow | Pleasant magic, glitter, gentle breeze | Chime variant/pitch at sparkle | MagicBurst | RainbowStart |
| Chaos | Reality-warp bed; rain/cold wind follow the four visual stages in a 20-second sequence | Reverse sweep, 18–29 seconds | Actual lightning, meteor, fire, magic and energy cues; voice capped | Warp fade |
| Inverted | Reversed-feeling ambience (eerie wind fallback), cold air | Reverse sweep, 17–29 seconds | MagicZap synchronized to a visible burst among the geometric accents | ReverseSweep |
| Nightmare | Dark drone (eerie wind fallback), cold distant wind | Quiet pulse/stinger, 23–39 seconds | Red-lightning thunder; sparse pulse/stinger ambience | Drone fade |
| Void | Cosmic ambience (eerie wind fallback), cosmic rumble, space shimmer | Cosmic tonal swell, 25–42 seconds | EnergyStrike at cosmic streak, celestial cues | VoidStart |
| Golden | Treasure ambience, gold shimmer, warm air | Golden chime variants/pitch at star burst | StarBurst | GoldenStart |
| Admin Abuse | Reality-warp bed; rain/cosmic layers follow the four visual stages in a 14.8-second sequence | Reverse/cosmic sweeps, 15–25 seconds | Actual thunder, meteor, fire, magic and energy; bounded mix | AdminStart |

**Every row has the same cleanup contract:** stop accepting new cues; cancel pending thunder/secondary cues; fade global sounds for 1.2 seconds; remove positional sounds with the event runtime; disconnect Ended/Heartbeat; destroy all owned sounds/anchors/groups. Starting another event during the fade first destroys the previous session, so old ambience cannot contaminate the next event. Optional `EventEnd` uses the same deadline and is silent until assigned.

## Existing recordings reused

| Definition | Existing asset | Use |
|---|---|---|
| ExistingRain | `rbxassetid://1516791621` | Moderate/heavy rain and restrained Chaos/Admin rain sections |
| ExistingThunder | `rbxassetid://12222030` | Thunder; explicitly temporary filtered meteor impact fallback |
| ExistingWind | `rbxassetid://8202539690` | Breeze, storm/cold/dry wind and subdued environmental layers |
| ExistingEerieWind | `rbxassetid://9114228918` | Temporary fog/moon/spirit/nightmare/void/warped ambience fallback with different EQ/mix |
| ExistingMeteor | `rbxassetid://9120705982` | Small/large meteor whoosh fallback |
| ExistingWaterSplash | `rbxasset://sounds/impact_water.mp3` | Quiet splash fallback; verified in the live character's existing Splash Sound |

These were found in source/live content; this inventory is not a guarantee that every remote asset is currently authorized for the experience. A failed load is skipped with one Studio diagnostic. Existing thunder is a temporary impact substitute, not a finished rock explosion recording. Eerie wind is not represented as a real cosmic pad, whisper, or heartbeat.

## Position and distance mix

All positional sounds use `InverseTapered` rolloff; min/max ranges are in studs. Volume is mixed beneath the 0.72 SoundGroup cap and one-shot pitch varies only 0.94–1.06.

| Cue | Min | Max | Base volume | Hard lifetime |
|---|---:|---:|---:|---:|
| ThunderStrike | 130 | 1900 | 0.56 | 12s |
| ThunderDistant | 180 | 2600 | 0.34 | 14s |
| MeteorFlybySmall | 70 | 1300 | 0.24 | 7s |
| MeteorFlybyLarge | 160 | 2200 | 0.40 | 12s |
| MeteorImpactSmall | 95 | 1400 | 0.36 | 9s |
| MeteorImpactLarge | 230 | 2900 | 0.62 | 14s |
| RockDebris | 20 | 300 | 0.14 | 4s |
| FireBurst | 45 | 650 | 0.20 | 5s |
| FireCrackle | 20 | 230 | 0.10 | 6s |
| WindGust | 70 | 900 | 0.17 | 6s |
| SpiritPass | 22 | 250 | 0.15 | 5s |
| SpiritWhisper | 16 | 190 | 0.055 | 5s |
| MagicBurst | 25 | 420 | 0.11 | 6s |
| MagicZap | 50 | 850 | 0.16 | 6s |
| EnergyStrike | 130 | 2100 | 0.20 | 9s |
| StarBurst | 30 | 480 | 0.13 | 6s |
| WaterSplash | 14 | 150 | 0.07 | 3s |

No invalid/missing world target falls back to a centered global impact. Large impacts have wider reach and stronger low-end filtering; no extra bass is added to the entire game's master mix.

## Performance and reliability

- At most 3 looping layers, 8 one-shots and 11 total voices per client; pending delayed cue queue capped at 12.
- One Heartbeat handler per active audio session; actual scheduling/checking at 5 Hz. No RenderStepped or Workspace scan.
- Layer IDs deduplicated even when several upload slots resolve to the same fallback.
- No expensive server audio motion; moving sound parent is the existing cosmetic meteor/spirit.
- Ended cleanup plus hard lifetimes handles inaccessible/never-ending sounds. Canceled or destroyed event objects cannot produce late scheduled cues.
- Empty IDs never produce Sound instances. Missing specialized magic/bird/whisper cues stay silent. Distinct real variants are selected when supplied; fallbacks resolve to a unique clip and use gentle pitch variation.
- Loop fades last 1.5 seconds in and 1.2 seconds out. Intense event sections cycle instead of running all layers at full volume. Chaos uses four 5-second stages; Admin Abuse uses four 3.7-second stages, both with the same initial 2-second lead-in as the visual controller. Rain audio is active only for rain stage 0 (and its initial lead-in), cold wind accompanies Chaos snow stage 2, and Admin cosmic rumble accompanies energy stage 3. Section changes crossfade over 1.8 seconds.
- Audio never changes player volume or assumes a nonexistent music ducking integration.

## Validation

Both new modules compile with the native Luau compiler. A standalone mocked Roblox lifecycle run passed **3,559 assertions across 18 event lifecycles and the complete 420-second Chaos/Admin stage sequences**, including fixed positional anchors, distance-delayed thunder, voice caps, missing asset silence, global fades after runtime removal, direct replacement, pending-cue cancellation, and rain/snow/energy audio phase alignment every half-second throughout both full event sequences. This validates controller behavior, not whether a remote recording loads or the subjective final mix in headphones. Live listening and asset permission checks remain necessary for final uploaded recordings.

All six reused recordings also fetched successfully and reported loaded in the live Studio asset check: [audio-assets-live.txt](audio-assets-live.txt). The final-source all-event sweep passed 181 assertions, including audio cleanup after fade: [final-studio-sweep.txt](final-studio-sweep.txt). The [extended Studio test](extended-studio-test.txt) also passed 100 assertions, observing three actual storm strikes with three positional thunder voices and continuous peaks of 3 / 6 / 5 weather sound objects for Thunderstorm / Chaos / Admin Abuse. All observed sounds were removed at event end. **No headphone listening or subjective audio-mix review was performed.** The 69 empty specialized slots still require actual assignments and listening review; these automated results do not claim complete unique sound design.

Roblox API references used: [Sound positional behavior and cleanup](https://create.roblox.com/docs/reference/engine/classes/Sound), [EqualizerSoundEffect](https://create.roblox.com/docs/reference/engine/classes/EqualizerSoundEffect), [SoundGroup](https://create.roblox.com/docs/reference/engine/classes/SoundGroup).

## MISSING SFX ASSETS

Assign these **69 currently empty definitions** in `WeatherSoundDefinitions.Assets`. Assign IDs permitted to this experience. Multiple variants can share a valid final recording temporarily; they are deduplicated internally. “Silent” means the requested specific sound is omitted until provided.

| Slot | Requested recording | Current fallback |
|---|---|---|
| `DayAmbience` | Seamless peaceful daytime nature | ExistingWind |
| `Bird1` | Quiet daytime bird call variant 1 | Silent |
| `Bird2` | Quiet daytime bird call variant 2 | Silent |
| `WindGust1` | Broad wind gust variant 1 | ExistingWind |
| `WindGust2` | Broad wind gust variant 2 | ExistingWind |
| `LeafRustle` | Gentle foliage rustling loop | Silent |
| `RainDistant` | Soft distant rain loop | Silent |
| `RainSplash1` | Small water splash variant 1 | ExistingWaterSplash |
| `RainSplash2` | Small water splash variant 2 | ExistingWaterSplash |
| `RainDrip1` | Gentle rain drip texture | Silent |
| `ThunderClose1` | Close thunder crack variant 1 | ExistingThunder |
| `ThunderClose2` | Close thunder crack variant 2 | ExistingThunder |
| `ThunderDistant1` | Long rolling distant thunder variant 1 | ExistingThunder |
| `ThunderDistant2` | Long rolling distant thunder variant 2 | ExistingThunder |
| `WinterWind` | Cold soft wind loop | ExistingWind |
| `WinterAmbience` | Quiet muffled winter ambience loop | Silent |
| `FogDrone` | Quiet mysterious fog drone loop | ExistingEerieWind |
| `DistantForestCue` | Sparse mysterious distant forest sound | Silent |
| `DryWind` | Dry airy desert wind loop | ExistingWind |
| `HeatInsects` | Subtle hot-weather insects loop | Silent |
| `AuroraPad` | Beautiful airy aurora pad loop | Silent |
| `CrystalChime1` | Soft crystalline chime variant 1 | Silent |
| `CrystalChime2` | Soft crystalline chime variant 2 | Silent |
| `MagicShimmer` | Soft magical shimmer loop | Silent |
| `AirySweep` | Airy magical sweep | Silent |
| `BloodMoonAmbience` | Low ominous blood moon drone loop | ExistingEerieWind |
| `BloodMoonPulse` | Soft low blood moon pulse | Silent |
| `DarkMagic` | Quiet dark magical texture | Silent |
| `BloodMoonStart` | Short ominous activation swell | Silent |
| `NightHowl` | Rare distant atmospheric howl | Silent |
| `MeteorSkyRumble` | Quiet distant sky rumble loop | Silent |
| `MeteorWhooshSmall1` | Small fiery meteor whoosh variant 1 | ExistingMeteor |
| `MeteorWhooshSmall2` | Small fiery meteor whoosh variant 2 | ExistingMeteor |
| `MeteorWhooshLarge1` | Large fiery meteor whoosh variant 1 | ExistingMeteor |
| `MeteorWhooshLarge2` | Large fiery meteor whoosh variant 2 | ExistingMeteor |
| `MeteorImpactSmall1` | Small meteor rock impact variant 1 | ExistingThunder |
| `MeteorImpactSmall2` | Small meteor rock impact variant 2 | ExistingThunder |
| `MeteorImpactLarge1` | Large low-end meteor impact variant 1 | ExistingThunder |
| `MeteorImpactLarge2` | Large low-end meteor impact variant 2 | ExistingThunder |
| `RockDebris` | Short scattering stone debris | Silent |
| `FireCrackle` | Short seamless crackling fire loop | Silent |
| `FireBurst` | Brief rushing fire burst | Silent |
| `SpiritAmbience` | Airy ghostly spirit ambience loop | ExistingEerieWind |
| `SpiritWhisper1` | Sparse indistinct spirit whisper variant 1 | Silent |
| `SpiritWhisper2` | Sparse indistinct spirit whisper variant 2 | Silent |
| `SpiritChime` | Soft nearby spirit orb chime | Silent |
| `SpiritSweep` | Ghost passing/reversed airy sweep | Silent |
| `RainbowAmbience` | Pleasant magical rainbow ambience loop | Silent |
| `RainbowStart` | Brief happy rainbow activation shimmer | Silent |
| `ChaosWarp` | Soft shifting chaotic ambience loop | ExistingEerieWind |
| `MagicZap1` | Soft magical zap variant 1 | Silent |
| `MagicZap2` | Soft magical zap variant 2 | Silent |
| `InvertedAmbience` | Reversed-feeling surreal ambience loop | ExistingEerieWind |
| `ReverseSweep` | Gentle backwards-feeling tonal sweep | Silent |
| `NightmareDrone` | Dark distant nightmare drone loop | ExistingEerieWind |
| `NightmarePulse` | Subtle heartbeat-like pulse | Silent |
| `NightmareStinger` | Rare quiet distant nightmare stinger | Silent |
| `VoidAmbience` | Deep cosmic space ambience loop | ExistingEerieWind |
| `CosmicRumble` | Gentle broad cosmic low rumble loop | Silent |
| `CosmicEnergy1` | Purple cosmic energy crack variant 1 | Silent |
| `CosmicEnergy2` | Purple cosmic energy crack variant 2 | Silent |
| `CosmicTone` | Distant planet/space tonal swell | Silent |
| `VoidStart` | Short cosmic opening swell | Silent |
| `GoldenAmbience` | Warm treasure-like magical ambience loop | Silent |
| `GoldenChime1` | Soft valuable golden chime variant 1 | Silent |
| `GoldenChime2` | Soft valuable golden chime variant 2 | Silent |
| `GoldenStart` | Short rewarding golden activation swell | Silent |
| `AdminRealityBreak` | Short large reality-breaking activation cue | Silent |
| `EventEnd` | Short gentle neutral weather exit cue | Silent |
