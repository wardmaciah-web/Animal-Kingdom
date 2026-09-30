Implemented in the connected Animal Kingdom testing place and the current local source. Studio returned to Edit mode. Nothing published; no assets generated or downloaded.

The inspected configuration contains 14 obtainable Meadow species and 11 Forest species. The baseline was read from the connected place and matched the local files before changes. It is recorded in `baseline.json`, including exact IDs, original prices, probabilities, rarities, base incomes, and base weights. All Meadow families previously cost 250; all Forest families previously cost 750.

Final prices use the requested ladder without adjustments. Values below use neutral Luck (1), each species’ base weight, and no temporary boost. Percentages are rounded for display; calculation uses the full normalized weights.

| Biome | Existing tree | Stable family ID / tier | Price | Pets: rarity, base probability, base coins/sec | Min / typical / max | Expected coins/sec |
|---|---|---|---:|---|---:|---:|
| Meadow | Blossombark | `Meadow_Shakeable_01` / 1 | 250 | Field Mouse (Common): 81.001473% → 2.5/s<br>Patchwork Lop Bunny (Rare): 17.673049% → 3.5/s<br>Blossom Bunny (Legendary): 1.325479% → 6/s | 2.5 / 2.5 / 6 | 2.723122 |
| Meadow | Honeybloom | `Meadow_Shakeable_02` / 2 | 500 | Meadow Chick (Common): 75.614367% → 4/s<br>Meadow Fawn (Rare): 22.684310% → 5/s<br>Cloudtail Fox (Legendary): 1.701323% → 8/s | 4 / 4 / 8 | 4.294896 |
| Meadow | Clover Crown | `Meadow_Shakeable_03` / 3 | 1,000 | Red Squirrel (Uncommon): 68.459658% → 6/s<br>Fluffy Lop Bunny (Rare): 29.339853% → 8/s<br>Prism-Antler Deer (Legendary): 2.200489% → 12/s | 6 / 6 / 12 | 6.718826 |
| Meadow | Sunpetal | `Meadow_Shakeable_04` / 4 | 2,000 | Meadow Goat (Uncommon): 77.777778% → 9/s<br>Meadow Buck (Epic): 11.111111% → 12/s<br>Daisy-Crown Bunny (Epic): 11.111111% → 14/s | 9 / 9 / 14 | 9.888889 |
| Meadow | Whisper Willow | `Meadow_Shakeable_05` / 5 | 4,000 | Daisy Hedgehog (Epic): 99.975006% → 14/s<br>Celestial Lamb (Secret): 0.024994% → 22/s | 14 / 14 / 22 | 14.002000 |
| Forest | Mossheart | `Forest_Shakeable_01` / 1 | 6,000 | Raccoon (Common): 82.088327% → 22/s<br>Tree Frog (Rare): 17.910180% → 36/s<br>Emerald-Wing Guardian (Secret): 0.001493% → 180/s | 22 / 22 / 180 | 24.509783 |
| Forest | Fernwood | `Forest_Shakeable_02` / 2 | 10,000 | Black Bear Cub (Common): 85.714286% → 32/s<br>Brown Bat (Epic): 14.285714% → 52/s | 32 / 32 / 52 | 34.857143 |
| Forest | Duskleaf | `Forest_Shakeable_03` / 3 | 17,500 | Skunk (Uncommon): 87.500000% → 46/s<br>Woodland Owl (Epic): 12.500000% → 70/s | 46 / 46 / 70 | 49.000000 |
| Forest | Elderbark | `Forest_Shakeable_04` / 4 | 30,000 | Badger (Uncommon): 88.607595% → 66/s<br>Leaf-Antler Guardian (Legendary): 11.392405% → 100/s | 66 / 66 / 100 | 69.873418 |
| Forest | Mooncap | `Forest_Shakeable_05` / 5 | 50,000 | River Otter (Rare): 93.023256% → 95/s<br>Crested Owl (Legendary): 6.976744% → 140/s | 95 / 95 / 140 | 98.139535 |

The minimum is also the most probable and median base-income outcome in all ten pools. Expected and typical income strictly increase within each biome. Mean rarity order also rises within each biome. Rarity composition is given by the species percentages above; Sunpetal’s two Epic entries together have 22.222222% probability. Rare/heavy lower-tier results can still outperform ordinary higher-tier results.

No species assignments, names, stable family IDs, PetIds, rarities, real models, or BaseWeights changed. Celestial Lamb and Emerald-Wing Guardian already had approved normal sources; no new Secret source was introduced. All 49 live copies resolve their family’s exact definition. Removed 30 obsolete `SearchCost=750` attributes from placed Forest trees; historical ServerStorage backups were left intact.

Three base rarity-weight overrides improve distribution while retaining every assignment:

- Honeybloom: Common 55 → 40; Rare remains 12 and Legendary 0.9. Common/Rare/Legendary probabilities become 75.614367% / 22.684310% / 1.701323%.
- Fernwood: Common 55 → 24; Epic remains 4. Common/Epic becomes 85.714286% / 14.285714%.
- Elderbark: Uncommon 28 → 7; Legendary remains 0.9. Uncommon/Legendary becomes 88.607595% / 11.392405%.

All other base weights are unchanged. These are input weights to the existing NormalTreeOdds calculation, not an additional Luck application. The Index uses the same calculation and published server modifier context. The Lucky promotional comparison is already conditional on actual normal odds; it needed no change.

Base income increases (coins/sec; no decreases):

- Meadow: Field Mouse 1 → 2.5; Meadow Chick 1.25 → 4; Meadow Fawn 2.5 → 5; Red Squirrel 1.75 → 6; Fluffy Lop Bunny 3 → 8; Prism-Antler Deer 7 → 12; Meadow Goat 2 → 9; Meadow Buck 4.5 → 12; Daisy-Crown Bunny 5 → 14; Daisy Hedgehog 4 → 14; Celestial Lamb 9 → 22.
- Forest: Raccoon 10 → 22; Tree Frog 22 → 36; Emerald-Wing Guardian 90 → 180; Black Bear Cub 12 → 32; Brown Bat 36 → 52; Skunk 15 → 46; Woodland Owl 45 → 70; Badger 18 → 66; Leaf-Antler Guardian 70 → 100; River Otter 28 → 95; Crested Owl 55 → 140.

Patchwork Lop Bunny (3.5), Blossom Bunny (6), and Cloudtail Fox (8) retain their original incomes. These are global species changes, so existing owned pets and Secret pets obtained through Lucky Trees receive the same base-income changes. No source-specific multiplier exists. Existing sale values also derive from these species definitions through the unchanged sale calculator.

The existing PetStats formula is unchanged: `min(1e12, round(BaseIncome * max(1, Weight / BaseWeight)^0.75, 2))`. The weight bands, weight roll, personal weights, mutation, XP, ownership, and UIDs were not changed. PetService.Publish already recalculates each pet’s CoinsPerSecond and publishes the same Sanctuary total used for actual accrual. Held and Sanctuary visual signatures already include CoinsPerSecond, so their caches refresh through the established lifecycle. Cards and labels consume that snapshot using the shared number formatter.

A necessary targeted economy correction: paid normal pet searches previously also rolled legacy gathering loot, multiplied by gathering and coin upgrades. In a neutral-weather mock Play test with level-4 coin/resource upgrades and a level-1 held Crested Owl, a 250-coin search returned 1,014 gathering coins plus a pet. Even a conservative minimum rebate at those settings exceeds 250 (322 coins). Because the starter price must stay 250, paid normal searches now skip that secondary resource/weather-loot block. The one pet transaction, search XP, Harvested signal, cooldown, records, streak, mastery, and contracts remain in the existing flow. Existing active contract IDs, progress and stored rewards are retained; newly generated price-based contract/mastery rewards follow their existing formulas with the new canonical prices. No progression reward formula was edited. Ordinary resource gathering keeps its loot. Lucky Trees use their separate unchanged event flow. The regression run at the same upgrade levels recorded exactly one -250 transaction, one new pet, and zero refund. See `legacy-rebate-proof.json` and `guardsFinal.json`.

The tutorial now selects only the existing tier-1 Blossombark family, avoiding an unaffordable random Meadow target. Search prompts (including the place-owned Meadow registration script), Index source details, and server insufficient-funds feedback all use the canonical configured price. The latter reports the full price and shortfall and directs players to collect Sanctuary income. No purchase menu was added.

Measured pacing, using mock/copy profiles:

- Actual client-driven new-player search: 250 starting coins → one 0.11 kg Field Mouse → 0 coins. Its 2.69/sec income rebuilt at least 250 in 93.45 seconds after placement. The first collection completed the tutorial; the recovered funds bought a second search. Travel, holding, placement, and collection charged nothing.
- Minimum-weight zero-balance fixture: one 0.10 kg Field Mouse, 2.5/sec, collected 250 in 100.09 seconds; total earned 250.222912 including the fractional remainder. No secondary gathering drop, grant, contract claim, Lucky reward, or boost was used.
- Other starter outcomes at base weight, calculated rather than sampled: Patchwork Lop Bunny needs 71.43 seconds for 250; Blossom Bunny needs 41.67. The probability-weighted mean of these waits is 94.18 seconds. Saving directly for the 500-coin tree with only the weakest starter takes 200 seconds.
- Five minimum-weight starters: 12.5/sec. Another 250 search takes 20 seconds; Honeybloom costs 40 seconds of income.
- Developed Meadow example: two Chicks, three Red Squirrels, three Goats, and two Daisy Hedgehogs; ten pets, 81/sec. The unchanged 2,500 Forest unlock plus a 6,000 Mossheart search costs 104.94 seconds of income from zero. After paying the unlock, the first Forest search takes 74.07 seconds.
- Newly developed Forest example: those ten Meadow pets plus two Raccoons; twelve pets, 125/sec. Fernwood takes 80 seconds of income.
- Developed Forest example: three typical pets from each tier; fifteen pets, 783/sec. Mooncap takes 63.86 seconds of income. This is not a full 70-slot stand.

The four multiple-pet setups above each accrued and collected in real Play for approximately five seconds. Their longer purchase times are calculations from the verified aggregate rate, not claims of full-length progression playthroughs. Measured accruals:

- Several starters: 62.652 earned in 5.012s at 12.5/sec.
- Developed Meadow: 406.109 earned in 5.014s at 81/sec.
- New Forest, Meadow plus two Raccoons: 626.514 earned in 5.012s at 125/sec.
- Developed Forest, three typical pets per tier: 3925.163 earned in 5.013s at 783/sec.

Pacing limitation to monitor: unlocking Forest with only five minimum-weight starters leaves an eight-minute wait for its 6,000-coin search. Meadow upgrades remain available during that time, and the stronger Meadow example above reduces the wait substantially. The single-pet starter wait of 1:40 is also a noticeable early pause. Neither was hidden behind Luck or Lucky payouts, and no new recurring subsidy was added. The requested initial prices were retained; biome unlock prices are unchanged.

Verification and scope:

- Exact production-module analysis: 530 assertions, covering 25 real models, exclusive normal sources, normalized nonzero odds, rarity ordering, increasing typical/expected income, five Luck contexts, Index membership, release gates, and Lucky configuration.
- Final live service/integration run: 453 assertions. The first search used actual client E input and the real reveal/Continue UI. The other nine families used their real ResourceService search in Play, including heartbeat commit, feedback, reveal, cooldown and natural restoration. A recovery search also ran. All 49 live copies had correct names/prices and the exact shared family definition.
- Client observation: all ten families delivered real reveal feedback and reached rendered Showcase views; the final observed run also includes the recovery and upgraded-regression searches. Held/Sanctuary labels and the Pets card displayed the expected published rate. The first-pet reveal used the actual imported model.
- Index renderer: 30 assertions across all ten families, verifying displayed price, base probability and effective probability at Luck 1.55.
- Failure/exploit guard tests: 8 assertions for actual insufficient-funds requests, cancellation after moving away, restoration without charge, and the upgrade-refund regression.
- Timed Sanctuary fixtures: 63 assertions; weakest starter measured for 100 seconds and four representative multiple-pet rates measured live.
- Copy/migration/publication tests retained UIDs, weights, XP, mutation, shiny/prismatic/favorite/locked flags, cosmetics, acquisition time, locations, contracts and records. A 12,345.67 uncollected balance and an existing non-250 coin balance survived refresh exactly. JSON copy restoration preserved the accumulated balance. Test fixtures restored the original mock snapshot afterward. This was not a production datastore migration or durable multiplayer persistence test.
- Lucky regression: both biome events remained free, three tries, fixed 5/40/55 categories, 5,000/20,000 coin awards, 300-second 1.35/1.55 boosts, and unchanged template IDs. Fourth tries failed. Lucky actions did not add normal search streaks. Single-active-event scheduling and asset selection code were unchanged.
- Jungle and every later biome retain ContentReady=false; Jungle family pools stay empty. Current Index completion remains 25 species.
- Final Edit-mode verification retained all 49 original tree names, family IDs, pivots and descendant counts, with no remaining per-copy SearchCost attributes. Temporary test scripts were absent after stopping Play. Core Lucky, release, profile, weight, shared odds, PetStats, PetService and SanctuaryService sources are byte-identical to the inspected baseline.

All targeted final tests passed. Early waiting and long-term economy behavior still warrant broader player testing; this short pass does not prove long-term balance. No trees were rebuilt, renamed, repositioned or remodeled. No assets were generated/downloaded. No publication occurred.

Evidence is in the adjacent `*Final.json` files, `baseline.json`, `income-changes.json`, and source diffs. Re-runnable temporary tests are in `tests/tree-economy/`. The synced production changes are the tree and pet definitions, ResourceService, EggService, TutorialService, and PetMenus. The place-owned prompt formatting and removal of obsolete per-copy prices are reproducible using `tools/gameplay/ApplyNormalTreeEconomyMetadata.studio.lua` in Edit mode.
