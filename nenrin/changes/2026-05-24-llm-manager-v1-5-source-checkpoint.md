---
type: nenrin_change
id: llm-manager-v1-5-source-checkpoint
date: 2026-05-24
status: observing
impact: unknown
related_files:
  - README.md
  - CHANGELOG.md
  - docs/current_status.md
  - docs/roadmap.md
  - docs/development_loop.md
  - docs/dmg-preview-checklist.md
  - docs/external_review_flow.md
  - docs/post_public_operations.md
  - docs/releases/1.7.0-warning-expected-dmg-preview.md
  - docs/releases/1.7.0-warning-expected-dmg-preview.release.md
  - docs/automation_smoke_backlog.md
review_after:
  tasks: 1
  days: 30
---

# Change: llm-manager-source-checkpoint-posture

## Changed

- Marked v1.7.0 as the current source-only checkpoint across app metadata, README, changelog, status, roadmap, external review, development loop, post-public operations, issue template, and smoke backlog docs.
- Recorded that the automated development loop is paused while release and packaged-artifact expectations are reviewed manually.
- Added the warning-expected DMG preview checklist and release-note templates as the durable boundary for any future binary asset publication.

## Reason

Future agents should treat v1.5 and earlier checkpoints as history, preserve the v1.7 source-only boundary, and avoid turning the DMG warning preview into a packaged-release claim.

## Expected Behavior

- While automation is paused, no recurring development slice is expected.
- If automation resumes, it chooses one verifiable post-v1.7 smoke, cleanup, localization, setup-guide, GGUF Acquisition, or release-evidence slice and keeps packaged-release work behind explicit human handoff.
- If the release lane changes to warning-expected DMG preview, agents use `docs/dmg-preview-checklist.md` and do not attach binary assets without explicit approval.

## Review After

- 1 related task(s)
- 30 day(s)

## Success Signals

- TBD

## Failure Signals

- TBD

## Result

Unjudged.
