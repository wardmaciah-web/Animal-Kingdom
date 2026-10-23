# Animal Kingdom OmniRoute recovery — 2026-10-22

Verified local execution in `E:\AnimalKingdom\Agents\Worktrees\Coding`: Node 24.19.0, npm 11.17.0, Codex CLI 0.163.0 and OmniRoute 3.8.51. The previous Windows sandbox initialization failure did not recur. This recovers supervised free-model assistance; it does not activate the workforce scheduler or change this already-running Codex conversation's provider.

## Verified route and billing

The installed OpenRouter account's live `/api/v1/key` metadata reported `is_free_tier=true`, credit limit `0`, remaining limit `0`, and usage `0`. Its live catalog offered 17 explicit `:free` model entries with zero pricing. Only `cohere/north-mini-code:free` was selected and tested. NVIDIA, Cerebras and Groq have existing saved connections, but their account billing tiers were not established, so they are excluded. Catalog presence alone is not a successful inference test.

The isolated listener is `http://127.0.0.1:20129/v1`. It contains one provider connection and one restricted local key, allowing only `openrouter/cohere/north-mini-code:free`. No auto routes, combos, global fallback or domain fallback chains are configured. Background services, credential health checks, automatic recovery, cloud sync, MCP and A2A are disabled. `OMNIROUTE_EMERGENCY_FALLBACK=false` and `OMNIROUTE_AUTO_FREE_FALLBACK_TO_FULL_POOL=false` are explicit.

`payload-rules.json` uses OmniRoute's existing native payload engine. It pins the provider to Cohere, sets all supported maximum-price dimensions to zero, disables provider fallback, removes model fallback arrays and paid plugin/preset/search fields, disables reasoning and caps each upstream output at 2,048 tokens. The rules path is set by the private `start.ps1`; never launch this isolated database without that script. The local key additionally limits requests to 5/minute and 30/day. Free-service quotas may stop execution; there is no paid escape route.

Actual evidence (UTC 2026-10-23, local date October 22):

- Unauthenticated `/v1/models`: HTTP 401. Authenticated catalog: exactly the allowed free model.
- Unknown model and `auto`: HTTP 403 before provider inference.
- Initial 128-token smoke response had no content because reasoning exhausted its budget; it was not counted as a successful coding result.
- Corrected chat request returned a Luau addition function; execution passed positive, negative and zero cases.
- Deliberately unavailable upstream provider returned HTTP 404 instead of switching models. OmniRoute's resulting cooldown also stopped a Codex attempt with HTTP 429; it was not bypassed.
- Corrected Codex CLI request: `provider: ak_free`, pinned model, exact response `AK_FREE_CODEX_VERIFIED`; router log confirms `/v1/responses` HTTP 200, 2,248 input and 6 output tokens.
- Supervised game review: generation `gen-1792716829-GF6XtIIdQMhZ3JhqKBoF`, provider **Cohere**, 568 input / 502 output tokens. Captured raw upstream response reports `usage.cost=0`, `is_byok=false`, and every `upstream_inference_*_cost=0`.
- OpenRouter generation lookup returned 404; billing verification instead uses its live account metadata, current model pricing and the captured raw upstream response, not an inferred OmniRoute cost estimate.
- Offline tests exercise the installed native rule engine with attempted price overrides, fallback arrays and paid add-ons. These strings never go to the network.

One initial CLI probe used `--ignore-user-config`, which also skipped the profile in this installed version. It used the existing ChatGPT authentication (no OpenAI API key): 10,232 input tokens, including 7,296 cached, plus 9 output tokens. That response was excluded from routing evidence. The supplied launcher always explicitly selects `ak_free`, so a missing provider configuration fails instead of selecting normal Codex. Do not add `--ignore-user-config`.

## Use and preservation

The original `C:\Users\Kenny\.codex\config.toml`, original OmniRoute database and original `.env` all passed SHA-256 preservation checks. The original Codex config hash is `282e32795e69170329b28828161847870bf86932f5f5d18fcd2984f0eb5e6280`. A private original copy is retained at `.tools\omniroute-recovery\codex-config.original.toml`.

Only the opt-in `C:\Users\Kenny\.codex\ak-free.config.toml` was added. Credentials, the cloned runtime, backup, logs, process identity and raw evidence remain under the ignored `.tools\omniroute-recovery` directory with current-user/SYSTEM access. No credentials belong in Git. `codex-profile.example.toml` is a credential-free reference, not an automatic installer.

From a checkout containing this handoff, run:

```powershell
powershell -NoProfile -File tools\workflow\omniroute-free\Invoke-Review.ps1 -Prompt 'Review this Luau snippet: ...'
```

The helper verifies the installed profile, payload rules, process creation time and loopback listener before loading the local key into the child process environment. It performs one supervised read-only Codex turn. It restores the caller's environment afterward. The original default Codex provider remains unchanged. This passive router has no automatic startup registration; if the recorded process stops, the helper refuses inference until its startup/identity is reverified. No autonomous worker was enabled.

## Exact rollback

```powershell
powershell -NoProfile -File 'E:\AnimalKingdom\Agents\Worktrees\Coding\.tools\omniroute-recovery\rollback.ps1'
```

The rollback verifies the recorded PID, executable, arguments and creation time, stops only that router and removes only the unchanged opt-in `ak-free.config.toml`. It leaves the original Codex configuration and original OmniRoute installation/database/credentials untouched. Evidence and backups remain. If the process identity or profile has since changed, it refuses the destructive step. Ordinary `codex` already uses the original provider; no original config restore is needed.

## Game continuation and remaining QA

The verified free route reviewed canonical `NormalTreeOdds.lua` in the Coding workspace. Its suggestion to remove zero-weight rows was rejected: those rows support Index display, and existing weighted-selection tests explicitly return no selection for an empty eligible pool. Model output remains review advice, not an instruction to edit or execute.

`python tests/run_hot_tree_tests.py --luau .tools/luau-0.743/luau.exe` passed **714 checks** at Coding HEAD `2ead9b5` (existing game work, not part of this commit). The content catalog suite could not start because its historical `documentations/production-polish-20260922/before/src/ReplicatedStorage/SharedSource/Datas/PetDatabase.lua` fixture is absent. This pre-existing fixture dependency was not replaced with fabricated data.

No game source, assets, release gates, production credentials or Roblox publication changed. In isolated Studio profiles, the existing Hot Tree task still requires every Meadow/Forest modifier's Legendary+ same-family reward, Heavy Mooncap >=3 kg within species bounds, rejection of ineligible families, real asset readiness and ContentReady gates, one charge/award, normal/Lucky-tree regressions, multiplayer and save/rejoin. Preserve the manual 70 kg reference before any resync. Studio was not invoked for this infrastructure recovery.

The Coding branch diverged from current `origin/main`; this handoff was created in a separate worktree based on current main so no unrelated local commits are pushed.

Primary references: [OpenRouter free variants](https://openrouter.ai/docs/guides/routing/model-variants/free), [provider routing and maximum prices](https://openrouter.ai/docs/guides/routing/provider-selection), [Codex provider/profile configuration](https://learn.chatgpt.com/docs/config-file/config-advanced).
