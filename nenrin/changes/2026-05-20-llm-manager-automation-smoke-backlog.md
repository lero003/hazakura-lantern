---
type: nenrin_change
id: llm-manager-automation-smoke-backlog
date: 2026-05-20
status: observing
impact: unknown
related_files:
  - docs/automation_smoke_backlog.md
  - docs/development_loop.md
  - docs/current_status.md
  - docs/roadmap.md
review_after:
  tasks: 1
  days: 14
---

# Change: llm-manager-automation-smoke-backlog

## Changed

- Added docs/automation_smoke_backlog.md and linked it from current_status, roadmap, and development_loop so automation can pick one concrete pre-release rough-edge slice.
- Folded the 2026-05-20 external general-distribution improvement proposal into the backlog as triaged automation candidates, human-decision items, low-priority polish, and scope boundaries.
- Reframed the recurring automation runbook so unfinished release-quality gates outrank version-numbered lane progression.
- Recorded the 2026-05-21 automated smoke regression so future runs treat `./script/build_and_run.sh --verify` as mixed helper-level evidence, while keeping source-only SwiftPM verification separate from packaged-release proof.
- Folded the 2026-05-21 Gemini v1 polish review into the backlog as bounded localization, HelpTooltip, launch-helper, toolbar, and log-policy follow-up input.
- Folded the 2026-05-21 DeepSeek v1 polish review into the backlog as bounded copy-feedback, preset-localization, localization-key cleanup, menu-bar accessibility, disabled-button, and stopped-background follow-up input.
- Folded the 2026-05-21 Chika v1 polish review into the backlog as bounded release-evidence, manual-smoke, health-check policy, Setup Guide empty-state, copy-accessibility, logs-retention, and source-checkpoint follow-up input.
- Clarified that human-decision items block only their exact slice, not unrelated safe automation work.
- Recorded the 2026-05-22 human decisions that health checks are running-server-only and the main toolbar should stay reduced to Setup Guide, profile import/export, and copy actions.
- Recorded the 2026-05-22 human decision that `llama.cpp` may have an explicit, user-triggered, non-mutating Check for Updates action, while other runtime update checks remain future human decisions.
- Recorded the earlier 2026-05-22 direction that public/release judgment stayed
  deferred while automation continued code-quality checks, narrow verified
  improvements, and non-public v1 readiness prep; this is now superseded by the
  source-only RC decision below.
- Recorded the 2026-05-22 human decision to release `v1.0.0-rc.1` as a
  source-only RC for personal/local use, while keeping packaged app release work
  separate and blocked on manual desktop evidence.
- Recorded the 2026-05-23 human decision to move the saved Lantern development
  automation to a 30-minute cadence and aim it through `v1.1` Local Smoke
  Console, `v1.2` Runtime Smoke Metrics, and immediate smoke-driven rough-edge
  fixes before a possible `v1.3` source-stable checkpoint.
- Recorded the 2026-05-26 post-GGUF automation shift: Smoke Console and
  Metrics are existing surfaces to harden from evidence, and GGUF Acquisition
  is now an implemented bounded lane that automation may harden only through
  tests, no-download API shape checks, UI copy/accessibility, and focused
  download-state fixes.

## Reason

Recurring automation needs a durable, bounded source for smoke-driven polish instead of guessing broad UI work or jumping straight to v1.0 update execution.

## Expected Behavior

- Future runs should inspect unfinished release-quality gates and the backlog, choose at most one verifiable UI/localization/menu-bar/setup/health/profile/packaging-prep/update-readiness slice, or report a verified no-op.
- External proposal items should be used as bounded rough-edge discovery input, not as permission for broad redesign, new tools, runtime mutation, or release packaging.
- Future runs should treat exact v0.x labels as history and choose from unfinished release-quality gates first: normal desktop/manual launch and quit smoke, menu bar daily-use verification, toolbar role decision, Setup Guide review, manual UI smoke, or a concrete backlog rough edge.
- Future runs should not loop on historical `kLSNoExecutableErr` unless a fresh Launch Services hypothesis appears; the current helper smoke is again a release-quality gate rather than source-build proof.
- Future runs should verify one visible localization surface at a time and preserve the UI-only localization boundary unless the user explicitly broadens it.
- Future runs should prefer one repo-grounded daily-use rough edge at a time, especially copy feedback consistency, visible localization mismatches, menu bar accessibility, disabled button visibility, or stopped-state animation behavior.
- Future runs should keep helper-smoke documentation internally consistent before using it for release judgment, and should record normal desktop/manual smoke only from a real app session.
- Future runs should not treat toolbar, release-posture, packaging, or product-policy decisions as global blockers when another safe P0/P1 polish slice is available.
- Future runs should not re-add lifecycle, health, command-reveal, or log-clear actions to the toolbar unless a human explicitly reopens toolbar scope.
- Future runs should keep manual health-check controls disabled until the server is running.
- Future runs may polish or test the `llama.cpp` update check while it remains advisory and non-mutating, but should not add other runtime targets or execute package-manager/Git/download/binary-replacement updates without explicit approval.
- Future runs should fix failing quality checks first, then choose one narrow
  code-quality, release-quality, or post-RC readiness slice; they should not
  create packaged artifacts, mutate runtime installs, or decide packaged-release
  readiness without an explicit human handoff.
- Future runs should prefer evidence-backed quality work before generic polish:
  harden the existing explicit, user-triggered Smoke Console and last-run Smoke
  Metrics surfaces, then fix one smoke-observed rough edge at a time.
- Future runs may harden GGUF Acquisition inside `docs/gguf_acquisition.md`
  with fake Hugging Face fixtures, destination-path tests, resume/cancel/failure
  coverage, localized UI/accessibility polish, no-download public API shape
  checks, or completion-to-model-path handoff fixes.
- Future runs should not turn Smoke Console into chat, saved conversation
  history, prompt libraries, RAG/tools, attachments, model catalog management,
  automatic endpoint polling, benchmark ranking, or runtime optimization.
- Future runs should not turn GGUF Acquisition into a model database, download
  history, ranking/recommendation surface, deletion manager, background
  downloader, token store, gated-model account flow, or LM Studio metadata
  integration.

## Review After

- 1 related task(s)
- 14 day(s)

## Success Signals

- Automation reports one concrete smoke/backlog slice with verification, or a clear no-op when no safe release-quality slice exists.
- Automation reports one concrete Smoke Console, Smoke Metrics, GGUF
  Acquisition, or release-quality slice with verification, or a clear no-op
  when no safe quality slice exists.
- Source verification remains boring: `git diff --check`, localization lint, `swift test`, and `swift build --disable-sandbox` pass even when Launch Services helper smoke is blocked.

## Failure Signals

- Automation treats any helper smoke result as packaged-release proof.
- Automation loops on historical `kLSNoExecutableErr` without a fresh hypothesis or without keeping source work moving separately.
- Automation builds chat history, benchmark dashboards, or runtime breadth while
  claiming to implement smoke verification.
- Automation expands GGUF Acquisition into persistent model management,
  unattended downloads, token storage, gated-account flows, or LM Studio
  internal metadata mutation.

## Result

Unjudged.
