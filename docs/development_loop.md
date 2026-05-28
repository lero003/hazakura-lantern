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
10. `docs/dmg-preview-checklist.md` only when a run touches warning-expected
    DMG preview preparation or binary artifact publication

Run Hazakura Habitat before choosing commands for code, dependencies, Git,
release, or automation work. Read its `agent_context.md` first, and consult
`command_policy.md` before risky or mutating commands.

## Current Automation Focus

The project has a public source-only `v1.7.0` checkpoint for personal/local
use. It keeps the existing `llama-server` control boundary, includes the
bounded GGUF Acquisition lane, and does not include packaged `.app`, zip, dmg,
signing, notarization, checksum, or binary distribution artifacts. Treat exact
version numbers as release history, not as the next work selector.

Current human direction: the automated development loop is resumed as a
stability-only quality loop after the `v1.7.0` source-only checkpoint and the
warning-expected DMG preview. It should fix one quality or smoke-observed rough
edge at a time. It is acceptable to spend runs on smoke verification and fix
the first concrete rough edge found, as long as the fix stays small and
verifiable. It is also acceptable to make no code change when checks and smoke
evidence do not point to a justified slice; report that verified no-op plainly
instead of inventing work.
Packaged app release work remains a separate future handoff. Automation should
not create packaged artifacts, mutate runtime installs, change GitHub settings,
or decide packaged-release readiness by itself.

The default question for each automation run is:

> Does this make Lantern closer to release-quality daily use without expanding
> scope?

Prefer failing quality checks, runtime usability polish, GGUF Acquisition
hardening, and post-checkpoint smoke evidence over packaged-release work. The
currently useful unfinished gates are:

- fix failing `swift test`, `swift build --disable-sandbox`, localization lint,
  or `git diff --check` results before choosing polish
- after v1.7: use smoke runs, fake-client
  tests, and manual evidence to fix one concrete rough edge at a time before
  considering another source checkpoint
- when a smoke or inspection run finds no concrete release-quality rough edge,
  end as a verified no-op rather than broadening into speculative cleanup
- harden GGUF Acquisition only as acquisition quality: public API parsing,
  `.gguf` file listing, destination-path safety, partial resume/cancel/failure
  behavior, localized UI copy, and completion-to-model-path handoff
- make one small code-quality improvement inside the current `llama-server`
  boundary when it supports the smoke lane and is covered by the same run's
  verification
- keep the 2026-05-25 normal desktop smoke fresh after UI/lifecycle changes;
  it covers launch, Setup Guide, Dashboard health, Smoke Console, toolbar
  profile panel presentation, menu-bar Stop, and clean quit
- app-language switching verification for remaining high-traffic surfaces such
  as menu bar, Settings, Endpoint advanced details, and HelpTooltip copy
- remaining menu bar daily-use verification for copy actions and a final Open
  Window regression check from hidden or backgrounded window states
- remaining reduced-toolbar verification for copy menu actions and title-bar
  crowding after future toolbar changes
- profile export/import round-trip smoke with safe temporary files when local
  file mutation is explicitly in scope
- packaged-artifact-specific launch/clean-quit smoke before any distributed
  app-bundle release
- Setup Guide inspector review against the normal Configuration flow
- one manual UI smoke pass covering main window, Setup Guide, menu bar,
  toolbar, logs, and clean quit
- concrete rough edges from `docs/automation_smoke_backlog.md` that can be
  fixed or exposed in one verified run
- post-checkpoint readiness prep such as release-gate clarity, deterministic
  smoke evidence, packaging-prep checks, update-workflow planning, or focused
  tests that do not mutate runtime installs or packaged release state
- external review preparation through `docs/external_review_flow.md` when the
  run needs release-readiness or future-direction feedback without making the
  release decision itself
- docs or issue-triage clarity only when current guidance would steer the next
  run incorrectly

Treat v0.3 adapter-boundary, v0.4 reliability, v0.5 post-public triage, v0.6
preset, v0.7 capability, v0.8 toolbar/navigation, and v0.9 update-readiness
notes as background context. Reopen one only when a concrete, release-quality
risk is visible and testable.

Do not expand into chat, conversation history, prompt libraries, RAG, tools,
attachments, model library management, model download history, model ranking,
model conversion, proxy behavior, remote exposure, bundled inference,
second-runtime work, automatic benchmarking, benchmark leaderboards, or real
runtime installation/update. User-triggered GGUF search/download work is
implemented only inside the bounded acquisition lane in
`docs/gguf_acquisition.md`; follow-up automation may harden that lane but must
not turn it into model management.
The current networked update check is limited to explicit user-triggered
`llama.cpp` latest-release metadata and must remain advisory.

Human-decision items are boundaries, not global blockers. When a run encounters
one, record the decision needed briefly and choose a different safe backlog
candidate if one exists. Use a verified no-op only when no build/test failure,
release-quality gate, or automatable rough edge can be advanced without that
decision.

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

The 2026-05-21 DeepSeek v1 polish review has also been folded into the backlog.
Prefer its repo-grounded small candidates when smoke is otherwise quiet: copy
feedback consistency, preset-description localization, duplicate localization
key cleanup, menu bar accessibility labels, disabled button visibility, and
stopped-state background rendering. HelpTooltip language policy is now resolved
for app UI text: localized titles, descriptions, tips, and headings, while
runtime logs, copied shell text, profile JSON, and adapter diagnostics stay
outside localization scope. Keep checkpoint-version plumbing, toolbar
simplification, and log persistence as human-decision items unless the user
narrows one explicitly.

The 2026-05-21 Chika v1 polish review has also been folded into the backlog.
Treat release-evidence consistency as a first-class docs target: README,
current status, troubleshooting, automation backlog, and roadmap must not
contradict each other about helper smoke, `kLSNoExecutableErr`, or manual
desktop smoke. Its safe automation candidates include Setup Guide no-runtime
wording, icon-only copy accessibility, logs retention wording, and
source-checkpoint centralization. Health checks now follow the chosen rule:
the action is disabled unless the server is running. Toolbar scope is also
decided for now: keep only Setup Guide, profile import/export, and copy
actions. The current source release posture is also decided for now:
`v1.7.0` is a source-only checkpoint, while packaged release remains a later
handoff. Keep Hugging Face setup guidance, Homebrew copy
placement, runtime breadth, and packaged-release work as human-decision items.

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
  handoff as permission for model-library management, runtime install/update,
  chat, proxy, LAN exposure, or adapter breadth.
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

- `v1.0.0-rc.1` is acceptable as a source-only release candidate when SwiftPM
  verification passes and docs clearly state that no packaged `.app` artifact is
  attached.
- Packaged-release readiness remains deferred to a future human handoff.
  Automation may prepare evidence and close local quality gaps, but should not
  decide packaged-release readiness by itself.
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
- Use `docs/external_review_flow.md` to prepare current-release and
  future-direction review requests. Keep reviewer input advisory until a human
  chooses the next release or product-boundary action.
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

- name: Hazakura Lantern stability loop
- id: `hazakura-llm-manager`
- cadence: every 2 hours in the user's local timezone
- environment: local execution in this project directory

2-hour stability posture:

- Start with `git status --short --branch`, then read the documents in the
  order above.
- Choose at most one small stability, smoke, code-quality, release-quality, or
  post-checkpoint readiness slice.
- Prefer implementation, tests, docs, commit, and push only when the slice is
  clear, genuinely improves local stability/quality, and verification passes.
- Keep runs quiet, but progress-biased. A verified no-op is valid when no
  failing quality check, smoke-lane slice, concrete rough edge, or
  post-checkpoint readiness prep is safely actionable in this run.
- Smoke-first runs are allowed: run a bounded manual or scripted smoke path,
  fix one concrete issue if it appears, and otherwise close with the smoke
  evidence and no code change.
- Do not add product features merely because the automation woke up. The loop
  acts as a local stability inspector for launch, stop, endpoint, copy, smoke,
  localization, path-validation, and docs correctness.
- Treat Codex, OpenCode, Hazakura Note, and other agent/client apps as
  downstream users of Lantern's endpoint, not as automation smoke targets.
  Automation may verify copied snippets, JSON shape, and local endpoint
  contracts, but must not launch, drive, script, or depend on those agent apps
  to prove Lantern quality.

Preferred order:

1. Fix a failing test or build.
2. Fix a failing localization lint or `git diff --check` result.
3. Harden the existing Smoke Console and Smoke Metrics surfaces from observed
   evidence, without turning them into chat, history, or benchmarks.
4. Harden GGUF Acquisition in one small slice when evidence exists: fake API
   coverage, downloader resume/cancel/failure behavior, path validation,
   localized UI copy, no-download public API smoke, or model-path handoff.
5. Fix smoke-observed rough edges after v1.7 without turning the surface into
   chat, saved history, benchmark ranking, or runtime optimization.
6. Make one small verified code-quality improvement inside the current
   `llama-server` boundary.
7. Close one unfinished release-quality gate from `docs/current_status.md`.
8. Use `docs/automation_smoke_backlog.md` to expose or fix one concrete
   pre-release rough edge that can be verified in the same run.
9. Add focused tests for observed `llama-server` launch, validation, health,
   endpoint, restart, copy-flow, or profile-warning behavior.
10. Prepare post-checkpoint readiness evidence, such as packaging-prep checks, release-gate
   wording, deterministic smoke notes, guarded update-workflow planning, or
   test coverage that does not perform real runtime or release mutation.
11. Prepare external review packets when outside judgment is needed, using
   `docs/external_review_flow.md` and keeping release/product decisions human
   owned.
12. Tighten docs when they would otherwise steer the next run incorrectly or
   confuse a `llama-server` setup path.
13. Classify public feedback or review notes with
   `docs/post_public_operations.md`, then make one safe local change only if the
   classification identifies a source-quality issue.
14. Refine presets, runtime capability advisories, or update-readiness wording
   only when it reduces a concrete release-quality risk and remains
   non-mutating.
15. End as a verified no-op only when no safe quality, smoke-lane,
   GGUF-acquisition hardening, release-quality, smoke-backlog,
   feedback-triage, test, or automation-doc slice is justified.

Avoid broad refactors, dependency changes, generated artifacts, UI restyling, or
new feature areas unless the current status and roadmap both support them.

Human approval is required before automation starts a new runtime adapter,
custom command profile implementation, profile schema version change, packaged
artifact, GitHub settings or release mutation, public issue mutation, automation
cadence change, dependency or lockfile mutation, endpoint auto-polling,
real runtime install/update execution, model library management, download
history, model ranking, Hugging Face token storage, gated-model workflow,
background download queue, LM Studio internal metadata integration,
conversation history, prompt library, RAG/tools, attachment support, automatic
benchmark/optimization, benchmark leaderboard, multiple-profile management,
launch-at-login, automatic restart policy, automation-driven Codex/OpenCode or
other agent-app operation, or update checks for runtimes beyond the current
`llama.cpp` target.

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
