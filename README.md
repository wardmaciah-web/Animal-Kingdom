# Animal Kingdom

**An open-source Roblox game and AI-assisted development project.**

Animal Kingdom is a work-in-progress Roblox experience centered on exploring biomes, discovering collectible animals, and building a persistent collection. The project also explores reproducible workflows for game development with Codex CLI, Roblox Studio, automated tests, and 3D asset tooling.

> **Status: Active development — not a verified release.** Gameplay, asset coverage, multiplayer, and persistence acceptance are still in progress. This repository may not contain every locally developed asset or the latest unpublished work.

## Vision

- Explore **12 planned biomes** with distinct environments and collectible animals.
- Collect pets through biome-specific interactions and reward pools.
- Manage a **Sanctuary**, followers, and a pet index.
- Grow through Garden expeditions, player plots, progression, and daily activities.
- Support persistent data and multiplayer without a player-to-player trading system.

## Engineering focus

Animal Kingdom is both a game and a practical testbed for AI-assisted development:

| Area | Development focus |
| --- | --- |
| Roblox gameplay | Luau systems for pet acquisition, inventory, followers, Sanctuary, progression, and persistence |
| Asset pipeline | Concept art, image-conditioned 3D generation, mesh optimization, private Roblox asset uploads, and canonical registry mapping |
| Verification | Focused automated checks, Roblox Studio tests, and evidence-based integration milestones |
| Coordination | Git-based checkpoints, issue tracking, and documented handoffs |

**Verification matters:** A model that spawns in a Studio test is not automatically verified for live inventory, save/rejoin, or multiplayer behavior.

## Current development priorities

1. Confirm the repository's public source and documented setup match the current development branch.
2. Complete end-to-end gameplay acceptance for Desert and Snow pets, including acquisition, inventory, Index, Sanctuary, save/rejoin, and multiplayer isolation.
3. Continue missing pet and biome production without duplicating existing approved assets.
4. Test progression, persistence, mobile usability, performance, and release readiness.

See [ROADMAP.md](ROADMAP.md) for status categories and remaining work.

## Getting started

This project targets **Roblox Studio** and uses **Luau**. To explore the source:

1. Clone the repository: `git clone https://github.com/wardmaciah-web/Animal-Kingdom.git`
2. Inspect the tracked project files and documentation before changing scripts.
3. Use Roblox Studio and any tooling described by the checked-out source to run local tests. **A one-command build or import procedure has not yet been publicly verified**, so this README does not claim one.
4. Never paste Roblox Open Cloud credentials, API keys, or private asset tokens into source files or issues.

For proposed changes, see [CONTRIBUTING.md](CONTRIBUTING.md). For defects, open a GitHub issue with reproducible steps and relevant sanitized logs.

## What contributors can work on

- Luau correctness, modularity, and tests
- Reliable multiplayer and DataStore behavior
- Developer tooling and documentation
- Asset validation, optimization, and idempotent pipeline steps
- Accessibility, input support, and performance

The long-term goal is to make useful development workflows reusable beyond this game. Not every game asset or third-party dependency is necessarily licensed for redistribution; verify provenance and permissions before contributing or reusing assets.

## Transparency

This project uses AI coding assistance. Changes should still be reviewed, tested, and attributed appropriately. Progress claims must distinguish **planned**, **implemented**, **locally tested**, and **fully accepted** work.

## License

The repository's covered source code is licensed under the [MIT License](LICENSE). This does **not** automatically relicense third-party assets, external models, Roblox platform materials, or content not owned by the project maintainer.
