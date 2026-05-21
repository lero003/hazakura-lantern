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
7. `docs/automation_smoke_backlog.md` when choosing UI, smoke, localization,
   menu bar, setup-flow, update-readiness, or pre-release polish work
8. `docs/post_public_operations.md` when a run touches public issues, external
   review feedback, post-public docs hygiene, or automation scope
9. `docs/public_opening_preflight.md` only when a run touches pre-open
   checklist history, release, GitHub visibility, GitHub settings, tags, or
   release assets

Run Hazakura Habitat before choosing commands for code, dependencies, Git,
release, or automation work. Read its `agent_context.md` first, and consult
`command_policy.md` before risky or mutating commands.

## Current Automation Focus

The project has a public source-only `v0.9.0-alpha.1` checkpoint for
release-quality UI, menu bar, toolbar, localization, setup guidance, and
non-mutating update-readiness work. Treat exact v0.x numbers as release
history, not as the next work selector.

The default question for each automation run is:

> Does this make Lantern closer to release-quality daily use without expanding
> scope?

Prefer unfinished release-quality work over advancing a version lane. The
currently useful unfinished gates are:

- restore or externally verify the app-bundle helper launch path, then complete
  normal desktop/manual launch and clean quit smoke
- app-language switching verification for high-traffic surfaces such as menu
  bar, toolbar, sidebar, Settings, Setup Guide, Endpoint, and HelpTooltip copy
- menu bar daily-use verification for status, lifecycle, copy, and Open Window
  behavior
- a product decision on whether the toolbar remains, shrinks, or is removed
  after the menu bar becomes the resident control surface
- Setup Guide inspector review against the normal Configuration flow
- one manual UI smoke pass covering main window, Setup Guide, menu bar,
  toolbar, logs, and clean quit
- concrete rough edges from `docs/automation_smoke_backlog.md` that can be
  fixed or exposed in one verified run
- docs or issue-triage clarity only when current guidance would steer the next
  run incorrectly

Treat v0.3 adapter-boundary, v0.4 reliability, v0.5 post-public triage, v0.6
preset, v0.7 capability, v0.8 toolbar/navigation, and v0.9 update-readiness
notes as background context. Reopen one only when a concrete, release-quality
risk is visible and testable.

Do not expand into chat, model download, RAG, proxy behavior, remote exposure,
bundled inference, second-runtime work, or real runtime installation/update.

Recent review feedback that suggests custom command profiles, Ollama, endpoint
auto-polling, multiple-profile management, or broad UI polish should be treated
as future backlog unless it can be narrowed to one testable `llama-server`
reliability, restart-state, copy-flow, empty-state, health wording,
profile-warning, setup-hint, preset, read-only runtime capability,
menu-bar/toolbar, or update-readiness ambiguity.

The 2026-05-21 Gemini v1 polish review has been folded into
`docs/automation_smoke_backlog.md`. Use it as bounded input for localization
coverage, HelpTooltip copy, launch-helper hypotheses, toolbar evidence, and
log-policy decisions; do not treat it as approval for broad Core diagnostic
localization, default signing/notarization work, or log persistence.

For pre-release rough-edge discovery, use `docs/automation_smoke_backlog.md`.
Automation may fix one concrete UI, localization, smoke, setup-flow,
menu-bar/toolbar, profile-warning, health/copy, packaging-prep, or
non-mutating update-readiness issue from that document per run when the issue is
observable and verifiable.

Historical lane handoff rules:

Use these only to interpret old roadmap notes. They are not the active work
queue, and automation should not chase them just because a version number is
next.

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
- v0.3 -> v0.4: allowed when adapter ownership is documented and tested well
  enough that `docs/current_status.md` names no concrete unresolved adapter
  ambiguity. The next lane is `llama-server` reliability and daily-use polish,
  not runtime breadth.
- v0.4 -> v0.5: allowed when the common `llama-server` launch, health,
  endpoint, copy-flow, restart-state, setup-hint, and profile-warning paths are
  quiet enough that public feedback triage is the next smallest risk. This
  handoff may happen automatically; v0.4 does not need to be exhaustively
  completed when no concrete reliability slice is visible.
- v0.5 -> v0.6: allowed when public issue triage rules and automation
  discipline are documented. v0.6 stays on `llama-server` model-family presets
  and option compatibility before runtime breadth.
- v0.6 -> v0.7: allowed when preset vocabulary and command-visible application
  are documented or tested. v0.7 may add local, timeout-bounded, read-only
  runtime/version capability checks to warn about preset compatibility.
- v0.7 -> v0.8: allowed when runtime capability checks are useful enough that
  the next smallest risk is making existing actions available from a native
  menu bar or toolbar. v0.8 is menu bar/toolbar/navigation, not runtime breadth.
- v0.8 -> v0.9: allowed when toolbar actions mirror existing behavior.
  v0.9 is non-mutating `llama-server` update readiness: source, version,
  capability, and dry-run explanation.
- v0.9 -> v1.0: allowed when update readiness can support a guarded,
  user-confirmed update workflow. v1.0 may implement update planning and
  execution UI, but automation must not execute real package-manager, git, or
  binary replacement updates without explicit human confirmation for that run.

Release posture:

- `v0.9.0-alpha.1` is acceptable as a source-only checkpoint when SwiftPM
  verification passes and docs clearly state that no packaged `.app` artifact is
  attached.
- Do not cut a user-facing app-bundle, zip, dmg, signing, or notarization
  release until a normal desktop/manual launch and clean-quit pass is recorded.
  The 2026-05-21 helper smoke has mixed evidence and is not packaged release
  proof.
- Do not cut a user-facing packaged release until the menu bar, toolbar, and
  Setup Guide release blockers in `docs/current_status.md` and `docs/roadmap.md`
  are resolved or explicitly deferred from the release scope.

Post-public posture:

- Use `docs/post_public_operations.md` for issue triage, external review notes,
  automation-safe work, and human approval gates. Formal post-public triage is
  the v0.5 lane, but these guardrails apply immediately.
- Keep `docs/public_opening_preflight.md` as the pre-open and release-handoff
  checklist, not as the default post-public work queue.
- Do not change GitHub repository visibility, branch protection, collaborators,
  secrets, webhooks, Actions settings, tags, GitHub Releases, release assets,
  repository packages, or public issue state without an explicit human handoff
  for that exact action.

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
- Choose at most one small release-quality slice.
- Prefer implementation, tests, docs, commit, and push only when the slice is
  clear and verification passes.
- Keep hourly runs quiet, but progress-biased. A verified no-op is valid when
  no unfinished release-quality gate or concrete rough edge is safely actionable
  in this run.

Preferred order:

1. Fix a failing test or build.
2. Close one unfinished release-quality gate from `docs/current_status.md`.
3. Use `docs/automation_smoke_backlog.md` to expose or fix one concrete
   pre-release rough edge that can be verified in the same run.
4. Add focused tests for observed `llama-server` launch, validation, health,
   endpoint, restart, copy-flow, or profile-warning behavior.
5. Tighten docs when they would otherwise steer the next run incorrectly or
   confuse a `llama-server` setup path.
6. Classify public feedback or review notes with
   `docs/post_public_operations.md`, then make one safe local change only if the
   classification identifies a source-quality issue.
7. Refine presets, runtime capability advisories, or update-readiness wording
   only when it reduces a concrete release-quality risk and remains
   non-mutating.
8. End as a verified no-op only when no safe release-quality, smoke-backlog,
   feedback-triage, test, or automation-doc slice is justified.

Avoid broad refactors, dependency changes, generated artifacts, UI restyling, or
new feature areas unless the current status and roadmap both support them.

Human approval is required before automation starts a new runtime adapter,
custom command profile implementation, profile schema version change, packaged
artifact, GitHub settings or release mutation, public issue mutation, automation
cadence change, dependency or lockfile mutation, endpoint auto-polling,
real runtime install/update execution, model download,
automatic benchmark/optimization, multiple-profile management, launch-at-login,
or automatic restart policy.

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
