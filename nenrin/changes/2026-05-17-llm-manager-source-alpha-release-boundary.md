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
  - docs/post_public_operations.md
  - docs/public_opening_preflight.md
  - docs/runtime_adapters.md
  - CHANGELOG.md
  - .github/workflows/ci.yml
  - nenrin/README.md
review_after:
  tasks: 5
  days: 14
---

# Change: llm-manager-source-alpha-release-boundary

## Changed

- Adopted a source-only alpha release boundary, v0.2 checkpoint, v0.3 automation
  handoff guidance, post-public stewardship guidance, troubleshooting checks,
  and a repo-local Nenrin ledger for durable agent-facing workflow decisions.

## Reason

Hazakura Lantern now has source-only prerelease checkpoints and recurring
automation that should close v0.3 only when a concrete adapter ambiguity
remains, then move to v0.4 post-public stewardship without drifting into
packaged app release work, chat, model download, proxy, LAN/auth, updater, or
adapter breadth.

## Expected Behavior

- Future runs use Nenrin for release/automation/scope judgment evidence, keep
  `v0.3.0-alpha.1` as a public source-only checkpoint, treat Launch Services
  as a packaged-app release blocker, and skip records for ordinary
  implementation logs.
- Future review feedback is pruned against the current lane: keep concrete
  adapter-boundary, observed restart-state, copy-flow, empty-state, setup-hint,
  and post-public docs hygiene slices; defer endpoint auto-polling, runtime
  version checks, custom command implementation, new adapters, and
  multiple-profile management unless a later lane and human handoff explicitly
  reopen them.

## Review After

- 5 related task(s)
- 14 day(s)

## Success Signals

- Future automation runs `nenrin brief` before release, lane-handoff, or
  recurring workflow decisions where prior judgment could change the next step.
- `v0.3.0-alpha.1` remains framed as source-only, with no packaged `.app`
  artifact or release claim.
- Post-public stewardship classifies public feedback before implementation and
  keeps public-opening preflight as a historical/release-handoff checklist.
- Public-opening or release actions stay human-gated for GitHub visibility,
  settings, branch protection, tags, releases, release assets, public issue
  mutation, packaged artifacts, and binary distribution claims.
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
