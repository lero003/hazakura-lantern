---
type: nenrin_change
id: llm-manager-source-alpha-release-boundary
date: 2026-05-17
status: observing
impact: unknown
related_files:
  - AGENTS.md
  - README.md
  - docs/development_loop.md
  - docs/current_status.md
  - docs/roadmap.md
  - docs/troubleshooting.md
  - docs/public_opening_preflight.md
  - CHANGELOG.md
  - .github/workflows/ci.yml
  - nenrin/README.md
review_after:
  tasks: 5
  days: 14
---

# Change: llm-manager-source-alpha-release-boundary

## Changed

- Adopted a source-only alpha release boundary, v0.2 checkpoint and v0.3 automation handoff guidance, troubleshooting checks, and a repo-local Nenrin ledger for durable agent-facing workflow decisions.

## Reason

Hazakura Lantern now has source-only prerelease checkpoints and recurring automation that should continue toward v0.3 without drifting into packaged app release work, chat, model download, proxy, LAN/auth, updater, or adapter breadth.

## Expected Behavior

- Future runs use Nenrin for release/automation/scope judgment evidence, keep v0.2.0-alpha.1 as a source-only profile checkpoint, treat Launch Services as a packaged-app release blocker, and skip records for ordinary implementation logs.
- Future review feedback is pruned against the current lane: keep adapter-boundary, observed restart-state, copy-flow, empty-state, and setup-hint slices; defer endpoint auto-polling, runtime version display, and multiple-profile management unless a later lane explicitly reopens them.

## Review After

- 5 related task(s)
- 14 day(s)

## Success Signals

- Future automation runs `nenrin brief` before release, lane-handoff, or
  recurring workflow decisions where prior judgment could change the next step.
- `v0.2.0-alpha.1` remains framed as source-only, with no packaged `.app`
  artifact or release claim.
- Public-opening preparation stays local and static until a human explicitly
  hands off GitHub visibility, settings, branch protection, tags, releases, or
  release assets.
- Public-facing agent guidance uses placeholders instead of maintainer-local
  absolute paths.
- Launch Services remains a packaged-app release blocker but does not block
  source-only adapter-boundary work.
- External review suggestions that would reopen v0.1 or v0.2 breadth are either
  narrowed to one testable current-lane slice or dropped.
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
