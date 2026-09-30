# Animal Kingdom — full map and systems audit

Date: September 17, 2026. Place inspected: **Animal Kingdom[TESTING]**, place ID **132313449035787**.

**Map repairs, biome alignment, all-event lifecycle tests, admin tests, server smoke tests, and targeted sky-effect rendering checks have passed.** The after score is **111/150**, up from **69/150**. This is an improved working foundation, with specific verification limits recorded below. The final fresh Play rerun passed and the complete audited place was saved and verified. No two-client pass or DataStore write/readback pass is claimed.

Complete audited place: [AnimalKingdom-after-full-audit-20260917.rbxl](AnimalKingdom-after-full-audit-20260917.rbxl).

Recovery points: `AnimalKingdom-before-full-audit-20260917.rbxl` preserves the actual open place; `source-before.tgz` preserves source before repairs. `live-before.json`, `live-scripts/`, and `live-script-status.json` capture the inspected live geometry and scripts. Live-only content is substantial; the Rojo build alone is not a complete replacement for this place.

## A. BEFORE AUDIT SCORE

These are conservative scores for the present game, including visible prototype/future features. A code review or successful build does not establish production readiness.

| # | Exact rubric category | Before /10 | Evidence limiting the score |
|---|---|---:|---|
| 1 | MAP VISUAL QUALITY | 5 | Authored scenery exists, with stray staging assets, inconsistent grounding, and duplicate geometry. |
| 2 | BIOME ALIGNMENT | 5 | Nine biome floor surfaces differ from the grounded benchmark. |
| 3 | OBJECT PLACEMENT | 4 | Floating/sunken candidates, detached biome props, underground imports, and a coincident tree duplicate. |
| 4 | NAVIGATION / PLAYABILITY | 6 | Continuous support floor exists, but raised biome edges, invisible helpers, and future progression interrupt flow. |
| 5 | COLLISION QUALITY | 4 | Large invisible tree RootParts collide; decorative geometry includes unanchored parts. |
| 6 | SPAWN SAFETY | 5 | Existing spawning works in principle, but saved admin return positions and plot arrival volumes were not safely checked. |
| 7 | WEATHER VISUAL QUALITY | 5 | Existing event visuals work, but moon/rainbow/aurora/void were camera-relative. |
| 8 | WEATHER EVENT RELIABILITY | 4 | Production started with 10/20-second test timing; cleanup/replication needed full verification. |
| 9 | ADMIN SYSTEM RELIABILITY | 7 | Working room and controls preserved; camera target, teleport safety, and a yielding authorization race found. |
| 10 | PLAYER PLOT RELIABILITY | 3 | Four real plots could be miscounted as fifteen assignable objects. |
| 11 | UI READABILITY | 5 | Narrow cards overflow; displayed money and biome prices were demo values; custom event cards omitted countdowns. |
| 12 | SCRIPT HEALTH | 3 | Real historical scale error, empty canonical targets, duplicate live scripts, and competing world cleanup scripts. |
| 13 | PERFORMANCE | 5 | Repeated plot discovery scanned Workspace; runtime prototype generation competed with cleanup; avoidable physics helpers. |
| 14 | MULTIPLAYER SAFETY | 4 | Plot identity, occupied arrivals, concurrent authorization, and profile-load lifecycle had gaps. |
| 15 | OVERALL GAME READINESS | 4 | Basic authored world exists; several reliability defects and unfinished future feature panes remain. |
| | **TOTAL** | **69 / 150** | |

## B. PROBLEMS FOUND

### Map

- The actual world is mostly live-only top-level content. The nearly empty `AnimalKingdomTown` container is not the location of most saved Town visuals. Assuming the source tree represented the complete map would lose content or target empty models.
- Snapshot contains 4,447 BaseParts, including 3,130 MeshParts. Staging imports exist underground and above the world; some named biome roots/logs are around Y=104 outside their named biome.
- One exact coincident pair of `AK_AncientRuins_StylizedTree` models exists at approximately (-729.45355,44.16553,382.03613). Identical names elsewhere often refer to different transforms and are not automatically duplicates.
- Of 102 unanchored parts, 24 are character parts and are intentional. Others include 66 underground `home` import parts, seven actual AltarRuins parts, one Sky rock, a Pedestal, two loose Parts, and a Union.
- Thirty-eight invisible collidable MagicalForest tree RootParts include helpers approximately 13–22 studs across. They can obstruct movement and invalidate safe landing searches.
- Existing saved Town color overlays are intact, but their canonical target containers are absent/empty. They must be preserved; rebuilding Town would be unnecessary.
- Final overview captures reveal conspicuous black rectangular foliage-card backgrounds in MagicalForest and rear Mythical imports. Their texture/alpha/material assets need repair. Broad bare concrete between biome collections and mismatched imported Volcano scenery also limit visual quality; base-height repairs do not resolve these art limitations.

### Biomes

- The grounded reference is **concrete support top Y=7.82893085**. Four plot slab bottoms match it; plot tops are Y=8.82893085. Meadow, Jungle, and Snow slab bottoms also match it; their 1.3-stud floors have playable tops **Y=9.12893085**.
- Other biome floor tops range from 9.61473590 to 11.54999971. This is a real inconsistency, distinct from intentional trees, cliffs, cones, ruins, and platforms.
- Sky's base is only about 1.72 studs above the grounded biome benchmark. Evidence does not indicate a deliberately high-altitude playable island. Its internal elevated scenery remains intentional.
- Some elevated biome floors moved independently of already grounded scenery. Moving every matching tree downward with those floors would create new buried objects. Coherent assembly offsets and isolated displaced-floor corrections must be distinguished.
- Rojo's old BiomeBlockout platforms are at Y=1, under a differently positioned authored world. Runtime fallback generation and live cleanup scripts fought over that old map.

### Navigation

- Raised biome edges and invisible tree helpers were genuine movement concerns. The shared concrete support spans approximately X=-1002.49…326.85 and Z=-428.11…924.16, so major biome gaps have support. However, all four outer-edge raycasts returned **VOID**; the map perimeter lacked a clear physical boundary. A visible perimeter has now been added.
- Original plot/admin movement could accept an obstructed saved position or an already occupied arrival point.
- Biome teleport requests already validate ownership, allowed names, argument count, cooldown, actual floor support, corner support, character clearance, and seated/dead characters. Those working protections were preserved.
- Pet/income-dependent progression is **BLOCKED BY FUTURE PET PHASE**. No pets or free progression were fabricated.

### Weather

- `TEST_MODE=true` forced 10-second breaks and 20-second events, including admin-triggered events.
- Blood Moon, Rainbow, Aurora, and Void were repositioned from camera-local CFrames every rendered frame.
- Meteor/lightning origin orientation inherited the camera precipitation rig. Looking around changed the logical weather direction; precipitation also tilted with camera rotation.
- Custom event artwork omitted the dynamic countdown even though an unused fallback card had one.
- Neutral Lighting/Terrain effect objects were created during the initial Break before an event required them.
- All-event transition, expiry, rapid replacement, Lighting restoration, and world-object cleanup required live verification. The lifecycle test now passes all 18 events; separate screenshots also confirm the corrected distant effects.
- Live testing found raw-string artwork preload requests reporting Failure. Typed ImageLabel preload inputs replace those requests without changing artwork IDs; subsequent fresh Play startup and weather regressions passed.
- Initial distant Rainbow and Aurora captures did not show the intended effects despite lifecycle/anchor checks passing. Fixed horizon positions, Beam settings, and event atmosphere were corrected. Final server-triggered captures show the rainbow and aurora; turn-away captures confirm the rainbow and Blood Moon leave the view.

### Admin

- Room, wall cameras, labels, controls, announcements, weather controls, queue, and emergency reset are retained.
- Town camera resolution targeted `AnimalKingdomTown`, while the actual TownPlaza is its sibling. An `and/or` expression also discarded a second bounds return value.
- The busy guard needed rechecking after authorization yielded; concurrent requests could otherwise pass the earlier check.
- Entry/return destinations needed support, clearance, occupancy, and velocity checks.
- Three live legacy cleanup scripts delete blockout/generated content or all of World. They conflict with a stable runtime container. The independent WalkSpeed=35 script is unrelated.

### Plots

- Prefix-only matching treated four floors, four fences, four SpawnLocations, and three PetDisplay models as fifteen plots. Actual capacity is four.
- Duplicate assignment can follow from misidentified plots; an unfinished duplicate live plot script also exists.
- Admin plot polling repeatedly rediscovered the map via Workspace.GetDescendants.
- Existing username signage is retained; real slot identity and safe spawn placement are repaired.

### UI

- HUD permanently displayed 12,840 Coins and 425 Friendship Tokens.
- Biome prices used a demo formula: Forest displayed 600 while the server charges 2,500.
- Unlock buttons sent UIRequest without a mapped server handler, despite an existing authoritative ProgressionService.
- Fixed three-column biome cards became roughly 80 pixels wide on small screens; text/button overflow followed.
- The text helper could create MinTextSize=10 with MaxTextSize=9.
- A delayed close callback could hide a window reopened within 0.14 seconds. Viewport handling did not follow camera replacement.
- PetIndex has a sample discovered count and pet records; FILTERS/filter chips have no action callbacks. Search and detail selection work only over those samples. Trade lists sample player names; merge sends empty selected pet IDs. These are **FUTURE PET PHASE** presentation scaffolds.
- Decor lists sample catalog ownership and has no working placement backend: **FUTURE 3D ASSET PHASE**.
- Settings toggles previously changed their text/color without applying audio/effect preferences; graphics and redeem controls depended on a missing UIRequest handler. This misleading behavior is repaired: unavailable controls are disabled and labeled Coming Soon, and redeem input is retained. Actual settings/redemption behavior still requires future integration. Existing HideUI/ShowUI and working biome actions were preserved.

### Scripts and data

- The historical `Only positive non-zero scale values are allowed — Workspace.Script line 82` is confirmed. Its GeneralStore target has zero bounds, producing a zero ScaleTo ratio. A second obsolete live overlay builder has the same invalid-target risk; it is already disabled in the captured live status.
- Mapped Town overlay code previously asserted against missing/empty canonical targets and waited indefinitely for absent imports.
- Profile loading lacked duplicate-load guards, departure cancellation, and complete session release on preparation errors. Full-profile requests were not bounded.
- Currency reconciliation needed finite-number normalization. Normal session end and external session loss needed distinct handling.
- Harmless Superbullet localhost/backend and Roblox plugin logging are separated from project errors.

### Performance

- Plot status polling repeatedly scanned the whole Workspace.
- Camera-following sky objects had unnecessary per-frame movement.
- Obsolete world generation could create blockout props, pet display pads, and collectible spheres only for live cleanup scripts to destroy them.
- Static decorative helpers and staging models created avoidable physics/query work. No broad performance redesign was introduced.

## C. FIXES MADE

### Source repairs completed

1. Production weather constants set to 300-second Break, 420-second Event, and TEST_MODE=false. All normal/secret event definitions use production duration; diagnostics replicate configured values.
2. Moon, rainbow, aurora, and void use fixed world anchors. Meteors and lightning use fixed world directions/origins. Only the local precipitation volume tracks position, upright, at 20 Hz.
3. Event effects are created only when required. Existing snapshots and generation-safe cleanup are retained; normal Sky moon size is saved and restored.
4. Custom weather cards now show the authoritative replicated deadline using server time.
5. Exact plot identification excludes fences, SpawnLocations, and display models. Cached container discovery replaces repeated full-world scans.
6. Plot spawns and admin entry/return use existing safe landing support/clearance/occupancy logic and clear residual velocity.
7. Town camera target and bounds handling corrected without rebuilding the camera wall or labels.
8. Admin request guard rechecks after yielding authorization. Existing authorization, confirmation, filtering, and rate limits remain intact.
9. Profile loading is guarded and cancelable; acquired sessions are released on failure/departure. Non-finite balances normalize safely. GetData is limited to one request per second and one pending load wait.
10. Currency HUD subscribes to authoritative ProfileService snapshots/updates. All biome prices use the authoritative shared configuration. Unlock actions call existing ProgressionService.
11. Responsive card columns, bounded button text, valid text constraints, stale-close cancellation, and camera viewport rebinding repair the UI defects.
12. WorldService recognizes actual authored biome floors, preserves World.Runtime, and skips obsolete replacement map generation. Portable fallback remains stored but becomes invisible/noncollidable/nonqueryable with disabled legacy prompts/spawns in the authored place.
13. Legacy sanctuary/display and NumNom prototype spawning require explicit `AK_EnableLegacyGameplayScaffold=true`; production default leaves them off in the authored map.
14. Town overlay runtime skips absent/empty canonical targets and uses a bounded import wait, preserving saved live visual models.
15. Weather artwork preload uses temporary typed ImageLabel instances rather than generic raw strings; original artwork IDs are preserved.
16. WorldService creates exactly four visible neutral-Slate perimeter walls in `AK_AuditPerimeter`, following the concrete ground orientation. They are 6 studs high and 3 studs thick along the outer 3 studs of the supported rectangle, anchored/collidable/nontouchable, and created idempotently. Existing boundaries were not rewritten. Minimum clearance to the biome bases is about 39.85 studs.
17. Settings, graphics, and redeem controls detect the actual UIRequest RemoteEvent. When it is absent or the wrong type, they are disabled with a Coming Soon message; clicks cannot pretend to apply settings or discard a code. HideUI remains operational. Endpoint addition/removal updates availability safely; no settings/rewards backend was invented.

### Live repairs completed and verified

- At **21:57:50 UTC**, the live map operation corrected all elevated biome bases. It moved **555 selected roots / 1,189 parts**, preserving internal relative positions; already grounded scenery was not blindly flattened. The subsequent runtime navigation audit asserted every biome surface is within 0.001 studs of the benchmark.
- Corrected the clearly floating `Forest_Decor_plant_bushDetailed_11` by **-35.25406551 studs**, after grounding inspection.
- Archived five misplaced import roots/logs, retaining them for reuse: two instances named `Prehistoric_Decor_Root_5_58`, `Prehistoric_Decor_Root_5_40`, `Prehistoric_Decor_log_large_79`, and `Mythical_Decor_Root_6_71`.
- Archived the exact coincident Ancient Ruins StylizedTree duplicate while retaining its counterpart.
- Disabled collision on **38 invisible tree helpers** and anchored **78 confirmed static parts**; character parts were preserved.
- Archived six conflicting/duplicate live scripts: the broken Workspace GeneralStore overlay, obsolete duplicate plot allocator, three old world cleanup scripts, and identical duplicate biome-label remover. The independent WalkSpeed script and existing saved Town visuals were retained.
- Verified all sixteen repaired runtime source instances against source in Studio at **21:59:51 UTC** and staged the regression scripts.
- Fresh Play verification completed: **18 weather events / 134 checks / 0 failures**; full admin client suite **0 failures**; twelve biome clearance checks and sixteen routes to Town **0 failures**; in-game SystemAudit **0 failures**, including a loaded, active ProfileStore session.
- Actual avatar respawn passed at **22:28:42 UTC** and retained the same assigned Plot1Floor.
- Final edit-world audit at **22:37:10 UTC** rechecked all twelve floor heights within 0.001 studs and confirmed **four perimeter walls**. A final-source Play session began at approximately **22:37:41 UTC**, assigned Plot1Floor, and reported Roblox API services available. Its startup had no project error. The final-source all-event regression then completed at **22:38:56 UTC: 18 events, 134 checks, zero failures**.

- Runtime collision raycasts hit all four new perimeter walls at **22:48:01 UTC**. The actual in-game SystemAudit repeated with **0 failures**, one connected player, and an active profile.
- Final running-game appearance checks confirmed Blood Moon, Rainbow, and Aurora; moon/rainbow turn-away checks passed. Rainbow/Aurora were triggered through the server admin remote; the final Moon appearance adjustment was checked through the actual visual controller and installed into source. Evidence: `blood-moon-final.png`, `blood-moon-away-final.png`, `rainbow-final.png`, `rainbow-away-final.png`, and `aurora-final.png`.
- After the final settings and Blood Moon fog adjustments, fresh Play began at **22:56:45–22:56:46 UTC**, assigned Plot1Floor, and reported API availability. Its all-event audit finished at **22:58:34 UTC: 18 events, 134 checks, 0 failures**.
- All **14 final region screenshots** in `final-views/` and the neutral `map-overview-final.png` were reviewed: twelve biomes, Town, and Player Plots. They show grounded biome bases, houses, and connected support without another unambiguous placement correction. Intentional Sky elevations remain. These are region overviews, not an individual visual examination of every mesh. The foliage-card backgrounds, bare concrete transitions, and Volcano style inconsistency are recorded as remaining asset work.
- Final `live-after.json` contains **4,443 parts, 2,480 model records, and 143 scripts**. The **24 remaining unanchored parts are intentional character parts**. Temporary `ServerStorage.AK_AuditTests` was removed before the full-place save; source test files are retained.
- Saved the complete audited live place as `AnimalKingdom-after-full-audit-20260917.rbxl`; binary signature, **9,522,310-byte** size, and SHA-256 were verified. The live-only Town/biome content is included.

Evidence is preserved in `live-verification-excerpts.txt`, `weather-live-test-results.txt`, and `weather-final-live-test-results.txt`. The score credits verified repairs and captures; it does not imply individual visual inspection of every mesh.

## D. BIOME ELEVATION REPORT

`[MapAudit] Common playable floor Y = 9.128930568695068`

This value is the **top of the biome floor slab**. Shared support/base-bottom Y is **7.82893085**. Existing plot slabs are one stud thick; biome slabs are 1.3 studs thick. This preserves grounded construction and small intended surface steps instead of assuming Y=0.

**Applied live at 21:57:50 UTC, rechecked during runtime navigation at 22:06:22–22:06:27 UTC, and checked again in the final map pass at 22:37:10 UTC.** Jungle and Snow retain negligible floating-point differences; all twelve floors pass the 0.001-stud alignment tolerance.

| Biome | Original base surface Y | Corrected base surface Y | Vertical offset applied | Placement decision |
|---|---:|---:|---:|---|
| Meadow | 9.128931 | 9.128931 | +0.000000 | Already aligned. |
| Forest | 10.128955 | 9.128931 | -1.000025 | Correct displaced floor; retain already grounded props. |
| Jungle | 9.128947 | 9.128947 | +0.000000 | Already aligned within floating-point tolerance. |
| Desert | 10.128926 | 9.128931 | -0.999995 | Correct displaced floor; retain already grounded props. |
| Snow | 9.128937 | 9.128937 | +0.000000 | Already aligned within floating-point tolerance. |
| Volcano | 10.550000 | 9.128931 | -1.421069 | Move coherent assembly; retain cone/internal elevations. |
| Ocean | 10.550000 | 9.128931 | -1.421069 | Correct displaced floor; retain already grounded props. |
| Ancient Ruins | 11.550000 | 9.128931 | -2.421069 | Move coherent assembly; preserve elevated ruins. |
| Magical Forest | 10.536739 | 9.128931 | -1.407808 | Move coherent assembly; preserve tree relationships. |
| Sky | 10.850001 | 9.128931 | -1.721070 | Correct base offset; preserve intentional clouds/platforms. |
| Prehistoric | 9.614736 | 9.128931 | -0.485805 | Move coherent assembly; preserve internal geometry. |
| Mythical | 10.300000 | 9.128931 | -1.171069 | Correct displaced floor; retain already grounded props. |

The assembly/floor distinction follows actual placement evidence. It is not a blanket flattening pass. Sky has no supported reason to retain the accidental 1.72-stud base offset; intentional internal vertical design is retained.

## E. WEATHER WORLD EFFECTS

The all-event Studio lifecycle test passed **18 events, 134 checks, 0 failures** on three runs: **22:02:57 UTC**, **22:38:56 UTC**, and the final all-source fresh session at **22:58:34 UTC**. Checks include fixed anchor positions during camera rotation/translation and clean teardown. Separate running-game captures confirm **visible Blood Moon, Rainbow, and Aurora**, and moon/rainbow turn-away captures confirm these phenomena leave the view. Rainbow/Aurora captures use server admin event starts; the final Moon atmosphere adjustment was checked through the actual visual controller. Their positions stay fixed when the camera rotates or the avatar moves. Final Blood Moon fog distance 100,000 and atmosphere density 0.2 were also checked in the running game, restoring crater visibility while retaining the event lighting. The final source-backed Moon screenshot was repeated after the last fresh session, with its crater detail visible. Lifecycle assertions and appearance captures are separate evidence.

| Effect | Fixed world position | Implementation |
|---|---|---|
| Blood Moon | **(-6338, 8008, -23752)** | Anchored Workspace part with a 1,900-stud world BillboardGui disc/craters; normal 3D occlusion; no camera-relative position update. Normal Sky moon sizes restore on cleanup. |
| Rainbow | **(-500, 60, -2200)** | Fourteen curved Beams form seven bands, outer radius 1,204 studs, width 24.08, 64 segments, transparency 0.15, LightEmission=0. Fixed attachments; visible horizon arc confirmed. |
| Aurora | **(-500, 850, -1700)** | Five fixed world ribbons with softened endpoints; fog distance 100,000 and atmosphere density 0.15 preserve visibility. Anchor and appearance checks passed. |
| Void | **(-338, 108, 18)** | Fixed anchor with seven deterministic wisps. |
| Meteor Shower origin | **(-338, 1508, -1952)** | Consistent world direction; temporary meteors/trails clean up with the event. |
| Lightning origin | **(-338, 658, -852)** | Consistent world-space strike origin; event-owned temporary geometry/effects. |

All players derive the same celestial locations. A BillboardGui may face a viewing camera for legibility; its anchor position remains fixed, so looking away moves it out of view. The rainbow is a world Beam assembly. Temporary flashes, subtle post-processing, vignette, and event cards remain legitimate screen/post-processing effects.

| Event family | Audited visual intent |
|---|---|
| Sunny Skies | Lighting/sky presentation and UI card. |
| Rainy Day, Snowfall | Upright local precipitation volume; particles move in the world. |
| Thunderstorm | Precipitation plus world lightning; temporary flash permitted. |
| Foggy | Atmosphere/fog with full restoration. |
| Windy, Heatwave | Environmental particles/post-processing; no fixed celestial object attached to view. |
| Aurora, Blood Moon, Rainbow | Fixed distant world phenomena as above. |
| Meteor Shower | Fixed logical world direction. |
| Spirit Night | Orbs originate near the player and then animate in world space without inheriting view rotation. |
| Chaos, Inverted, Nightmare, Golden, Admin Abuse | Event-specific particles/post-processing/UI; lifecycle included in the all-event regression. |
| Void | Fixed world phenomenon plus appropriate post-processing. |

`tests/WeatherAudit.studio.client.lua` exercises all 18 event starts/ends, rapid replacement, fixed-anchor stability during camera movement, collision flags, countdowns, and restoration of Lighting/Atmosphere/Clouds/Sky/sounds. Its successful output is recorded in `weather-live-test-results.txt` and `weather-final-live-test-results.txt`. Render evidence is recorded separately in the five final appearance/turn-away screenshots listed in C.

## F. EVENT TIMING

- **Break = 300 seconds.**
- **Event = 420 seconds.**
- **TEST_MODE production default = false.**
- Admin starts use production durations. Existing queue, pause/resume, random, end, and emergency reset controls are retained.
- TIME LEFT is derived from authoritative replicated EndsAt and Workspace:GetServerTimeNow(); it does not accumulate a separate drifting client timer.
- Automated actual-source tests pass production timing, admin duration, automatic cycling, queue transitions/clear, pause/resume, reset, and stale timer cancellation. The live admin suite also passed event duration, queue start/clear, reset to a five-minute Break, and TEST_MODE off at 22:05:54 UTC; all-event client checks passed authoritative countdown visibility. Two-client timer comparison remains unverified.

## G. SYSTEM HEALTH

PASS means the specified check has evidence. WARNING means partial verification or a remaining limitation. No live system is marked PASS solely from compilation.

| Audited system/check | Status | Evidence or specific remaining limit |
|---|---|---|
| Live map visual/grounding pass | WARNING | Fourteen final region overviews show grounded bases/houses and connected support; identified placement outliers repaired. Imported foliage-card backgrounds and art transitions still need asset work. Every mesh was not individually examined visually. |
| Biome base alignment | PASS | All twelve floors corrected/retained within 0.001 studs; runtime assertions passed. |
| Main navigation | PASS | Twelve biome clearances and routes from all twelve biomes plus four plots to Town passed PathfindingService. |
| Perimeter boundary | PASS | Four unsupported outer edges repaired; runtime raycasts hit all four visible collision walls at 22:48:01 UTC. Source regressions verify placement/idempotence. |
| Every narrow geometry gap | WARNING | Main routes verified; every possible gap/intentional jump off the map has not been traversed with a real avatar. |
| Plot/admin spawn and return safety | PASS | Live checks passed all four plot landing volumes, velocity reset, admin room entry/membership, and return. |
| Actual respawn | PASS | Real avatar respawn at 22:28:42 UTC retained Plot1Floor and safe placement. |
| Two-player arrival contention | WARNING | Safe-arrival code/lifecycle mocks pass. Server & Clients was attempted, but zero clients connected; true two-client contention remains unverified. |
| Weather server timing/commands/queue | PASS | Actual-source regressions and live admin suite passed production timing, transitions, queue, reset, TEST_MODE off. |
| Weather fixed anchors and cleanup | PASS | All 18 events / 134 assertions passed three times, including the final all-source session at 22:58:34 UTC; anchor invariance and rapid replacement restoration verified. |
| Weather final visual appearance | PASS | Final running-game screenshots show moon, rainbow, and aurora; moon/rainbow turn-away screenshots pass. Fixed anchors and cleanup are separately verified. |
| Admin authorization / confirmations / announcements | PASS | Dispatcher/security mocks pass; live suite passed filtered announcement, queued event, confirmed reset and all destinations. |
| Admin room / camera wall / labels | PASS | Live suite confirmed six panels, fifteen preserved labels; SystemAudit confirmed all camera points/buttons and room entry/return. |
| Player plot discovery / single-player ownership | PASS | Exactly four real plots; live player owns exactly one; all four safe landing checks passed. |
| Player plots multiplayer admission / release | WARNING | True concurrent admission, leave/reassignment, and full-capacity contention need a two-client/server test. |
| Profile wrapper/session lifecycle | PASS | Lifecycle mocks pass; live runtime shows loaded/reconciled data and active ProfileStore session. |
| Actual DataStore save / reconnect | WARNING | Active load verified; persistence across save/rejoin and concurrent session behavior not established. |
| Currency / prices / biome ownership UI | PASS | Twelve callback regressions pass; live screenshot displays actual balances 100/0; authoritative price and update paths verified. |
| Pet/trade/merge/decor UI | WARNING | Existing sample panes depend on future phases. |
| Settings / redeem availability | PASS | Missing/wrong-type endpoint disables actions with Coming Soon; no fake preference changes or discarded codes. Actual-source callback regression passes, including endpoint changes and working HideUI. Future backend is listed in H. |
| Script syntax / source build | PASS | Final 22:46:32 UTC build/sourcemap both exit 0; all 64 first-party runtime scripts compile without errors. Settings and authored-world/perimeter regressions pass. |
| Fresh Studio gameplay startup/output | PASS | Fresh runs started cleanly, assigned a plot, and reported API availability. Actual in-game SystemAudit repeated at 22:48:01 UTC with 0 failures. Latest post-edit Play began at 22:56:45–22:56:46 UTC and its lifecycle audit finished at 22:58:34 UTC with zero failures. |
| Performance | WARNING | Whole-world polling/prototype churn and static physics defects repaired; no populated-server frame/memory benchmark. |
| Multiplayer safety | WARNING | Security/lifecycle regressions pass; true two-client contention and replicated visual comparison remain unverified. |

The first SystemAudit invocation from Command Bar reported one profile lookup failure caused by the Command Bar module context. Running the same audit as an actual in-game server Script at **22:09:37 UTC** returned **zero failures** and confirmed the active profile; the real-Script rerun at **22:48:01 UTC** also passed. Later `FireServer`/`WeatherVFX` errors in Output identify **CommandBar** test expressions, not a project script. Unrelated plugin/backend errors are excluded. The final fresh session had no project startup error. At 22:59:37 UTC an audit Command Bar expression attempted to access WeatherVFX after its event-start request was rejected outside the admin room, producing a nil-reference error in the audit command. The rendering check was then run through the client controller successfully; this was not a gameplay startup failure.

## H. REMAINING ITEMS

Only genuine future asset/system work is listed here. Verification caveats belong in G and J, not in this list.

- **FUTURE PET PHASE:** Real pet acquisition/assets, inventory/index integration, pet-derived income/progression, merging, and pet trading. Current sample panes are not a completed gameplay loop.
- **FUTURE 3D ASSET PHASE:** Repair the imported foliage texture/alpha/material assets responsible for conspicuous black card backgrounds in MagicalForest/rear Mythical; improve biome background/transition artwork across broad bare concrete and reconcile mismatched Volcano scenery. Also supply real decoration/furniture assets, catalog ownership integration, and plot decoration/placement. No furniture, pets, eggs, or decoration-placement systems were added.
- **FUTURE SETTINGS / REDEMPTION INTEGRATION:** Connect existing preference/graphics controls to actual settings behavior and implement legitimate redeem-code validation/rewards. This is unrelated to pet/decoration assets. Controls clearly show Coming Soon and remain disabled while their real handler is absent.

## I. AFTER AUDIT SCORE

**After score: 111 / 150**, based on completed live map, lifecycle, admin, navigation, perimeter collision, and sky rendering evidence. Two-client testing and DataStore write/readback are not credited as completed. The game has a stronger working foundation; remaining polish and future gameplay phases prevent a production-readiness claim.

| # | Exact rubric category | After /10 | Evidence and limit |
|---|---|---:|---|
| 1 | MAP VISUAL QUALITY | 6 | Fourteen region views confirm grounding; conspicuous foliage-card backgrounds, bare concrete transitions, and inconsistent imported styling remain. |
| 2 | BIOME ALIGNMENT | 9 | Twelve bases satisfy measured common level; intentional internal elevations retained. |
| 3 | OBJECT PLACEMENT | 7 | Confirmed floating prop/staging/duplicate issues repaired; not every mesh inspected individually. |
| 4 | NAVIGATION / PLAYABILITY | 8 | Twelve biome/four plot routes pass and four visible perimeter walls address walking into void; future progression remains blocked. |
| 5 | COLLISION QUALITY | 8 | Invisible helpers repaired; main landings/routes and all four perimeter collision raycasts pass. Not every narrow gap traversed. |
| 6 | SPAWN SAFETY | 8 | Four plot/admin entry/return and actual same-plot respawn pass; real two-player contention still needs coverage. |
| 7 | WEATHER VISUAL QUALITY | 7 | Fixed moon/rainbow/aurora are visible and turn-away behavior passes; angular ribbon styling remains basic, and populated-client performance is unmeasured. |
| 8 | WEATHER EVENT RELIABILITY | 8 | Eighteen-event lifecycle passes three times, including final all-source Play, and production timing passes. Real multi-client comparison remains limited. |
| 9 | ADMIN SYSTEM RELIABILITY | 9 | Full live client suite passes; room, labels, controls and announcements preserved. |
| 10 | PLAYER PLOT RELIABILITY | 7 | Four correct slots and active ownership verified; real concurrent joins/releases not yet proven. |
| 11 | UI READABILITY | 7 | Currency/prices/countdowns/layout repaired; unavailable settings are clearly disabled. Future sample pet/decor panes remain. |
| 12 | SCRIPT HEALTH | 8 | Known scale source removed; syntax/runtime smoke and final fresh startup pass. |
| 13 | PERFORMANCE | 7 | Obvious polling/churn/physics problems reduced; no populated-server benchmark. |
| 14 | MULTIPLAYER SAFETY | 6 | Server policy/session tests pass; true two-client and reconnect verification outstanding. |
| 15 | OVERALL GAME READINESS | 6 | Map/admin/weather foundation improved; future gameplay and unproven multiplayer/persistence limit readiness. |
| | **TOTAL** | **111 / 150** | **+42 points over before** |

## J. BUILD RESULT

**PASS:** `rojo build default.project.json --output documentations/full-audit-20260917/AnimalKingdom-source-audited.rbxlx`

**PASS:** `rojo sourcemap default.project.json --output documentations/full-audit-20260917/AnimalKingdom-source-audited.sourcemap.json`

Both exited **0** after the final source changes at **22:46:32 UTC (15:46:32 PDT)**. Native Luau compilation passed for **64 first-party runtime scripts, 0 errors**. Actual-source systems/admin, UI, settings, authored-world preservation, and perimeter regressions passed. Evidence: `final-build-evidence.json`, `final-script-sha256.json`, `build-results.txt`, `compile-results.txt`, `systems-test-results.txt`, `settings-test-results.txt`, `perimeter-test-results.txt`, `final-map-results.txt`, `map-source-findings.md`, and `weather-repair-notes.md`.

**Build scope:** The `.rbxlx` above contains the source mapping, including portable fallback geometry. It does not contain all live-only authored Town/biome assets. Use the final full live-place save for the complete map; do not overwrite it with the source-only build.

Fresh Studio results: weather lifecycle **22:02:57 UTC — 18 events / 134 checks / 0 failures**; admin client suite **22:05:54 UTC — 0 failures**; navigation **22:06:27 UTC — 12 biome clearances and 16 routes / 0 failures**; actual in-game SystemAudit **22:09:37 UTC — 0 failures, one connected player, active ProfileStore session**. See `live-verification-excerpts.txt`.

Additional checks: actual same-plot respawn **22:28:42 UTC — PASS**; twelve final biome heights plus four perimeter walls **22:37:10 UTC — PASS**; weather lifecycle repetition **22:38:56 UTC — 18 events / 134 checks / 0 failures**; all four perimeter collision raycasts and actual-Script SystemAudit **22:48:01 UTC — PASS**; final post-edit Play startup **22:56:45–22:56:46 UTC — plot assigned, API services available**; final all-source weather lifecycle **22:58:34 UTC — 18 events / 134 checks / 0 failures**. Final celestial captures and all fourteen map overview captures are recorded in C/E.

**Complete full-place delivery: PASS.** `AnimalKingdom-after-full-audit-20260917.rbxl` contains the audited live map and installed source. Verified binary signature, size **9,522,310 bytes**, SHA-256 **`6025a5ac8c4980490dfe75628a4f7eb0e2d56ba79bb3889003fdb7f3a8ce2ff7`**; see `final-place-evidence.json`. The final fresh-session lifecycle repetition passed. Actual two-client and save/rejoin persistence checks remain unverified; API availability is not a saved-write/readback test.

## K. LIVE TEST CHECKLIST

1. Open the final full audited place, start a fresh Play session, and inspect Output. Confirm no project syntax/nil/infinite-yield/scale errors. The saved Workspace attribute `AK_CommonPlayableFloorY` must equal approximately 9.12893057; the audit printed this value during the repair pass. Ignore identified unrelated plugin/backend chatter.
2. Spawn as a new player. Confirm a real plot is assigned, its existing username sign updates, and the avatar is above the floor with movement enabled. Reset the avatar and repeat.
3. Use Start Server with two clients. Confirm different real plots, correct names, no fence/display/spawn object treated as a plot, and no overlapping arrival. Leave/rejoin one client and check release/reassignment. If testing capacity, the fifth player must not receive a duplicate of four occupied slots.
4. Walk from plots through Town and all twelve biome entrances. Check raised edges, paths, narrow spaces, floor seams, and all four visible perimeter walls; normal walking should stop at the supported boundary. Walk under/around MagicalForest trees to detect remaining invisible helpers.
5. Inspect Meadow, Forest, Jungle, Desert, Snow, Volcano, Ocean, Ancient Ruins, Magical Forest, Sky, Prehistoric, and Mythical from ground level and elevated view. Verify aligned base surfaces, grounded objects, preserved cliffs/cone/ruins/clouds, and no staging objects floating over the map.
6. Use Biome Teleport for legitimately unlocked destinations. Confirm safe landing. A locked biome must reject teleport; a successful authorized unlock must use the displayed server price and update ownership. Do not grant currency or fabricate pets for this test.
7. Test `/weatherroom`, `/return`, room entry/return after moving/resetting, all named camera buttons, plot/Town cameras, and exit from camera/spectate mode. Existing room labels and controls should remain readable.
8. Test weather start/end/random/pause/resume, event queue/replacement/clear, emergency reset, player controls, server status, activity log, and a filtered announcement. Confirm a non-admin cannot invoke protected controls.
9. Start Blood Moon. Look toward (-6338,8008,-23752), turn away, return, and walk sideways. The moon must keep its world position, disappear outside the view, and agree in logical location across both clients. End it and confirm normal moon behavior restores.
10. Start Rainbow. Look toward (-500,60,-2200), turn away/back, and move. The arc must stay in place. End/reset and confirm every beam/anchor disappears.
11. Check Aurora/Void fixed placement and Meteor Shower/Thunderstorm world direction. Camera rotation must not swing those phenomena around the player. Rain/snow should stay upright when looking up/down.
12. Exercise all 18 events individually: Sunny Skies, Rainy Day, Thunderstorm, Snowfall, Foggy, Windy, Heatwave, Aurora, Blood Moon, Meteor Shower, Spirit Night, Rainbow, Chaos, Inverted, Nightmare, Void, Golden, Admin Abuse. End each and confirm no leftover event particles, sounds, anchors, colors, atmosphere, or clouds. Replace events rapidly and emergency-reset once during an active event.
13. Confirm initial Break is five minutes and a normal/admin event is seven minutes. Compare TIME LEFT on both clients against WeatherState.EndsAt and server time; pause/resume must agree.
14. In a fresh client's initial Break, run `tests/WeatherAudit.studio.client.lua` in the **client** Command Bar. It injects local test state to verify visual lifecycles; use the admin/server tests for authoritative transition checks. Record its PASS/FAIL output.
15. Run `tests/SystemAudit.studio.server.lua` as an actual server Script during Play to use the gameplay module context. Run `tests/BiomeTeleport.studio.lua` in the server context, then `tests/AdminCommandCenter.studio.client.lua` in the authorized client's Command Bar. Record results and inspect Output for real project errors.
16. Resize the viewport and test a narrow phone layout. Open/close/reopen Biomes quickly. Confirm cards, prices, TELEPORT/UNLOCK, balances, weather card/countdown, admin controls, and announcements remain readable. Settings/graphics/redeem should show Coming Soon while their handler is absent; clicks must not change preferences or erase a typed code. HideUI/ShowUI must still work.
17. Change a legitimate server-side balance through existing gameplay/admin mechanisms and confirm the HUD updates; it must never revert to demo balances. Rejoin to verify actual DataStore persistence/session behavior in an API-enabled test environment.
18. During a populated server and the heaviest event, inspect frame rate, physics load, memory, and Workspace after event cleanup. Confirm hidden fallback content does not appear and prototype pads/spheres do not respawn.

### Final live evidence to record

- Final place file: **PASS** — `AnimalKingdom-after-full-audit-20260917.rbxl`, 9,522,310 bytes, valid binary signature and verified SHA-256 in `final-place-evidence.json`. This is the complete authored map; the source-only build is not.
- Transform/re-audit report: **PASS**, `biome-alignment-plan.json`, `final-map-results.txt`, and applied/alignment/navigation output in `live-verification-excerpts.txt`; twelve final floors and four perimeter walls verified.
- Fresh Play session and output range: initial audited Play loaded at approximately **22:00:57–22:01:00 UTC**; suites ran through **22:09:37 UTC**. A subsequent Play started **22:37:41 UTC** cleanly; its weather rerun finished **22:38:56 UTC** with zero failures. Actual-Script SystemAudit and all four perimeter collision checks passed at **22:48:01 UTC**. Latest post-edit Play started **22:56:45–22:56:46 UTC**; its lifecycle repetition finished at **22:58:34 UTC** with zero failures.
- All-event visual lifecycle result: **PASS three times — 18 events, 134 checks, 0 failures**, including final all-source Play. Final rendered Blood Moon/Rainbow/Aurora appearance and moon/rainbow turn-away screenshots are confirmed.
- Region overview review: **14/14 reviewed**, covering all twelve biomes plus Town and Player Plots. Grounding and connectivity are verified at overview level; art limitations remain listed in H.
- Admin/plot/biome live smoke result: **PASS — admin suite, actual-runtime SystemAudit, 12 biome clearances, 16 Town routes, and actual same-plot respawn.**
- Two-client and persistence limits: **WARNING — one actual connected player in verified gameplay runs; Server & Clients was attempted but zero clients joined that test server. Save/rejoin write/readback has not been demonstrated.**
