# Resumable pet factory

The factory owns `D:/AnimalKingdom3D/factory/queue.json`, scratch jobs under
`D:/AnimalKingdom3D/scratch/jobs/<run-id>/`, and preserved bundles under
`D:/AnimalKingdom3D/approved/<run-id>/`. It never adopts or cleans historical
outputs, Git files, existing models, shared weights, caches or source references.
Each job points TEMP/TMP at its own new `tmp` directory. Legacy entry points use
`scratch/session-temp`, which is never auto-deleted.

```powershell
$factoryPython = 'D:/AnimalKingdom3D/tools/python/cpython-3.11.17-windows-x86_64-none/python.exe'
& $factoryPython tools/pet_pipeline/factory.py status
& $factoryPython tools/pet_pipeline/factory.py run
```

`init` creates the queue once from the roster, excluding registered pets. Do not
reinitialize it. `assign --pet PET --kind concept|model --config PATH --reason TEXT`
supplies a species recipe. Parsed configuration and referenced image bytes are
hashed; repeated attempted configurations are refused. Changed retries require
an evidence-based reason. Model recipes must explicitly record an approved
concept. Historical species attempt limits and deferred-species rules still apply.

`run` resumes ready recipes sequentially. Failed runs retain their evidence; another
ready pet in the same biome may run only after fresh resource checks. Later biomes
wait for earlier ones. Technical completion stops for concept/visual review. An
interrupted row is marked for inspection after probing the generation lock, never
silently rerun or assumed successful. `reject --pet PET --reason TEXT` preserves
failed work and permits assignment of a changed recipe.

## Review, Studio and cleanup

1. Inspect the generated concepts/model against original bear, approved Ocelot
   and Red Panda quality fixes. Use existing `pet_pipeline.py review` for models.
   New acceptance checks include `no_duplicated_limbs`, `well_formed_paws` and
   `stylized_proportions`. Previous approvals are not changed.
2. `factory.py archive --pet PET` verifies technical/art approval and preserves
   GLB, packed editable Blender sources, all textures, configs, QA, logs and copied
   references. It writes SHA256s to `preservation.json` and a false-by-default
   `verification.template.json` with the required Studio checks.
3. Import the exact approved asset into the canonical Studio project. Extend
   existing PetAssets, definitions and physical tree reward families. Verify
   durable import, registration, real tree payout, rarity, weight, income,
   Inventory/Held, followers, Sanctuary, Index, server ownership and isolated
   save/rejoin. Restore test overrides and leave incomplete biomes locked.
4. Fill the receipt with actual results, mesh/texture IDs and hashes of Studio
   evidence files. Set `receipt_path` to its repository-relative path. Commit the
   receipt **without a commit field**, evidence and preservation manifest, then
   push to canonical origin/main. Add the resulting full SHA as `commit` to a
   runtime copy of the receipt.
5. `factory.py verify --pet PET --receipt PATH` verifies remote main ancestry,
   exact receipt/evidence bytes in Git, archived file hashes and GLB identity. It
   preserves verification/asset IDs in runtime and approved directories, cleans
   eligible scratch files and automatically tries the next ready pet.

Studio import, registration and testing are real review steps performed through
Studio, not invented or replaced by Python receipts. Multiplayer regression is
still required separately before release. The controller does not publish games.

## Strict deletion boundary

Eligible files are only inventoried `work/generated/scene-code.pt`,
`work/generated/source.ply`, `work/generated/raw.glb`,
`work/projected/projected.glb`, and files produced in the job's dedicated `tmp/`.
Everything else remains, including final meshes, editable sources, textures and
QA renders. The **same run** must pass all verification gates before any deletion.
Older failed/unverified runs are retained: age, low disk, another approved run
or upload success alone never authorizes deletion.

Cleanup checks SHA256 and size, rejects traversal, junctions/reparse points,
symlinks, hard links and Git directories, and unlinks individual files only.
Files added after inventory survive. A journal supports interrupted cleanup.
There is no recursive delete or blanket cache purge. Missing remote Git evidence,
altered archives or unknown ownership block cleanup. Use the factory commands;
their generation lock prevents cleanup during active production.

## Memory and storage

Admission remains **4 GiB available RAM, 16 GiB system commit headroom and 7 GiB
free VRAM**. Storage reserve increases to **10 GiB**. Low-disk recovery considers
only verified scratch receipts; if reclamation is insufficient, production stops.
Archive creation reserves space for the preserved copy plus 10 GiB.

Windows commit used/limit/peak now comes from GetPerformanceInfo, converting page
counts with PageSize ([Microsoft definitions](https://learn.microsoft.com/en-us/windows/win32/api/psapi/ns-psapi-performance_information)).
The watchdog samples RAM/commit every 0.5 seconds and records JSONL telemetry. It
stops and waits for only its own child when free commit drops below 4 GiB or free
RAM below 1 GiB, or telemetry fails. Emergency stop reserves do not lower admission.
Fast native allocations can outrun sampling; model-load peak validation remains
required once admission passes. RAM, commit, VRAM and disk are rechecked after
worker exit and before another stage/job can load.

Process exit releases Python/native/CUDA/Blender allocations. Existing concept
code also frees text encoders after embedding and empties CUDA cache between
sequential candidates. Proven FP16/mmap/low-CPU-memory loading, sliced/tiled VAE,
chunked reconstruction and Ocelot/Red Panda fixes remain unchanged.

Read-only system audit:

```powershell
& $factoryPython tools/pet_pipeline/audit_resources.py --output D:/AnimalKingdom3D/factory/resources.json
```

The audit records RAM, actual commit usage, GPU memory, pagefile allocation/use,
C:/D: storage and largest private-memory processes. Its own Python PID appears
while it runs. No pagefile changes, unrelated app termination, reboot, purchases
or scheduled unattended processes are performed.
