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

## Reason

Recurring automation needs a durable, bounded source for smoke-driven polish instead of guessing broad UI work or jumping straight to v1.0 update execution.

## Expected Behavior

- Future runs should inspect unfinished release-quality gates and the backlog, choose at most one verifiable UI/localization/menu-bar/setup/health/profile/packaging-prep/update-readiness slice, or report a verified no-op.
- External proposal items should be used as bounded rough-edge discovery input, not as permission for broad redesign, new tools, runtime mutation, or release packaging.
- Future runs should treat exact v0.x labels as history and choose from unfinished release-quality gates first: normal desktop/manual launch and quit smoke, menu bar daily-use verification, toolbar role decision, Setup Guide review, manual UI smoke, or a concrete backlog rough edge.
- Future runs should not loop on historical `kLSNoExecutableErr` unless a fresh Launch Services hypothesis appears; the current helper smoke is again a release-quality gate rather than source-build proof.
- Future runs should verify one visible localization surface at a time and preserve the UI-only localization boundary unless the user explicitly broadens it.

## Review After

- 1 related task(s)
- 14 day(s)

## Success Signals

- Automation reports one concrete smoke/backlog slice with verification, or a clear no-op when no safe release-quality slice exists.
- Source verification remains boring: `git diff --check`, localization lint, `swift test`, and `swift build --disable-sandbox` pass even when Launch Services helper smoke is blocked.

## Failure Signals

- Automation treats any helper smoke result as packaged-release proof.
- Automation loops on historical `kLSNoExecutableErr` without a fresh hypothesis or without keeping source work moving separately.

## Result

Unjudged.
