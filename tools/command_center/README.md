# Animal Kingdom Command Center

Implements [issue #1](https://github.com/wardmaciah-web/Animal-Kingdom/issues/1)
for `wardmaciah-web/Animal-Kingdom`. The worker runs locally on Windows under
the current user. It never merges task branches or publishes the experience.

## What is enabled

The default policy accepts bounded text tasks in
`documentations/command-center-tasks/`. It supports exact-content/substring
acceptance checks, Git whitespace checks, and non-executing Python/JSON syntax
checks. Codex proposes edits in a JSON response; the trusted controller applies
only validated files. It does not run shell commands supplied by issues, comments,
Notion, or the model. Generated Python is never executed by these checks.

Game source, pet-pipeline source, approved models, release locks, credentials,
workflow files and the controller itself are outside this worker's edit authority.
Studio-dependent tasks stop with an explicit blocker. This is a deliberately
restricted first deployment, not an unrestricted replacement for interactive
Codex or the pet factory. Widening edit/test permissions requires a separate
reviewed policy change. Issue #2 must not run during bridge setup.

## Queue contract

Create a GitHub issue with label `ak-command-center` and exactly one fenced
`ak-task` JSON block, following [task.example.json](task.example.json). The issue
author must be in the local `trusted_issuers` list. Each task has an immutable ID,
positive revision, source, priority, approval class, exact allowed files, existing
Notion row, instructions, acceptance criteria and trusted check names.

An authorized issuer then comments exactly:

```text
ak-dispatch SHA256_OF_THE_ENTIRE_CURRENT_ISSUE_BODY
```

This binds approval to that body. A label or an edited issue alone is insufficient.
The issue is fetched again before execution; closed or changed issues are blocked.
Comments are not interpreted as shell commands or general instructions.

States: `queued → claimed → implementing → testing → review → done`.
`blocked`, `failed`, and `needs-approval` are explicit terminal states. Successful
automation stops at `review`. After inspecting the branch and evidence, an
allowlisted reviewer can comment:

```text
ak-review TASK_ID REVISION approve FULL_COMMIT_SHA
```

The worker records `done` without merging. Corrective feedback goes on the same
issue and Notion row. Increment the issue revision, change the failing task's
instructions/configuration or deploy a verified controller fix, and dispatch the
new body hash. Duplicate revisions never execute twice; failed candidates do not
retry merely because polling runs again. The controller hash is recorded in the
queued payload. Free-form comments never expand permissions.

## Authentication and containment

GitHub defaults to the existing Windows Git Credential Manager login. No new
permissions are requested. Its existing OAuth grant may be broader than this
repository; the broker pins all API operations to this repository. The startup
installer therefore requires a separate fine-grained token limited to this repo
with Contents and Issues read/write, set `github_auth` to `environment`, and use
the encrypted credential setup. Its GitHub and Git operations both use that token;
Git does not silently fall back to GCM in token mode. Never paste tokens into chat
or issues. The user must confirm the token's repository/permission selection in
GitHub; the broker cannot introspect every permission granted to a fine-grained PAT.

Notion defaults to the installed Codex connector and existing ChatGPT login.
The controller starts a private app-server over stdio and calls the installed
`mcpServer/tool/call` protocol directly. **No model turn runs in this connector
process.** Only `notion.fetch` and `notion.notion-update-page`, configured page IDs,
and six existing handoff properties are allowed. Unexpected authorization or
elicitation requests are denied. Configured unrelated MCP servers, plugins and
hooks are disabled for this process. Protocol incompatibility fails closed.
An optional REST adapter uses `AK_NOTION_TOKEN` when `notion_auth` is not
`codex-connector`; no token is required for the demonstrated configuration.

The separate generation-of-code process uses installed `codex exec`, existing
login, `--no-daemon`, `--ignore-user-config`, `--ignore-rules`, read-only sandbox,
no approval escalation, disabled app/shell/browser tools and web search, and a
structured output schema. A real canary test confirmed the sandbox rejects writes.
The edit broker validates exact paths, Windows reserved names, case-insensitive
duplicates, binary extensions, file sizes, symlinks, junctions and hardlinks.

All child processes start suspended, enter a private Windows Job Object, then
resume. Closing the job kills only its owned process tree. Timeouts, stop requests
and controller crashes cannot intentionally leave those children running. An
OS-held byte lock prevents overlapping local workers. This is a single-PC queue;
multi-host deployment requires a distributed lease and is not supported.

Purchases, credit spending, publication, destructive work and security changes
cannot be authorized by setting an issue flag. Those tasks stop for a separately
reviewed human action; there is no remote approve-all switch.

## Storage, recovery and reporting

Everything lives under `D:/AnimalKingdom3D/command-center`: SQLite/WAL state,
bounded rotating logs, per-revision evidence, and sparse shallow task clones.
At least 2 GiB disk headroom is required before cloning. Canonical dirty work is
never reset or staged by a task. Each new branch starts from fetched remote main;
existing task branches and non-fast-forward pushes are preserved and blocked.

Task evidence includes QA JSON/Markdown, structured proposals, event metadata and
the Notion handoff revision. GitHub receives a deduplicated structured report and
task branch/SHA. Notion updates the existing row and preserves external handoff
text before the controller's marked report section. Reports include tests,
Studio availability, asset validation status, blockers, next action, credit use,
confidence and reviewer decision. An unavailable Studio or untested model is
never recorded as passed. The local dashboard reads pet progress from the
canonical roster and explicitly distinguishes it from live Studio verification.

Network delivery uses a persistent outbox with exponential backoff, capped at
eight attempts. This retries delivery, not implementation. Older failed Notion
reports cannot overwrite a newer revision. `retry-delivery` is an explicit local
operation after connectivity/authentication is repaired. GitHub comments use
stable markers, allowing recovery after a crash between posting and recording it.

After an interrupted job, the worker marks it blocked and retains its clone and
evidence. Inspect them and submit a corrected higher revision. It never resumes
half-written model output blindly. No automated file deletion is performed by
this command center. The existing pet factory's cleanup policy is unchanged.

## Setup and operation

Python and Codex paths in `config.example.json` match this existing PC. No pip
packages or paid services are required. Run from the canonical repository:

```powershell
$python = 'D:\AnimalKingdom3D\tools\python\cpython-3.11.17-windows-x86_64-none\python.exe'
$config = 'D:\AnimalKingdom3D\command-center\config.json'
& $python -m unittest tools.command_center.test_bridge -v
& $python tools/command_center/bridge.py doctor --config $config
& $python tools/command_center/bridge.py status --config $config
```

`setup.ps1 -Action Prepare` creates/reuses the dedicated runtime, restricts its
ACL to the current user and SYSTEM, and preserves any existing configuration.
Review/approve this local security setup before running it.
`-Action Credentials` prompts securely and stores tokens using current-user
Windows DPAPI. The launcher removes token environment variables when it exits;
agent subprocess environments exclude broker tokens.

Foreground controls:

```powershell
& $python tools/command_center/bridge.py pause --config $config
& $python tools/command_center/bridge.py run --config $config
# In another terminal:
& $python tools/command_center/bridge.py resume --config $config
& $python tools/command_center/bridge.py stop --config $config
```

Pickup is paused by default. Pause finishes the current job; stop cancels its
owned command process tree and prevents further pickup. Network calls have bounded
timeouts. `once` performs one polling cycle and at most one job; it still respects
pause. The dashboard is `http://127.0.0.1:8766`; run `bridge.py dashboard-token
--config <config path>` in your own terminal to display its current-user token.
The stored token is DPAPI-encrypted. It stays in browser memory, never in the URL
or logs. Do not share its terminal output. Any legacy plaintext smoke-test token
is inactive and is not read by the worker.
API access requires that token, the exact loopback Host and same-origin controls
for writes. No LAN or public listener is created.

Only after the smoke test and explicit user opt-in:

```powershell
./tools/command_center/setup.ps1 -Action Prepare
./tools/command_center/setup.ps1 -Action Credentials
./tools/command_center/setup.ps1 -Action Install -ApproveStartup
Start-ScheduledTask -TaskName AnimalKingdomCommandCenter
```

The startup task is current-user, limited privilege, hidden, logon-triggered,
single-instance and restarts at most three times after crashes. It does not resume
pickup automatically. To remove it without deleting evidence:

```powershell
./tools/command_center/setup.ps1 -Action Uninstall
```

Polling is every **five minutes**, per the current Notion handoff. The existing
ChatGPT Production Watch remains hourly; this does not create another schedule.
Only material task/review/blocker changes become issue comments. Notion receives
the heartbeat and dashboard snapshot in the existing task's evidence field.

## Verified demonstration

[Issue #3](https://github.com/wardmaciah-web/Animal-Kingdom/issues/3) exercised
authenticated dispatch, claim, Notion handoff, real Codex implementation, exact
text/whitespace checks, branch push, and GitHub plus Notion feedback. Revision 3
produced commit `31c141be7d04eb9c28016393b0fa641b606a6d5b` on
`akcc/command-center-smoke/r3`. The only changed file is the harmless text fixture.
The two earlier attempts stopped before editing: connector tool-name mismatch,
then sparse-clone index initialization. Their diagnostics remain preserved; both
fixes were verified before a new revision was admitted.

Persistent startup is a separate opt-in; a successful foreground demonstration
does not mean an unattended service is installed. No game model, tree mapping,
release lock, production issue or Roblox publication was changed by the demo.

CLI behavior was checked against the installed 0.162.0 help/protocol schema and
[OpenAI's noninteractive documentation](https://learn.chatgpt.com/docs/non-interactive-mode),
[authentication documentation](https://learn.chatgpt.com/docs/auth), and
[configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference).
