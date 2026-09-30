# Live validation status

The final eight presentation sources were installed in Studio EDIT mode at **2026-09-18 00:51:05 UTC** (September 17, 5:51:05 PM Pacific). A fresh Play run completed the final-source all-event sweep at **00:55:34 UTC: 181 assertions, zero failures**.

Verified on the final installed sources:

- All 18 event lifecycles, real avatar walking, 360-degree camera rotations, cosmetic collision safety, object/audio budgets, Break cleanup, baseline Lighting/wind restoration, and Low-quality switching.
- Revised 5600-stud Blood Moon, distant planet/star billboards, continuous Aurora ribbons, readability changes, overhead Chaos/Admin precipitation and synchronized audio stage definitions are included in this installed revision.
- All 18 event PNGs were refreshed during the final-source sweep. Moon, Aurora, Void planet and Admin celestial rendering is visible in the refreshed captures.

Evidence: [final source installation](final-source-install.txt), [final sweep](final-studio-sweep.txt), [refreshed captures](views/README.md), and [build/regression results](final-build-and-regression.txt).

Extended final-source verification completed at **2026-09-18 01:05:02 UTC: 100 assertions, zero failures, 114.08 seconds**. [Evidence](extended-studio-test.txt).

- Thunderstorm: 20-second continuous observation, three actual fixed-world lightning strikes, three positional thunder voices, peak 20 VFX BaseParts / 3 weather sounds.
- Chaos: 35-second observation, all four stages, matching rain/snow enablement, peak 62 VFX BaseParts / 6 weather sounds.
- Admin Abuse: 35-second observation, all four stages, matching rain/snow enablement, peak 135 VFX BaseParts / 5 weather sounds.
- Blood Moon/Rainbow/Void: anchors project into view when facing them, leave view when turned away, and stay fixed through full rotation/translation; world billboards retain their stud dimensions. Cosmetics did not intercept ordinary scene raycasts.
- Every observed temporary actor/voice was removed; Lighting, effects/Sky and GlobalWind returned to their original values.
- Mean Studio Heartbeat rates were 59.11 / 59.67 / 59.92 Hz; maximum observed gaps were 171.2 / 71.9 / 88.9 ms respectively. These diagnostics are not a render-FPS or device/server benchmark.

A test-only setup guard was corrected from `EndsAt` to the existing `BreakEndsAt` attribute before the successful run. The earlier guard failure stopped the test before execution; production weather code/timing was unchanged.

Other completed checks:

- All six reused sound recordings fetched successfully and reported loaded in Studio: [audio asset evidence](audio-assets-live.txt).
- The audio lifecycle/sequence mock passed **3,559 assertions**, including both complete 420-second Chaos/Admin audio sequences: [mock evidence](audio-mock-results.txt).
- The earlier 18-event sweep also passed 181 assertions; its log is retained separately as earlier-revision evidence.
- The previous dedicated meteor/ghost upgrade test passed 19 assertions, including 30-second crater expiration. It predates the final full-polish sources and does not replace their pending lifetime check.

Resumed verification on September 17, 2026:

1. **Completed:** dedicated final-source meteor/ghost verification, 19 assertions and zero failures, including the full 30-second crater lifetime. See [final phenomena evidence](final-phenomena-test.txt).
2. **Completed:** live admin-control regression at 01:33 UTC September 18, zero failures: six panels, 15 labels, all destinations, filtered announcements, queue transition, production timing, and emergency reset. See [final admin evidence](final-admin-regression.txt).
3. **Pending host dependency:** a fresh full authored-place recovery save. The Studio window returned long enough for the final gameplay run (83 server and 6 client assertions, zero failures), then macOS locked (`ScreenLocked = true`) and stopped exposing controllable Studio windows. Existing full-map backups remain intact; the new Rojo source build is not a full authored-map save.

The gameplay continuation and final validation limitations are documented in [the 20-system build report](../gameplay-20-systems-20260917/REPORT.md).

Audio limitations remain: **69 named specialized SFX slots are empty**. They use documented safe fallbacks or silence. No headphone listening or subjective final mix review was performed; successful loading is not proof of finished sound design. Two-client replication and populated-server/device FPS benchmarking are also not verified by this solo sweep.
