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
- Recorded the 2026-05-21 automated smoke result and updated recurring guidance so future runs treat `./script/build_and_run.sh --verify` as passing helper-level evidence, while keeping manual desktop UI smoke as the remaining release gate.

## Reason

Recurring automation needs a durable, bounded source for smoke-driven polish instead of guessing broad UI work or jumping straight to v1.0 update execution.

## Expected Behavior

- Future runs should inspect unfinished release-quality gates and the backlog, choose at most one verifiable UI/localization/menu-bar/setup/health/profile/packaging-prep/update-readiness slice, or report a verified no-op.
- External proposal items should be used as bounded rough-edge discovery input, not as permission for broad redesign, new tools, runtime mutation, or release packaging.
- Future runs should not re-diagnose historical `kLSNoExecutableErr` unless the helper smoke regresses or a fresh Launch Services hypothesis appears.

## Review After

- 1 related task(s)
- 14 day(s)

## Success Signals

- Automation reports one concrete smoke/backlog slice with verification, or a clear no-op when no safe release-quality slice exists.
- Launch-helper cleanup remains boring: `--verify` or `--stop` leaves no `HazakuraLLMManager` process behind.

## Failure Signals

- Automation treats the 2026-05-21 helper smoke as packaged-release proof.
- Automation loops on historical `kLSNoExecutableErr` without a new regression or hypothesis.

## Result

Unjudged.
