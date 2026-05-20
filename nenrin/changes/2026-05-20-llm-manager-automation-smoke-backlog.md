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

## Reason

Recurring automation needs a durable, bounded source for smoke-driven polish instead of guessing broad UI work or jumping straight to v1.0 update execution.

## Expected Behavior

- Future runs should inspect the backlog after lane-specific candidates, choose at most one verifiable UI/localization/menu-bar/setup/health/profile/packaging-prep/update-readiness slice, or report a verified no-op.
- External proposal items should be used as bounded rough-edge discovery input, not as permission for broad redesign, new tools, runtime mutation, or release packaging.

## Review After

- 1 related task(s)
- 14 day(s)

## Success Signals

- TBD

## Failure Signals

- TBD

## Result

Unjudged.
