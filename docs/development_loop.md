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
6. `docs/troubleshooting.md`

Run Hazakura Habitat before choosing commands for code, dependencies, Git,
release, or automation work. Read its `agent_context.md` first, and consult
`command_policy.md` before risky or mutating commands.

## Current Lane

The project has a source-only v0.2 alpha checkpoint for a local macOS LLM
server manager. The next source-work lane is v0.3 adapter boundary clarity,
while the app-bundle launch smoke remains a packaged-release blocker.

Favor work that keeps the existing `llama-server` control loop explicit while
making future adapter boundaries smaller and easier to test:

- launch command preview correctness
- adapter-owned command construction
- adapter-owned endpoint and health contracts
- validation and error mapping
- source-only profile compatibility checks
- app launch/build reliability when there is a fresh hypothesis

Do not expand into chat, model download, RAG, proxy behavior, remote exposure,
or bundled inference.

Recent review feedback that suggests endpoint auto-polling, runtime version
display, multiple-profile management, or broad UI polish should be treated as
future backlog unless it can be narrowed to one testable adapter-boundary,
restart-state, copy-flow, empty-state, or setup-hint ambiguity. Prefer dropping
the suggestion over reopening a closed lane.

The recurring automation may move from v0 to v0.1, v0.2, and v0.3 without a new
human prompt when `docs/current_status.md` and `docs/roadmap.md` agree that the
previous lane is sufficiently closed. Do not keep re-running the same launch
smoke diagnostics after the blocker is already documented. If a blocker appears
environment-specific and the core SwiftPM tests still pass, carry it as a known
risk and choose the next safe lane item that does not depend on that blocker.

Lane handoff rules:

- v0 -> v0.1: allowed when command construction, process control, endpoint
  display, configuration persistence, and SwiftPM verification are stable, even
  if the documented Launch Services helper blocker remains unresolved.
- v0.1 -> v0.2: allowed when daily-use confidence is good enough that profiles
  are the next smallest source of value: clearer runtime state, local health or
  client smoke evidence, copy flows, and common failure messages are covered by
  tests or docs.
- v0.2 work must stay on local profile contract and portability. Do not use the
  handoff as permission for model download, runtime install/update, chat,
  proxy, LAN exposure, or adapter breadth.
- v0.2 -> v0.3: allowed when local profile contract, persistence, and
  import/export helpers are covered well enough that the next risk is adapter
  boundary clarity. v0.3 work should tighten protocols, tests, and docs before
  adding another runtime adapter.

Release posture:

- `v0.2.0-alpha.1` is acceptable as a source-only checkpoint when SwiftPM
  verification passes and docs clearly state that no packaged `.app` artifact is
  attached.
- Do not cut a user-facing app-bundle, zip, dmg, signing, or notarization
  release until the app-bundle launch smoke is verified on a normal macOS
  environment.

## Automation Rules

Each automated run should choose at most one coherent slice that can be
implemented, verified, and reported in the same run.

Saved Codex automation:

- name: Hazakura Lantern development loop
- id: `hazakura-llm-manager`
- cadence: hourly at minute 45 in the user's local timezone
- environment: local execution in this project directory

Hourly posture:

- Start with `git status --short --branch`, then read the documents in the
  order above.
- Choose at most one small slice. Do not stop after inspection only when the
  tree is clean, verification is available, and `docs/current_status.md` lists
  a small next slice.
- Prefer implementation, tests, docs, commit, and push only when the slice is
  clear and verification passes.
- Keep hourly runs quiet, but progress-biased. A verified no-op is valid only
  after checking current-status candidates and finding no safe implementation,
  test, or automation-doc slice for this run.

Preferred order:

1. Fix a failing test or build.
2. Close a small correctness gap in the current roadmap lane.
3. If the current lane is blocked only by a documented environment-specific
   smoke issue, advance to the next lane's smallest safe item.
4. Add focused tests for an existing boundary.
5. Tighten docs when they would otherwise steer the next run incorrectly.
6. End as a verified no-op only when no safe slice is justified after the
   checks above.

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

Use `docs/troubleshooting.md` to classify setup, endpoint health, and
app-bundle launch-smoke failures before changing runtime scope.

When an automation run launches the app for smoke verification, it must also
close the app before finishing. Prefer `./script/build_and_run.sh --verify`
because that mode owns launch cleanup. If the app is already open or a smoke
path is interrupted, run `./script/build_and_run.sh --stop` before final
reporting. Treat Apple Events / `osascript` as optional only; the reliable local
cleanup path is the project script stopping the `HazakuraLLMManager` process.

## Habitat And Nenrin

Use Habitat when the run needs command judgment: substantial code changes,
dependency or lockfile work, Git/GitHub mutation, release work, automation
changes, unfamiliar command selection, or secret-adjacent paths. Use a temporary
output directory, read `agent_context.md` first, and consult `command_policy.md`
before risky or mutating commands.

For a tiny docs check, read-only inspection, or a no-op run where command choice
is already clear, Habitat is optional. Do not commit generated Habitat reports.

Use Nenrin as a pruning and judgment aid, not as an hourly work log.

Run:

```bash
nenrin brief
```

before release, lane-handoff, recurring automation, or workflow-scope decisions
where prior durable judgment could affect the next step.

After agent-facing docs or automation guidance changes, run:

```bash
nenrin diff
nenrin debt
```

Use the result to decide whether a record, observation, review, or explicit
no-op is warranted. Do not create a Nenrin record for ordinary implementation,
formatting, small copy changes, one-off notes, or no-op runs.

Create or update a Nenrin-facing record only when this project changes durable
future-agent behavior: command policy, verification policy, release gates,
recurring automation guidance, or a repeated blocker pattern.

## Git And Output Hygiene

This project is expected to be a Git repository tracking `origin/main`. If Git
metadata is unavailable, do not reinitialize the repository or pretend
commit/push happened. Report the blocker clearly.

Commit only the files changed in the current run, and push only when the
automation prompt or user request explicitly delegates that action.

Do not commit `.build/`, `dist/`, temporary Habitat reports, app bundles, logs,
or local machine paths unless a future release process intentionally defines
them as artifacts.
