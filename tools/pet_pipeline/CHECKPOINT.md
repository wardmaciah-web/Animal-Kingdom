# Implementation checkpoint — 2026-10-08

User approved the original free Ocelot. Its GLB SHA256 is
`d00c5ceb074ec9e67ec8eeaaae7a358d7cc4f4dd04e9b475958eada868b67cc7`.
The original asset is preserved unchanged. Approval of that asset is not evidence
that the newly packaged pipeline reproduces it yet.

Implemented: pinned vendored inference source, model hashes, environment snapshots,
preserved successful scripts, configurable stages, separate non-overwriting run
directories, four-view previews, numeric validation, explicit visual approval gates,
and native Roblox import preparation. Five approval-gate tests pass.

Clean reproduction results so far: 0 successful / 4 attempts. Attempts 001–003
crashed with native Windows access violation in PyTorch `param.copy_` while loading
the checkpoint. The untouched original script reproduces the same crash in
`outputs/original-workflow-diagnostic-001`. Attempt 004 used a separate diagnostic
recipe to stream identical FP16 weights to CUDA and failed with CUDA out-of-memory.
That loading variant is experimental and is NOT the production default. No new
geometry from these runs passed QA. Logs and manifests are retained in audits.

At investigation time: RTX 3060 12GB, approximately 8.5GB reported free VRAM,
16GB installed RAM, approximately 3GB available Windows commit, C: about 52MB
free, E: about 221GB free. Fortnite alone used about 4.4GB resident RAM. The CUDA
error despite available VRAM may involve WDDM/system commit; this is a hypothesis,
not a confirmed diagnosis. A temporary Fortnite closure was requested while
independent implementation continues. No user processes were terminated.

Live audit: each of ten future biomes has 25 anonymous registered pet slots,
250 total. Jungle has five empty named tree families; the other nine have no
explicit family definitions. Physical art copies are not equivalent to reward
families and require deliberate mapping. Meadow and Forest are preserved.

Remaining: resolve loading failure, clean Ocelot comparison, second original
species generation and art QA, durable Studio import verification, complete
unique rosters, all future-biome production, full feature integration, and every
tree-family reward test before biome release. No future biome has been released
and the Roblox game has not been published. The full user task remains active.
