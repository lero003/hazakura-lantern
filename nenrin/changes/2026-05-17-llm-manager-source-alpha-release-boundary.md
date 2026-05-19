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
  - docs/product_brief.md
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
  handoff guidance, `llama-server` reliability guidance, post-public
  stewardship guidance, troubleshooting checks, and a repo-local Nenrin ledger
  for durable agent-facing workflow decisions.

## Reason

Hazakura Lantern now has source-only prerelease checkpoints and recurring
automation that should close v0.3 only when a concrete adapter ambiguity
remains, then move to v0.4 `llama-server` reliability without drifting into
packaged app release work, chat, model download, proxy, LAN/auth, updater,
custom command profiles, Ollama, or adapter breadth.
The user has approved continuing through v0.5 automatically when no concrete
v0.4 reliability slice is visible.

## Expected Behavior

- Future runs use Nenrin for release/automation/scope judgment evidence, keep
  `v0.3.0-alpha.1` as a public source-only checkpoint, treat Launch Services
  as a packaged-app release blocker, and skip records for ordinary
  implementation logs.
- Future review feedback is pruned against the current lane: keep concrete
  adapter-boundary, `llama-server` launch/configuration, observed restart-state,
  copy-flow, health-wording, empty-state, setup-hint, profile-warning, and
  post-public docs hygiene slices; defer endpoint auto-polling, runtime version
  checks, custom command implementation, new adapters, and multiple-profile
  management unless a later lane and human handoff explicitly reopen them.
- Future automation checks both v0.4 `llama-server` reliability and v0.5
  post-public triage/docs candidates before declaring verified no-op.
- Future automation may propose issue labels and draft responses locally, but
  does not apply labels, post replies, close issues, or otherwise mutate public
  issue state without explicit human approval.

## Review After

- 5 related task(s)
- 14 day(s)

## Success Signals

- Future automation runs `nenrin brief` before release, lane-handoff, or
  recurring workflow decisions where prior judgment could change the next step.
- `v0.3.0-alpha.1` remains framed as source-only, with no packaged `.app`
  artifact or release claim.
- Post-public stewardship classifies public feedback before implementation and
  keeps public-opening preflight as a historical/release-handoff checklist, but
  v0.4 automation primarily improves `llama-server` reliability.
- If v0.4 is quiet, automation continues into v0.5 issue triage and
  automation-discipline docs instead of stopping early.
- v0.5 triage handoffs use the local label vocabulary and draft-response
  shapes in `docs/post_public_operations.md` without promising feature support
  or mutating public issues.
- Public-opening or release actions stay human-gated for GitHub visibility,
  settings, branch protection, tags, releases, release assets, public issue
  mutation, packaged artifacts, and binary distribution claims.
- Public-facing agent guidance uses placeholders instead of maintainer-local
  absolute paths.
- Launch Services remains a packaged-app release blocker but does not block
  source-only adapter-boundary work.
- External review suggestions that would reopen v0.1 or v0.2 breadth, custom
  command profiles, Ollama, broad adapter expansion, or packaged release work
  are either narrowed to one testable current-lane `llama-server` slice or
  dropped.
- Ordinary implementation work reports Nenrin no-op instead of creating log
  records.

## Failure Signals

- A run creates Nenrin records for routine implementation logs or tiny copy
  changes.
- Automation treats Nenrin as a task generator and stops after preflight
  instead of completing a clear slice.
- A packaged app release, zip/dmg, signing, or notarization claim appears
  before app-bundle launch verification succeeds.
- v0.4 work drifts into custom command profiles, Ollama, MLX implementation, or
  broad adapter abstraction before the `llama-server` path is boring.

## Result

Unjudged.
