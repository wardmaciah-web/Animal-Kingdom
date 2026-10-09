# Coati production-mode proposal — disabled

Implements the preparation scope in [issue #4](https://github.com/wardmaciah-web/Animal-Kingdom/issues/4).
This branch does not deploy itself, activate a grant, change the live configuration,
or execute [issue #2](https://github.com/wardmaciah-web/Animal-Kingdom/issues/2).

## Exact authority

| Capability | Proposed v1 permission |
| --- | --- |
| Dispatch | Canonical repository, issue **2**, stable ID **coati-sdxl-memory**, trusted issuer plus existing SHA-256 dispatch comment |
| Approval | Separate **production-coati-v1** class; local current-user DPAPI grant bound to exact policy and controller hashes, expiring after 24 hours |
| Quantity | One source-proposal workflow, consumed before profiling; a failed/interrupted claim cannot silently renew itself |
| Editable files | `tools/pet_pipeline/generate_concepts.py`, `tools/pet_pipeline/run_concepts.py`, `tools/pet_pipeline/concept_coati_anatomy.json` — task branch only |
| Read-only context | `tools/pet_pipeline/pet_pipeline.py`, `resource-policy.json`, `production-policy.json`, plus existing `AGENTS.md` instructions |
| Fixed actions | `profile-resources` uses GetPerformanceInfo, a pinned `nvidia-smi` query and a fixed read-only PowerShell pagefile/process query; `propose-source` and `static-qa`; no task-supplied argv or executable |
| Tests | `text-contract`: broker comparisons; `syntax`: `ast.parse`/`json.loads`, never `exec` or import; `git-diff-check`: fixed Git whitespace checks |
| Reporting | Existing issue and Notion pipeline row `3f3d6658-7369-812c-b612-ef141e6fe703`; existing report fields only |
| Branch actions | Create/push `akcc/coati-sdxl-memory/rN`; stop at review; no main writes, merges or self-review comments |
| Storage | Existing per-revision broker evidence; proposed trial scratch `D:/AnimalKingdom3D/scratch/command-center-coati-v1`; trial outputs `D:/AnimalKingdom3D/outputs/command-center-coati-v1` |
| Artifacts | JSON, JSONL, Markdown and one PNG concept; no approved asset replacement or automatic cleanup |
| Admission | At least **16 GiB system commit headroom**, **4 GiB RAM**, **7 GiB VRAM**, **10 GiB disk** |
| Trial ceilings | One seed, at most 1024 × 1024, 35 steps, 900 seconds, 0.5-second sampling; **4 GiB commit**, **1 GiB RAM**, **0.25 GiB VRAM** stop reserves |

The existing production `resource-policy.json` is read-only. The JSON policy and
independent broker ceilings agree; editing only one does not expand permissions.
The proposal may still investigate low-memory telemetry: a failed trial admission
does not prohibit a read-only profile or an unexecuted source diff.

`src/`, all approved models/references, the roster, generation safety code, tests,
controller, policy, `AGENTS.md`, Git metadata, workflow files and credentials are
outside edit scope. The task cannot choose another Notion page, species, issue,
program, environment, output path, network destination or action. No shell, paid
service, purchase, pagefile/OS setting, deletion, Studio operation, publication,
biome unlock, reconstruction or full production queue is included.

## Important execution limitation

**This proposal enables investigation and source proposals, not execution of newly
generated Python.** An allowlisted filename is not a security boundary: a modified
Python test or generator could execute arbitrary commands under the broker's user.
Removing token environment variables alone would not prevent it from reading the
user's credential files or Credential Manager.

Therefore proposed Python is parsed as data and never imported or run on the host.
`production_trial.request_trial` fails closed even with a valid grant. The inspected
PC has no `C:/Windows/System32/WindowsSandbox.exe`. No Windows feature was enabled,
account created, ACL changed, VM installed, or new execution permission activated.

`production_trial.py` generates a **non-executable review plan** with fixed mounts,
network/clipboard/audio/video/printer redirection disabled, a read-only bundle,
and one disposable output mount. It has no LogonCommand and no launch fallback.
The plan does not establish an isolation guarantee. Microsoft documents the
[Windows Sandbox configuration controls](https://learn.microsoft.com/en-us/windows/security/application-security/application-isolation/windows-sandbox/windows-sandbox-configure-using-wsb-file).

Before any GPU trial, a separately reviewed execution backend must demonstrate:

- Denial of credential access, networking, unmapped host paths and approved assets.
- A dedicated, cancellable VM/process lease; killing a GUI launcher is insufficient.
- Watchdog and crash cleanup that affects only the owned job.
- Usable CUDA under isolation, real host RAM/commit/VRAM telemetry, and bounded artifacts.
- Execution of the exact human-reviewed code/dependency bundle, not a mutable task checkout.

The missing backend is an explicit **Phase B blocker**, not a reason to fall back
to full-access host Python or reduce the 16/4 GiB commit gates. A real Coati concept,
peak measurements, visual QA, reconstruction and Studio integration are unverified.
This branch must not be described as ready for autonomous generation.

## Review and activation — do not run before user approval

1. Review the branch diff, this permission table and the test evidence. Decide
   whether to approve **source-proposal mode only**. Full inference requires the
   additional boundary above and is not granted by this activation command.
2. Have a human merge the reviewed PR. During an approved maintenance window,
   record the live worker's pause state and stop it using its existing `stop`
   command. Fetch and fast-forward the canonical checkout; preserve its unrelated
   uncommitted launcher fixes. Do not copy an old launcher over those fixes.
3. Restart the existing scheduled launcher with production still disabled. It
   retains its existing credentials, five-minute polling and documentation policy.
   Confirm the dashboard says `documentation-only`; the hourly ChatGPT watch is unchanged.
4. In a local operator terminal, from the reviewed canonical checkout:

   ```powershell
   $python = 'D:\AnimalKingdom3D\tools\python\cpython-3.11.17-windows-x86_64-none\python.exe'
   & $python -m tools.command_center.production inspect
   ```

   Review the displayed policy and both hashes **after deployment**. Then, only
   with explicit approval, substitute those literal hashes:

   ```powershell
   & $python -m tools.command_center.production activate --policy-sha256 '<reviewed-policy-hash>' --controller-sha256 '<reviewed-controller-hash>'
   ```

   Type the exact local confirmation `ENABLE production-coati-v1 FOR ISSUE 2`.
   The dashboard now identifies the active policy and its expiry. No remote issue,
   comment, dashboard request or config boolean can perform this operation.
5. Restore the previously approved pickup state. Preserve issue #2's narrative;
   append a reviewed `ak-task` block using `production-task.example.json`, replacing
   its policy-hash placeholder with the inspected hash. Use a positive new revision,
   add the queue label, then have an allowlisted issuer post the exact body-hash
   dispatch comment. Do **not** do any of those dispatch mutations during preparation.
6. Expect read-only profiling, an unexecuted source proposal, static checks, a task
   branch and a review handoff. A consumed or interrupted workflow stays consumed.
   Never clear the spent marker to retry; a new reviewed grant/policy is required.

Only the local operator can activate or revoke the grant. The grant protects against
remote task/code escalation; it is not a defense against a malicious same-user local
administrator who can replace the installed controller.

## Immediate rollback

From the reviewed checkout, revoke only the production capability:

```powershell
& $python -m tools.command_center.production disable
& $python -m tools.command_center.production inspect
```

The receipt becomes disabled; documentation tasks remain available. A running owned
Codex/Git child checks revocation at most once per second and is stopped by its Job
Object. Network reporting has existing bounded timeouts. Authorization is checked
again before applying edits and before committing/pushing. Uncommitted candidates,
task branches, logs, spent markers and approved assets are preserved.

For a binary rollback, stop the upgraded worker at an approved maintenance window,
point its launcher to a separate checkout of `8fdea86a3e0561a1ead64d199b4819e2b65cf905`
(including the operator's separately preserved launcher fixes), and restart it.
That version rejects the production approval class. Do not hard-reset the dirty
canonical checkout, delete evidence or rewrite a published branch. Restore the
previous documentation pickup state and verify a fresh heartbeat.

## Verification

Run from this branch:

```powershell
& $python -m unittest tools.command_center.test_bridge tools.command_center.test_production -v
& $python -m unittest discover -s tools/pet_pipeline/tests -v
```

The suites cover disabled-by-default behavior, local hashes/expiry/DPAPI, issuer and
revision forgery, path/ADS/hardlink escapes, self-edit attempts, unauthorized actions,
resource exhaustion and unit separation, duplicate/crash claims, revocation of an
owned child, unchanged documentation behavior, static-only malicious candidate
handling, forbidden VM mounts, no host fallback, existing watchdogs and cleanup.
All activation fixtures are temporary D: test directories, not the live runtime.
