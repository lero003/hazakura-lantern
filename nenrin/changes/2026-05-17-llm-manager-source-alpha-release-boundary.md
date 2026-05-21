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
  - docs/external_review_flow.md
  - docs/runtime_adapters.md
  - docs/runtime_profiles.md
  - docs/llama_server_presets.md
  - docs/toolbar_and_navigation.md
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
- Advanced the source-only checkpoint framing to `v0.5.0-alpha.1`, making
  post-public issue triage and automation discipline the current default lane
  while leaving packaged app release work blocked by Launch Services smoke.
- Reframed v0.6 and v0.7 to stay on the existing `llama-server` adapter:
  model-family presets, option compatibility, and read-only runtime capability
  advisories now come before MLX design or implementation.
- Restored v0.8 as menu bar/toolbar/navigation work for existing actions,
  placed v0.9 on non-mutating `llama-server` update readiness, and reserved
  v1.0 for a guarded, user-confirmed `llama-server` update workflow.
- Added an external review flow so current-release feedback and future product
  direction feedback can be requested without treating outside comments as
  release approval or immediate scope expansion.

## Reason

Hazakura Lantern now has source-only prerelease checkpoints and recurring
automation that should treat v0.3 adapter-boundary and v0.4 `llama-server`
reliability as prior lanes unless a concrete ambiguity or regression is visible.
The current default lane is v0.5 post-public issue triage and automation
discipline. Automation may continue through v0.8 without another human prompt
only while staying on the existing `llama-server` adapter: v0.6 for
command-visible model-family presets and option compatibility, v0.7 for
read-only runtime capability advisories, and v0.8 for menu bar/toolbar/navigation
actions that mirror existing behavior. Automation may also prepare v0.9 update
readiness while it remains advisory and non-mutating. It must not drift into
packaged app release work, chat, model download, proxy, LAN/auth, unattended
updates, custom command profiles, Ollama, MLX implementation, or adapter
breadth.

## Expected Behavior

- Future runs use Nenrin for release/automation/scope judgment evidence, keep
  `v0.5.0-alpha.1` as a public source-only checkpoint, treat Launch Services
  as a packaged-app release blocker, and skip records for ordinary
  implementation logs.
- Future review feedback is pruned against the current lane: keep concrete
  v0.5 public-feedback classification, automation-safe triage, docs hygiene,
  and explicitly named `llama-server` launch/configuration, observed
  restart-state, copy-flow, health-wording, empty-state, setup-hint, or
  profile-warning slices; keep v0.6/v0.7 work on presets and read-only runtime
  capability checks; keep v0.8 menu bar/toolbar/navigation work limited to
  existing actions; after the initial menu bar control surface, prefer
  daily-use verification or toolbar demotion decisions over new control
  surfaces; keep v0.9 update-readiness work advisory and non-mutating; defer
  endpoint auto-polling, unattended runtime installation/update, model download,
  automatic benchmarking, custom command implementation, new adapters, and
  multiple-profile management unless a later lane and human handoff explicitly
  reopen them.
- Future automation checks v0.5 post-public triage/docs candidates, v0.6
  preset candidates, v0.7 runtime-advisory candidates, v0.8 menu
  bar/toolbar/navigation candidates, non-mutating v0.9 update-readiness
  candidates, and any concrete v0.4 reliability signal before declaring
  verified no-op.
- Future automation may propose issue labels and draft responses locally, but
  does not apply labels, post replies, close issues, or otherwise mutate public
  issue state without explicit human approval.
- Future external review intake should separate source-readiness judgment from
  product-direction judgment, and should classify image/audio/video generation
  ideas as adjacent-product direction unless a design note proves they fit
  Lantern's local-runtime supervision contract.

## Review After

- 5 related task(s)
- 14 day(s)

## Success Signals

- Future automation runs `nenrin brief` before release, lane-handoff, or
  recurring workflow decisions where prior judgment could change the next step.
- `v0.5.0-alpha.1` remains framed as source-only, with no packaged `.app`
  artifact or release claim.
- Post-public stewardship classifies public feedback before implementation and
  keeps public-opening preflight as a historical/release-handoff checklist.
- If v0.5 triage is quiet, automation can progress into v0.6 presets and v0.7
  runtime-advisory checks, then v0.8 menu bar/toolbar/navigation work, instead
  of reopening old reliability work just to fill the lane.
- v0.9 update-readiness work identifies runtime source, version, option
  compatibility, and dry-run requirements without executing real package
  manager, git, download, or binary replacement commands.
- v1.0 update workflow work remains guarded: every real update is opt-in,
  user-confirmed, source-scoped, visible before execution, and tested with
  fakes before it touches a real runtime.
- MTP guidance stays explicit and conservative: `--spec-type draft-mtp` and
  `--spec-draft-n-max` belong to MTP-capable model/preset choices, not a global
  default, and the launch command must remain visible and editable.
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
- External review requests produce concrete release-readiness questions and
  product-boundary questions before implementation work starts.
- Ordinary implementation work reports Nenrin no-op instead of creating log
  records.

## Failure Signals

- A run creates Nenrin records for routine implementation logs or tiny copy
  changes.
- Automation treats Nenrin as a task generator and stops after preflight
  instead of completing a clear slice.
- A packaged app release, zip/dmg, signing, or notarization claim appears
  before app-bundle launch verification succeeds.
- v0.6/v0.7/v0.8/v0.9 work drifts into hidden optimization, automatic
  benchmarking, unattended runtime updates, model downloads, custom command
  profiles, Ollama, MLX implementation, or broad adapter abstraction before the
  `llama-server` preset, advisory, menu bar/toolbar, and update-readiness paths
  are useful.
- v1.0 update workflow work executes real package-manager, git, download, or
  binary replacement commands without explicit human confirmation for that run.
- Image, audio, video, or multimedia generation ideas are implemented directly
  in Lantern before being classified as adjacent product direction or accepted
  through a focused design note.

## Result

Unjudged.
