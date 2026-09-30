# Animal Kingdom connected development workflow

## Purpose

Animal Kingdom uses one task record from idea through QA. The tools are stages of one workflow, not separate project trackers.

`ChatGPT → 3DAI Studio (when needed) → Codex → GitHub checkpoint → Roblox Studio/Rojo → QA/Fix → Done`

Notion **Animal Kingdom HQ** is the command center. GitHub is source-control history. `Real_Animal_K` is the canonical local codebase. Roblox Studio is the final live-game verification surface.

## One-record rule

A feature should keep the same Development Pipeline record as it moves through stages. Do not create a second record just because work moved from ChatGPT to 3DAI, Codex, GitHub, or Studio.

Important fields:
- `Task`: stable task name.
- `Stage`: current workflow stage.
- `Codex Handoff`: implementation summary/constraints.
- `GitHub / Commit`: full SHA for the exact code being tested.
- `Studio Evidence`: automated evidence plus later Studio evidence.
- `QA Result`: Not Tested / Partial / Pass / Fail / Blocked.
- `Next Action`: next concrete action.

## Stage flow

Typical no-3D feature:
`Idea → GPT Design → Ready for Codex → Codex Working → Studio Testing → Done`

Feature requiring assets:
`Idea → GPT Design → 3D Needed → 3DAI Studio → Ready for Codex → Codex Working → Studio Testing → Done`

Failed QA loops back:
`Studio Testing → Needs Fix → Codex Working → Studio Testing`

Use `Blocked` only when progress genuinely requires missing input/access/content.

## Codex start gate

Codex should locate the matching Notion task when the Notion source is enabled, mark it `Codex Working`, then inspect the current source needed for the request. It should not read every historical report before every edit. `src/` is live source; `documentations/` is evidence/history unless a task specifically references a current report.

## Git checkpoint gate

A Git checkpoint is created when the implementation is coherent enough to test. Before committing:
- affected tests/checks have been run where available;
- unrelated local changes are excluded;
- no secrets/local auth files are added;
- no historical backup trees are reintroduced;
- the commit corresponds to one understandable task/handoff.

After committing, push to `origin/main` without force. Record the full SHA in the matching Notion row.

## Studio QA gate

Source/unit/static checks are not a substitute for Roblox Studio when the feature changes world behavior, visuals, UI, input, physics, replication, assets, or persistence.

Before `Done`, test the affected behavior in Studio and record enough evidence to reproduce the result. For high-risk changes, include obvious regression checks such as ownership/UID integrity, persistence, normal tree rewards, released-biome gating, UI duplication, mobile/controller behavior when relevant, and Output errors.

If Studio is not available, leave the task at `Studio Testing` with `QA Result = Partial` or `Not Tested` and state exactly what remains.

## 3DAI handoff

3DAI Studio currently hands off through a real asset/file/animation result. Store the asset identifier/file reference on the same task. Codex must not invent a substitute asset to bypass this stage. Once the real asset exists, move the same task to `Ready for Codex`.

## Safety rules

- No duplicate tabs/systems when an existing one should be extended.
- No fabricated pets or unreleased-content bypasses.
- Preserve `ContentReady` gating.
- Keep rewards, currencies, ownership, UIDs, rarity, weight, unlocks, and persistence server-authoritative.
- Git push is not Roblox publish. Publishing the Roblox experience requires explicit user intent.
- Never force-push or discard unrelated user changes.

## Handoff output

Run:

```bash
tools/workflow/ak_handoff.sh "Task name" "Partial" "Exact Studio checks remaining"
```

Use that output to update the same Notion task and to tell the user what is ready for Studio.
