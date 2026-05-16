# Agent Guidance

This project is a macOS SwiftUI app for managing local LLM server processes.
Keep changes small and verify them with SwiftPM before expanding scope.

## Habitat Usage

Run Hazakura Habitat before substantial coding, dependency, release, Git/GitHub,
or command-selection work.

Prefer a temporary Habitat output directory unless `habitat-report/` is
intentionally ignored by the repo:

```bash
HABITAT_SCAN=/Users/keisetsu/Projects/hazakura_Habitat/.build/debug/habitat-scan \
  /Users/keisetsu/.codex/skills/hazakura-habitat/scripts/run_habitat_scan.sh . \
  "$(mktemp -d "${TMPDIR:-/tmp}/hazakura-llm-manager-habitat.XXXXXX")"
```

Read `agent_context.md` first. Consult `command_policy.md` before dependency,
lockfile, Git/GitHub, archive, delete, copy, move, sync, credential-adjacent, or
environment-mutating commands.

For the current project shape, Habitat should lead agents toward:

- `swift test`
- `swift build`
- read-only project inspection with `rg`

## Development Loop

For automated or recurring development, read:

- `docs/development_loop.md`
- `docs/current_status.md`
- `docs/roadmap.md`
- `docs/product_brief.md`

Choose at most one coherent slice per run. A verified no-op is better than a
speculative feature expansion.

## Nenrin Usage

Use Nenrin as a pruning and judgment aid, not as a work generator.

Do not create a Nenrin record for ordinary app implementation, formatting,
small copy changes, or one-off task notes.

Create or update a Nenrin-facing record only when a change durably affects
future agent behavior, such as:

- this file
- project run or verification policy
- release or review gates
- recurring automation guidance
- a repeated blocker pattern that should change future command decisions

If there is no durable behavior signal, report the no-op explicitly. That is a
successful outcome.

## Current Verification

Use:

```bash
swift test
swift build --disable-sandbox
```

`--disable-sandbox` is used because this Codex environment can reject SwiftPM's
manifest sandbox while normal project compilation still succeeds.
