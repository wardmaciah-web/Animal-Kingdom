# Animal Kingdom development roadmap

This roadmap describes **targets and verification gates**, not a promise that every feature is complete. Check issues, source, and recent test evidence for the current implementation state.

## Planned scope

- 12 distinct biomes with collectible pets and themed environments
- Canonical pet definitions, rarity, reward pools, and progression
- Pet Index, inventory, followers, and Sanctuary
- Garden expeditions, player plots, economy, and daily activities
- Persistent save/load and multiplayer-safe ownership
- Mobile-friendly UI, performance optimization, and release testing

## Current priority areas

| Workstream | State | Acceptance needed |
| --- | --- | --- |
| Desert and Snow pet assets | Previously reported as locally Studio-tested | Confirm current branch; verify real gameplay acquisition and persistence |
| Biome tree bindings | Previously reported as locally bound | Test server-awarded rewards in normal gameplay |
| Pet inventory and Index | In verification | Acquisition, equip/unequip, discovery, and rejoin |
| Sanctuary | In verification | Placement, retrieval, ownership, and persistence |
| Multiplayer | Not fully accepted | Multi-client isolation and exploit-resistant server authority |
| Remaining biomes and pets | Ongoing | Canonical coverage, optimized assets, and gameplay integration |
| Release readiness | Not accepted | Regression, mobile, performance, save/rejoin, and multiplayer tests |

## Evidence standard

A feature should be labeled:

- **Planned:** requirement documented but not implemented.
- **Implemented:** code or asset exists, but end-to-end behavior is not confirmed.
- **Locally tested:** targeted test passed in a controlled environment.
- **Accepted:** relevant gameplay, persistence, multiplayer, and regression criteria passed.

Historical local test results should not be presented as current public-branch verification without checking the matching source revision.

## Next maintainer actions

1. Document the public checkout's exact build/test workflow.
2. Publish sanitized test evidence and close verified gaps.
3. Prioritize reusable tooling with minimal platform-specific assumptions.
4. Keep the roadmap aligned with completed GitHub issues and merged pull requests.
