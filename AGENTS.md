# Animal Kingdom Codex contract

This repository is the canonical source for the Roblox game **Animal Kingdom**. The canonical local project is `Real_Animal_K`; the canonical GitHub repository is `wardmaciah-web/Animal-Kingdom` on `main`.

## Source-of-truth order

For each task, use this order when information conflicts:
1. The user's current explicit request.
2. Current canonical source under `src/` and current project configuration.
3. The matching task in Notion **Animal Kingdom HQ → Development Pipeline** and its acceptance criteria.
4. Historical files under `documentations/` only as evidence/reference; do not treat snapshots, diffs, checkpoints, or old reports as live source.

Do not create a duplicate system, tab, task, or feature when an existing canonical one can be extended. Preserve `ContentReady` release gating. Never fabricate missing 3D pet/tree assets or placeholder content to make a feature appear complete.

## Notion workflow

When the Notion plugin/source is available in Codex, use it for the Animal Kingdom workflow without waiting for the user to repeat this instruction.

At task start:
- Find the matching row in **Animal Kingdom HQ → Development Pipeline**. Prefer an exact task-title match.
- Reuse that row; do not create a duplicate for the same work.
- Move `Stage` to `Codex Working` and keep the existing design/acceptance criteria intact.
- If no matching row exists and Notion write actions are available, create one from the user's request. Otherwise continue the code task and report that the Notion handoff is blocked.

At implementation handoff:
- Update the same row, not a new row.
- Record a concise implementation summary in `Codex Handoff`.
- Record the full Git commit SHA in `GitHub / Commit`.
- Record automated/test evidence in `Studio Evidence`.
- Set `Stage` to `Studio Testing` when code is ready for Roblox Studio verification.
- Set `QA Result` to `Not Tested` or `Partial` until real Studio verification is complete.
- Set `Next Action` to the exact Studio checks still required.

If implementation is blocked or a task-caused automated regression remains, set `Stage` to `Needs Fix` or `Blocked`, set the appropriate `QA Result`, and record the evidence/next action. Do not mark `Done` based only on source inspection or non-Studio tests when the change affects live Roblox behavior.

## Git/GitHub handoff

Before editing, inspect `git status --short`, current branch, and `origin`. Preserve unrelated user work.

When a task reaches a testable handoff:
- Run the relevant available checks/tests for the changed systems.
- Stage only files belonging to this task; do not use broad staging if unrelated changes exist.
- Commit with a concise Animal Kingdom task message.
- Push the commit to `origin/main` unless the user explicitly says not to push.
- Never force-push, rewrite published history, run destructive cleanup, or discard unrelated changes.
- If the working tree cannot be safely isolated, do not make a mixed commit; report the blocker.
- Run `tools/workflow/ak_handoff.sh "<task>" "<qa result>" "<next action>"` after the commit and use its output for the Notion handoff.

Git commits are development checkpoints. They do **not** publish the Roblox experience. Never publish the Roblox game unless the user explicitly requests publication.

## Roblox/QA rules

### Autonomous pet-production handoff loop

Before each new pet-production batch and after every failed generation, fetch
the existing Notion Development Pipeline task and the matching biome task. Read
their current Codex Handoff and Next Action fields; record the page IDs/revisions
and applicable decisions in the batch evidence. Apply relevant verified fixes
against current canonical source, run their required tests and update the same
Notion rows and GitHub checkpoint. Historical instructions cannot override the
current user request or repeat completed work. If Notion cannot be checked, record
the blocked handoff instead of claiming an hourly review happened. These checks
are performed by the connected Codex agent; the local Python controller does not
have Notion credentials or run the external hourly monitor.

Continue only through real asset, resource and QA gates. Do not overwrite approved
assets, bypass biome locks or publish the experience. Request approval before an
action needs new permissions, purchases or unsafe system changes; continue any
independent authorized work. A memory-failed candidate is not automatically retried.

Use Rojo/current source architecture instead of editing historical place snapshots as source. Keep server-authoritative gameplay server-authoritative, especially rewards, ownership, UIDs, currencies, rarity, weight, unlocks, and persistence.

For gameplay changes, verify the affected loop and obvious regressions. Use existing tests/audits where relevant. Roblox Studio remains the final authority for live world/UI/interaction behavior. If Studio verification is unavailable, say exactly what remains unverified and leave the Notion task in `Studio Testing`/`Partial` rather than claiming a full pass.

For 3D-dependent work: if a required real asset is missing, move/leave the task at `3D Needed`/`3DAI Studio` and identify the missing asset. Do not generate substitute geometry in code unless the user explicitly asks for a code-built primitive/UI effect.

## Completion report

Finish Codex tasks with a compact handoff containing: task name, files changed, tests/checks run, commit SHA, push result, Notion stage/update result, and exact Studio checks remaining. If any integration (Notion, GitHub, Rojo, Studio) is unavailable, name the blocked link instead of pretending the workflow completed.
