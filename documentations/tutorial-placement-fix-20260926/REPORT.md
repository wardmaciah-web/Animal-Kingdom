# Tutorial placement-to-collection fix — 2026-09-26

Only these gameplay sources changed:
- src/ServerScriptService/ServerSource/Server/TutorialService.lua
- src/StarterGui/AnimalKingdomUI/TutorialGuidance.lua

Updated regression expectations in tests/tutorial-held/Backend.server.lua. Backups and the exact diff are in before/ and changes.patch. Source hashes confirm every other src file is unchanged.

## Cause

The observed mock profile had tutorial UID a436fedf-1230-4963-8c89-a809193531f9 correctly placed in Sanctuary slot 2, while TutorialProgress.Step remained 4 and SlotId remained 1. The server required the originally suggested slot during live placement. The client then explicitly directed the player to pick up a pet placed in a different slot. Its generic prompt hint also reused dynamic Sanctuary ActionText, which changes to PICK UP after placement.

## Correction

- The server accepts the exact tutorial UID in any valid physical owned Sanctuary slot and advances to step 5, collection. The actual LocationSlot is retained for authoritative collection validation.
- TutorialService observes the existing profile Pets/ActiveHeldPetUID update signal, so placement/pickup reconciliation runs immediately after committed state changes. The existing polling fallback remains.
- The client handles separately replicated pet/progress updates: canonical Sanctuary placement clears PLACE targeting and presents collection guidance. It never uses the normal occupied-slot prompt to choose the next objective.
- Removed the pickup-recovery tutorial branch and dynamic PICK UP hint text. Placement guidance only targets empty slots and only emphasizes PLACE prompts.
- Manual pickup before collection returns the tutorial to step 4 and an empty placement target. Normal Sanctuary pickup/swap/place behavior is untouched.
- Resume uses the same canonical-location rule, including already placed pets whose saved suggested slot differs.

No ownership, placement, income, collection, Garden, navigation, world, profile schema, or other UI source was changed. No live saved profile was modified and nothing was published.

## Tests

- 47 existing mock backend assertions passed, including the revised alternate-valid-slot rule, stable collection state over repeated updates, manual pickup, re-placement, resume after character readiness, zero-credit rejection, and positive collection.
- Full mock UI flow: Biomes → Meadow → normal registered tree search/reveal → exact Held selection → Sanctuary → normal PLACE → collection objective.
- Test reward UID efd1d876-2cca-48cc-8e0a-70bc0709d997 retained all stats through placement. The actual UI placement landed in slot 1; a different valid slot was separately verified by the authoritative backend regression.
- The client monitor recorded 0 PICK UP tutorial messages, 0 Sanctuary paw targets after placement, and 0 incorrect arrow directions over 695 collection-arrow samples.
- Normal E pickup was exercised before collection: the same UID returned to Held, step 4 targeted an empty slot, and the message said Place your pet here to start earning. Re-placement returned to collection.
- Saved step 5 through the existing mock ProfileStore, read it back, and restored it through existing migrations in a fresh Studio session. Resume showed the collection message with no Sanctuary paw and an arrow exactly aligned to the collector (dot product 1). This was a mock reconnect simulation, not a production network rejoin.
- Walking onto the existing collector credited 97 coins (126 → 223) and opened Congratulations. The arrow and paw were removed.
- Rojo build passed. Both tutorial sources compiled during the Edit-mode sync and matched current Studio source afterward.

The original pre-test mock session was restored at the end. Its existing Fluffy Lop remains in slot 2 and now correctly resumes at collection step 5. Studio Play is left running for continuation.
