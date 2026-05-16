# Development Loop

This document is the runbook for automated and human-assisted development.
Keep it short, current, and stricter than the backlog.

## Read Order

Start each substantial run with:

1. `AGENTS.md`
2. `README.md`
3. `docs/current_status.md`
4. `docs/roadmap.md`
5. `docs/product_brief.md`

Run Hazakura Habitat before choosing commands for code, dependencies, Git,
release, or automation work. Read its `agent_context.md` first, and consult
`command_policy.md` before risky or mutating commands.

## Current Lane

The project is in v0 hardening for a local macOS LLM server manager.

Favor work that makes the existing `llama-server` control loop more reliable:

- configuration validation
- process lifecycle behavior
- launch command preview correctness
- local endpoint copy and display
- in-memory log handling
- app launch/build reliability

Do not expand into chat, model download, RAG, proxy behavior, remote exposure,
or bundled inference.

## Automation Rules

Each automated run should choose at most one coherent slice that can be
implemented, verified, and reported in the same run.

Saved Codex automation:

- name: Hazakura Lantern development loop
- id: `hazakura-llm-manager`
- cadence: daily at 22:45 in the user's local timezone
- environment: local execution in this project directory

Preferred order:

1. Fix a failing test or build.
2. Close a small correctness gap in the v0 runtime/control loop.
3. Add focused tests for an existing boundary.
4. Tighten docs when they would otherwise steer the next run incorrectly.
5. End as a verified no-op when no safe slice is justified.

Avoid broad refactors, dependency changes, generated artifacts, UI restyling, or
new feature areas unless the current status and roadmap both support them.

## Verification

Use the project defaults:

```bash
swift test
swift build --disable-sandbox
```

For docs-only work, also run:

```bash
git diff --check
```

`swift build --disable-sandbox` is the preferred build command in this Codex
environment because SwiftPM manifest sandboxing can fail even when compilation
is otherwise healthy.

## Git And Output Hygiene

This directory may be used before Git has been initialized. If it is not a Git
repository, do not run `git init`, add remotes, or pretend commit/push happened.
Report the work as local files changed only.

If the project later becomes a Git repository, commit only the files changed in
the current run, and do not push unless a remote already exists and the
automation prompt explicitly delegates that action.

Do not commit `.build/`, `dist/`, temporary Habitat reports, app bundles, logs,
or local machine paths unless a future release process intentionally defines
them as artifacts.

## Nenrin

Do not create Nenrin records for ordinary implementation, formatting, or small
copy changes.

Create or update a record only when this project changes durable future-agent
behavior: command policy, verification policy, release gates, recurring
automation guidance, or a repeated blocker pattern.
