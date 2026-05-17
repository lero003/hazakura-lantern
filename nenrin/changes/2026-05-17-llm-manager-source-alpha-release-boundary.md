---
type: nenrin_change
id: llm-manager-source-alpha-release-boundary
date: 2026-05-17
status: observing
impact: unknown
related_files:
  - AGENTS.md
  - docs/development_loop.md
  - docs/current_status.md
  - docs/troubleshooting.md
  - CHANGELOG.md
  - .github/workflows/ci.yml
  - nenrin/README.md
review_after:
  tasks: 5
  days: 14
---

# Change: llm-manager-source-alpha-release-boundary

## Changed

- Adopted a source-only alpha release boundary, v0.3 automation handoff guidance, troubleshooting checks, and a repo-local Nenrin ledger for durable agent-facing workflow decisions.

## Reason

Hazakura Lantern now has a public prerelease checkpoint and recurring automation that should continue through v0.3 without drifting into packaged app release work, chat, model download, proxy, LAN/auth, updater, or adapter breadth.

## Expected Behavior

- Future runs use Nenrin for release/automation/scope judgment evidence, keep v0.1.0-alpha.1 as source-only, treat Launch Services as a packaged-app release blocker but not a v0.2 profile-work blocker, and skip records for ordinary implementation logs.

## Review After

- 5 related task(s)
- 14 day(s)

## Success Signals

- Future automation runs `nenrin brief` before release, lane-handoff, or
  recurring workflow decisions where prior judgment could change the next step.
- `v0.1.0-alpha.1` remains framed as source-only, with no packaged `.app`
  artifact or release claim.
- Launch Services remains a packaged-app release blocker but does not block
  v0.2 profile-contract work.
- Ordinary implementation work reports Nenrin no-op instead of creating log
  records.

## Failure Signals

- A run creates Nenrin records for routine implementation logs or tiny copy
  changes.
- Automation treats Nenrin as a task generator and stops after preflight
  instead of completing a clear slice.
- A packaged app release, zip/dmg, signing, or notarization claim appears
  before app-bundle launch verification succeeds.
- v0.3 work adds adapter breadth before profile contract and adapter boundary
  tests/docs are ready.

## Result

Unjudged.
