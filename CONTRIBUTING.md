# Contributing to Animal Kingdom

Thanks for your interest in improving Animal Kingdom. The project is under active development, and focused contributions are welcome.

## Before you begin

- Read the [README](README.md) and [roadmap](ROADMAP.md).
- Search existing issues to avoid duplicate work.
- For substantial gameplay or architecture changes, open an issue to discuss the scope before investing significant time.
- Do not publish the Roblox experience, change production DataStores, or upload assets to the maintainer's account.

## Making a change

1. Fork the repository and create a descriptive branch.
2. Make the smallest cohesive change that solves the issue.
3. Keep existing pet IDs, canonical registries, reward mappings, and persistence formats stable unless the change explicitly requires migration.
4. Add or update relevant tests and explain how you verified the change.
5. Open a pull request with a clear description, risks, and testing evidence.

## Pull request checklist

- [ ] Linked issue or clear rationale
- [ ] No unrelated refactors or generated-file churn
- [ ] Tests run and results reported (including limitations)
- [ ] No secrets, tokens, private user data, or production DataStore content
- [ ] Asset provenance and redistribution rights checked
- [ ] No claims of full gameplay acceptance based solely on isolated mock tests

## AI-assisted contributions

AI tools, including Codex, may be used. Contributors are responsible for reviewing generated code, validating behavior, and ensuring the contribution does not include unlicensed material or sensitive information. Disclose meaningful AI-assisted generation in the pull request description.

## Reporting bugs

Include the affected feature, expected and actual behavior, reproduction steps, environment, and sanitized logs. For multiplayer or persistence bugs, say whether the test was isolated, Studio-based, or an actual multi-client test.

## Licensing

By submitting a contribution, you agree to license your contribution under the repository's [MIT License](LICENSE). Do not submit third-party content without the necessary rights.
