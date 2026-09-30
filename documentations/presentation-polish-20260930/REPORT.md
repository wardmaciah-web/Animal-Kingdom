# Animal Kingdom presentation polish — September 29, 2026

Implemented in the connected **Animal Kingdom[TESTING}** place, PlaceId `132313449035787`, and its current mapped source. This pass extends the existing controllers. It does not rebuild Activities, guidance, announcements, weather, or tree searching.

Studio is left in Edit mode. Nothing was published. No assets, models, images, or downloads were added. Mobile checks were skipped at the user's request.

## Coverage and evidence

| Requested correction | Result | Evidence and limits |
|---|---|---|
| Larger shared announcements | Implemented; desktop Play tested | Responsive white titles, dark stroke, soft shadow/glow, restrained accents. Measured 40 px titles and 21 px secondary text at a 1722 px viewport. Existing queue retained. |
| Journey/activity progress feedback | Implemented; Play tested | Three real mock-profile Meadow searches produced Journey 1/3, 2/3, then step-complete with the next Sanctuary objective. Rush acceptance and Paw discovery produced shared notices. |
| Announcement priority/coalescing | Implemented; fixture tested in Play | Ten rapid progress updates held during a reveal produced only the final update when released. Important notices hide the compact objective HUD temporarily. No vertical notice stack. |
| Strong Hot Tree presentation | Implemented; Play tested | All five variants had distinct colors and active glow/particle values. Fresh Play verified the floating Heavy label, countdown, stronger silhouette, and halo around the tree. |
| Open-ground paw placement | Implemented; server validation and Play tested | Six valid markers in each biome; all outside tree bounds on eligible ground. First marker in each biome reached by walking and discovered with E. Remaining markers completed using server-validated scripted player positions. |
| Smooth foot guidance | Implemented; Play sampled | One retained arrow object with tapered Beams, continuous delta-time interpolation, gentle movement, near-target fade, and target emphasis. Sampled intermediate heading changes across 46 render frames; same arrow instance retained. |
| Meadow world life | Implemented; visually observed | Walked Meadow and observed for 12 seconds: several drifting pink petals, green leaves, and warm pollen points. Search anticipation and committed bursts exercised through real searches. |
| Forest world life | Implemented; visually observed | Walked Forest and observed for 12 seconds: falling leaf silhouettes, dust, firefly pockets, and localized low haze. Uses the existing leaf icon and particle textures. |
| Breeze/firefly/restless moments | Implemented; visual-state fixtures tested | Breeze/restless increased foliage from 24 to 36. Firefly moments increased each pocket from 5 to 12.5 particles/sec. Server schedule and reward behavior unchanged. |
| Weather and effects levels | Implemented; client fixtures tested | Rain, thunderstorm, snow, wind, fog, sun, and normal states checked. Fog suppresses custom mist; rain/storm/snow suppress delicate particles. High/Medium/Low densities use the existing settings. |
| Town attention | Implemented; partially Play tested | Walked board-to-shop and observed for 12 seconds. Shop sparkles and attention selection visible. Index, Garden, Activities, and Biomes eligibility paths are source verified; each was not separately exercised through a complete gameplay lifecycle. |
| Gameplay preservation | Source comparison plus targeted regression | Three Meadow searches each charged 250 and granted one pet; one Forest search charged 6,000 and granted one pet. Reveals continued normally. Original mock profile restored. No economy definitions changed. |

## Presentation tuning

Announcements retain the existing shared queue and tutorial/reveal suspension. Important titles scale between 32–42 px on desktop, secondary text between 18–24 px. The transparent presentation scales 0.90 → 1.05 → 1.00 over 0.34 seconds, holds approximately 4 seconds normally, 5 seconds for completion, or 5.5 seconds for special events, then fades over 0.5 seconds. Low-priority cosmetic messages hold 3 seconds. Routine transaction feedback stays compact. Reduced Motion removes the scale movement.

Secret/Lucky notices take critical priority; completions and significant records take high priority; progress, stock, and availability use normal priority; cosmetic moments stay low. Matching progress updates replace queued updates and can update the currently visible progress notice. Existing event/reward deduplication remains. A kilograms value alone is no longer incorrectly classified as a weight record.

Journey notices use the authoritative published objective text and progress. Completion shows the next actual objective. Initial profile publication does not replay historical progress. These notifications do not grant rewards or increment goals.

Hot Tree colors are purple for Heavy, green/gold for Lucky Treelet, gold for Rich, cyan for Fast, and orange for Mastery. The silhouette pulses smoothly over 2 seconds, with fill transparency 0.54–0.67 and outline transparency 0.04–0.16 nearby. Reduced Motion uses a steady presentation. Highlights remain eligible out to 245 studs, labels to 185, ground glow to 150, and particles to 115. Each active Hot Tree has one updraft and two modest orbit emitters. The halo radius follows the existing tree's footprint, clamped to 6–16 studs.

Play inspection caught the floating label being obscured. The final label explicitly adorns the existing visual anchor, sits in front of the full canopy footprint, and smoothly follows changes in camera direction. It remains depth tested against other world objects. A fresh Play capture verified the final label and halo.

Paw markers now sit 0.10 studs above ground, with a soft ground disc, existing paw art, shimmer, gentle pulse, and existing discovery sound. The prompt remains an 8-stud interaction, backed by the existing 9-stud server validation. Placement rejects water, steep surfaces, prop tops, building/plot areas, nearby visible or collidable obstacles, and overhead foliage. It maintains at least 5 studs outside the complete tree bounding footprint and validates a walkable path. Markers are at least 16 studs apart. An obstructed active marker can relocate without resetting the accepted run or earned progress.

The measured Meadow trail was 419.05 studs with 22.24 studs minimum marker separation; Forest was 319.34 studs with 38.97 studs minimum separation. Trail construction took about 1.04 seconds and 1.88 seconds respectively in this Studio session. These are two observed trails, not exhaustive proof for every possible world configuration.

The existing guidance owner retains its target and Beam objects. Heading smoothing uses `1 - exp(-dt * 16)`, while the visual follows the player's horizontal position each rendered frame. Ground height is sampled separately. A short tapered ribbon and chevrons replace blocky parts; the direction fades near the destination while target emphasis increases. Tutorial guidance keeps priority. No new arrow controller was introduced.

## Ambience and performance controls

High effects use 24 pooled drifting leaves/petals at baseline and at most 36 during a cosmetic breeze. Medium uses approximately 65% density; Low and Reduced Motion use 35%, with nine baseline foliage visuals. No emitter is attached to every tree.

Meadow has 24 pollen particles/sec at baseline. Forest has 11 dust particles/sec plus three selected firefly/mist pockets, each at 5 fireflies/sec and 0.9 mist particles/sec. Pockets are distance culled and relocate after sufficient player movement. Town uses five drifting foliage visuals and local motes, plus attention at only one eligible functional landmark at a time. Meadow/Forest ambience stops in Garden; Town ambience requires actual proximity to Town.

All continuous emitters share a cap of 96 particles/sec multiplied by the selected quality scale. Search bursts are separately throttled. The foliage pool, pocket count, highlights, and special-tree effects are bounded. One render connection owns this controller's motion, with state refreshes at 5 Hz. The guidance controller retains its own existing render connection. Cleanup disconnects listeners and destroys local effects.

The existing trees are predominantly single meshes. Their authored CFrames, colliders, interaction anchors, and gameplay models are not animated by this pass. Wind is communicated through moving foliage, particles, and restrained light emphasis. No independent canopy/grass deformation is claimed. Existing search shaking remains the visual owner of tree transforms.

Weather selection and timing are untouched. Rain reduces pollen/fireflies and increases drift; thunderstorms increase wind and suppress delicate effects; snow suppresses bright pollen; fog disables custom mist; wind accelerates foliage; sun increases delicate visibility. Cosmetic moments yield to major weather and use smoothed density/wind changes. No permanent Lighting modification was added.

## Test distinctions and remaining limits

- **Actual Studio Play:** Town, Meadow, and Forest walks with approximately 12-second observations; first Paw discovery by walking/E in each biome; real normal searches/reveals; Journey progress/completion; accepted Rush guidance; actual Lucky Tree spawn; Hot Tree visuals and final label.
- **Fixtures within Play:** Remaining Paw positions, all five Hot visual variants, weather/quality states, cosmetic moments, stock notification, and announcement coalescing. The server-record banner replayed an actual current record snapshot; it was not a newly earned weight record. The Forest Raccoon search at 7.1 kg was not claimed as an exceptional weight record.
- **Static/source verification:** 173 scripts compiled with zero errors. SHA-256 comparison shows exactly eight changed mapped files and 655 unchanged files, with no added/deleted mapped source files. Prices, pools, pet stats, Weight rolls, Hot gameplay modifiers, Lucky rewards, Shop/Garden/Mastery/Contract definitions, weather scheduling, profile services, and release gates are byte-identical to the starting checkpoint.
- **Mock restoration:** Fixture asserts Studio and mock-profile mode, uses a copied profile, and restores the original data table. Five original UIDs and their saved weights/locations remain. In the final fixture, accumulated Sanctuary coins were `605491.3651860262` both before and after restoration. Production profiles were not written.
- **Not performed:** Mobile/controller/device-matrix testing, two-player testing, a full new-player tutorial replay, durable persistence testing, every activity completion, every Town attention lifecycle, or a hardware performance benchmark. These are not presented as passing tests. This pass did not re-prove the earlier expansion's entire gameplay matrix.

The final console contained no new errors from the changed scripts. Existing asset-availability warnings and the unavailable local Superbullet backend remain outside this presentation pass. No missing assets were downloaded or fabricated.

## Changed files and recovery

| File | Purpose |
|---|---|
| `src/ServerScriptService/ServerSource/Utilities/ActivityRoutes.lua` | Open-ground Paw selection, clearance, reachability, and safe retargeting. |
| `src/StarterGui/AnimalKingdomUI/ActivityPresentation.lua` | Progress notices, Paw feedback, and Town attention state. |
| `src/StarterGui/AnimalKingdomUI/AdventureStatus.lua` | Compact HUD yields while the shared announcement is visible. |
| `src/StarterGui/AnimalKingdomUI/AnimalKingdomUIV2/Overlays.lua` | Existing announcement queue styling, animation, classification, and coalescing. |
| `src/StarterGui/AnimalKingdomUI/AnimalKingdomUIV2/TutorialPointer.lua` | Reusable Beam guidance and smooth render updates. |
| `src/StarterGui/AnimalKingdomUI/Main.client.lua` | Connect authoritative publication to presentation; suppress redundant success toasts. |
| `src/StarterGui/AnimalKingdomUI/TutorialGuidance.lua` | Retain target emphasis and existing guidance priority. |
| `src/StarterPlayer/StarterPlayerScripts/TreePresentation.client.lua` | Hot/Lucky/Town effects, pooled foliage, biome ambience, and weather/quality integration. |

The unmapped fixture is `tests/presentation-polish/VisualFixture.server.lua`; it is not shipped through the source map. This folder contains `checkpoint-before/`, `checkpoint-after/`, source hash manifests, `source-changes.json`, and `play-evidence.json`. Screenshots were inspected through Studio tool captures; they are not falsely represented as saved PNG files here. No source-control repository was present, so recovery uses these file checkpoints rather than a commit.
