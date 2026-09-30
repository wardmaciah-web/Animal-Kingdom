# Pet visual foundation — production polish

The existing backend, pet IDs, profiles, rarity rolls, paid Meadow readiness checks, and income calculations are preserved. Visual models now pass through `Shared.Gameplay.PetModelResolver` and `PetAppearance`.

## Files

- `PetModelResolver.lua`: canonical definitions → strict existing Meadow resolver, or `ReplicatedStorage.PetAssets`, or compatible existing `Assets.Pets`. Never manufactures fallback animals. Imported template scripts are rejected; all clone geometry is anchored and non-colliding/querying/touching.
- `PetVisualGeometry.lua`: bounds from visible part corners, orientation parsing, contextual normalization, footprint fitting, and horizontal ground placement. Invisible roots and `PetBoundsIgnore` parts do not inflate bounds. Cosmetics remain in final fit bounds.
- `PetAppearance.lua`: canonical clone creation with contextual size, existing variant effects/labels/cosmetics, and body-bounds-based cosmetic placement. Source models are never scaled or pivoted.
- `PetDefinitions.lua`: consistent `PetTypeId`, `ModelKey`, and `BaseIncome` aliases plus an `imported` entry list for future species.
- `MeadowSanctuaryDisplay.lua`: keeps the existing module/service owner and authoritative displayed IDs, supports valid canonical definitions, fits clones to authored slot spacing, grounds them above the complete display collision surface, and skips unchanged visual replication. No pedestal geometry is removed or edited.
- `PetAssetValidator.lua` and `PetAssetDiagnostics.server.lua`: Studio-only diagnostics for missing definitions/models, duplicate IDs, bad rarity/income/bounds, and missing textures. Full structured diagnostics live on the diagnostics script's `Report` attribute.

## Geometry API

`Measure(model, reference?)` returns `Min`, `Max`, `Size`, `Center`, and eight cached `Corners` relative to the supplied CFrame (default model pivot). Only visible BaseParts count. It returns nil for invalid or empty bounds.

`Rotation(value)` accepts yaw degrees, Vector3 XYZ degrees, CFrame orientation, or nil. Inputs are validated/clamped. `ContextRotation(def, context)` reads e.g. `FollowerRotation`, falling back to `ModelRotation`.

`GroundCFrame(bounds, surfacePosition, rotation?, clearance?, yOffset?)` returns the model pivot transform. It centers the footprint on X/Z and keeps the lowest transformed bound corner at the surface plus clearance. Default clearance is .04 studs. Negative offsets cannot push geometry below the surface. Cache Measure's result once after sizing; GroundCFrame can run in the visual scheduler.

`Normalize(model, definition, context)` uses 2.8 studs longest dimension by default and 3.2 in Garden, multiplied by the context scale override. `Fit(model, limits, rotation, multiplier)` fits the complete clone inside safe dimensions; exceptional display multipliers may shrink the result but cannot exceed its neighbor limit.

## Sanctuary evidence and placement

The existing `PetSlot_XX` instances are real, collidable wood mesh models. Each nominal bound is approximately 22.163 studs, while actual neighbor centers are only 4.5036 studs apart. The placement code therefore caps usable width/depth at 96% of nearest horizontal neighbor distance and fills 78% of that usable footprint (approximately 3.372 studs, vs. prior 2.8 longest dimension). Height may reach approximately 4.756 studs for tall animals. Bounds include cosmetic geometry, preventing hats from violating the height cap.

The surface ray includes the entire authored display; overlapping wood tiers can be higher than the individual named slot. An optional `PetDisplaySurface` Attachment takes precedence for future authored display art. The placement records `DisplaySurfaceMode` and `DisplaySurfaceY`; a bounds fallback is explicit and should be reviewed visually. Front is the established identity yaw unless `PetDisplayRotation` is authored on slot/display or `DisplayRotation` is defined for the species.

## Add a pet

1. Import a textured Model or MeshPart into `ReplicatedStorage.PetAssets`, named with its stable `PetTypeId`. Keep imported geometry in canonical storage; do not use streamed Workspace templates. Existing Meadow templates remain in their current location.
2. Add one entry to the `imported` table in `PetDefinitions.lua`, for example `{PetTypeId="ForestOtter",DisplayName="Forest Otter",Biome="Forest",Rarity="Rare",BaseIncome=3,ModelKey="ForestOtter"}`. Use the existing actual rarity and biome identifiers. The example is documentation, not an added species.
3. Other-biome reward pools currently derive from `PetDefinitions.Ordered` and rarity weights in `EggDefinitions`; validate the resulting pool. Meadow uses five guarded explicit three-pet pools: a new Meadow pet needs intentional pool configuration and provenance, not a silent generic bypass. Marking it `IsMeadowPet` requires its real template path and exact mesh/PBR manifest.
4. Set optional orientation/scale overrides only when the imported model needs them. Rotation units are degrees. `DisplayYOffset` adds clearance; it cannot sink the animal.
5. Run the Studio diagnostics and inspect reward/inventory/index/follower/Garden/Sanctuary for the new content. No changes to the renderer or layout are needed to produce a real clone; pre-existing UI gating still determines where some legacy/non-Meadow features are exposed.

Current blocker: `MeadowHoneyLop` has no real model or provenance. It remains unavailable and its existing guarded reward pool remains blocked. Nothing substitutes a different animal or primitive geometry.

## Verification

- All seven runtime source modules and `tools/audit/pet_visual_geometry_test.lua` compile with the native Luau compiler.
- Existing gameplay adapter passes migration, economy, ownership/protection, XP and power checks, then fails its obsolete free-tree reward expectation. Substituting every modified file from the before-backup produces the identical failure; this is a pre-existing test mismatch.
- `tools/audit/pet_visual_geometry_test.lua` is a Studio Play test for all available canonical species, contextual bounds, several orientations, collision policy, source immutability, invisible roots, and unavailable model behavior. Its actual Play execution/results are recorded separately by the main pass.
