# Post-Public Operations

This document is the operating guide for the public source-only checkpoint after
the repository is visible. It is not permission to publish packaged app
artifacts, change GitHub settings, or widen runtime scope.

Use `docs/public_opening_preflight.md` for historical pre-open checks and
future visibility or release handoffs. Use this document for ongoing public
feedback, automation triage, and post-public docs hygiene.
Use `docs/external_review_flow.md` when preparing paste-ready requests for
outside release-readiness or future-direction review.

## Operating Posture

Hazakura Lantern is currently public as a source-only `v1.5.1` checkpoint for
personal/local use. The previous source-only checkpoint was `v1.5.0`.
Automated work should keep the project understandable, narrow, and easy to
review while the near-term source lane improves the existing `llama-server`
path through post-checkpoint smoke polish.

Post-public stewardship is a guardrail now and the formal v0.5 lane later.
Automation may start v0.5 docs and triage improvements when v0.4 has no
concrete safe `llama-server` reliability slice:

- classify public feedback before implementing it
- keep source-only and packaged-release boundaries clear
- fix small reproducible bugs in the existing `llama-server` behavior
- improve docs, empty states, setup hints, or copy flows only when a concrete
  user-facing ambiguity exists
- accept verified no-op when no safe slice is justified

Do not treat public interest as permission to turn Lantern into a chat app,
model manager, runtime installer, proxy, marketplace, or general command
runner. The bounded GGUF acquisition lane is a user-triggered file download
helper only; it is not a model library or marketplace.

## Issue Triage Taxonomy

Classify incoming issues or review notes before choosing work:

- A. `source-build blocker`: SwiftPM build, test, or source verification fails.
- B. `llama-server launch/configuration bug`: existing runtime selection,
  validation, command construction, launch preflight, process lifecycle,
  endpoint display, health check, logs, or copied snippet behavior is wrong or
  confusing.
- C. `profile import/export bug`: active profile JSON, schema version `1`,
  runtime kind, portability warnings, preview, import, export, or persistence
  behavior is wrong.
- D. `docs confusion`: README, troubleshooting, current status, roadmap,
  issue templates, or setup guidance misleads users.
- E. `packaged app blocker`: app-bundle launch, `.app`, zip, dmg, signing,
  notarization, checksums, GitHub Release assets, or installer expectations.
- F. `runtime-breadth request`: MLX, Ollama, custom command profiles, runtime
  catalogs, networked runtime version checks beyond the current explicit
  `llama.cpp` release-metadata check, endpoint polling, or
  second-runtime support.
- G. `adjacent-product request`: image, audio, video, or other multimedia
  generation workflows that may fit the broader Hazakura ecosystem but do not
  yet fit Lantern's current local-runtime supervision boundary.
- H. `out-of-scope request`: chat, model library management, download history,
  model ranking, model conversion, RAG,
  tools, proxy behavior, LAN exposure, authentication, runtime installation,
  automatic updates, package-manager mutation, marketplace behavior, multiple
  profile management, launch-at-login, or automatic restart policy.
- I. `security-sensitive report`: secrets, credentials, private paths,
  network exposure, authentication, supply chain, or host privacy concerns.

For B-class reports, separate Lantern-owned behavior from runtime-owned
behavior before proposing a fix. Lantern owns selected paths, validation,
generated arguments, process supervision, displayed endpoint values, manual
health-check requests, copied snippets, and wording. The local runtime owns
model loading, supported flags, server API behavior, response quality, and
runtime crashes after Lantern successfully starts the process.

When the report is runtime-owned, keep the local action narrow: improve setup
guidance, copied commands, or troubleshooting only if Lantern wording made the
boundary confusing. Do not add installers, package-manager mutation, runtime
updates, endpoint polling, proxy behavior, or a new adapter to work around an
upstream runtime issue.

When reporting a triage result, prefer:

```text
Classification:
Owner:
Recommended action:
Human approval needed:
Verification:
Confidence:
```

## Label Proposals

Automation may propose labels in local notes or handoff text, but must not apply
labels to public GitHub issues without explicit human approval.

Use this small label vocabulary unless the repository owner creates a different
public label set:

- `area:source-build` for A. source-build blockers.
- `area:llama-server` for B. launch, configuration, endpoint, health, logs, or
  copied snippet issues in the existing runtime path.
- `area:profile` for C. active profile import/export, schema, portability,
  preview, or persistence issues.
- `area:docs` for D. docs or setup-guidance confusion.
- `area:packaging` for E. app-bundle, release asset, signing, notarization, or
  installer expectation issues.
- `type:runtime-breadth-request` for F. second-runtime, custom command,
  runtime catalog, version-check, or endpoint-polling requests.
- `type:adjacent-product-request` for G. multimedia-generation ideas that
  should be evaluated as future ecosystem direction before Lantern scope.
- `type:out-of-scope` for H. requests outside Lantern's current boundary.
- `security-sensitive` for I. reports involving secrets, credentials, private
  paths, network exposure, authentication, supply chain, or host privacy.

Prefer one area label plus one type label only when both add signal. For
example, an MLX adapter request can be only `type:runtime-breadth-request`,
while a packaged `.app` launch failure can be only `area:packaging`.

## Draft Response Shape

Automation may prepare draft responses without posting them. Keep drafts short,
avoid promising feature support, and include the approval boundary when the next
public action requires a human.

For source or `llama-server` bugs:

```text
Thanks for the report. I would classify this as <classification>.
I would treat the owner as <Lantern/runtime/setup> based on <short evidence>.
The next local step is <small verification or focused fix>.
Human approval is <needed/not needed> before any public issue mutation.
```

For packaged-app or release-asset blockers:

```text
Thanks for the report. Lantern is currently a source-only checkpoint,
so this is a packaged-release blocker rather than a source-build blocker.
The current safe path is SwiftPM verification while the app-bundle launch path
is investigated separately.
```

For runtime-breadth or out-of-scope requests:

```text
Thanks for the suggestion. This is outside the current source lane.
Lantern is staying focused on the existing `llama-server` path before new
runtimes, chat, model management, proxy behavior, LAN exposure, or installers.
```

For adjacent-product requests:

```text
Thanks for the idea. I would classify this as adjacent-product direction rather
than current Lantern scope.
The useful next step is a short design note or external product-direction
review: should this stay separate, become a sibling project, or share Lantern's
local-runtime supervision contract later?
```

For security-sensitive reports:

```text
Thanks for flagging this. Please avoid posting secrets, tokens, private paths,
or sensitive host details publicly. This should be handled as a human-reviewed
security-sensitive report before any public reply or label change.
```

## Automation-Safe Work

Automation may do one small, verifiable slice per run:

- run `git status --short --branch`, `swift test`,
  `swift build --disable-sandbox`, and `git diff --check`
- add focused tests for an existing boundary when a new bug, regression, or
  design note names a concrete ambiguity
- fix a small reproducible bug in current source behavior
- update README, changelog, current status, roadmap, troubleshooting, runtime
  adapter docs, or this operations guide
- classify public issues or review notes and propose labels or next actions
- prepare draft issue responses without posting them
- prepare external release-readiness or future-direction review requests with
  `docs/external_review_flow.md`
- maintain local repository hygiene files such as CODEOWNERS, pinned CI action
  references, Dependabot proposal configuration, and local secret-ignore rules
  when they reduce review or supply-chain ambiguity without changing remote
  repository settings
- improve small `llama-server` empty-state, setup-hint, copy-flow,
  health-wording, profile-warning, or error-message wording when the current
  docs or issue text identify the ambiguity
- record a known blocker or verified no-op when no safe slice exists

Automation should not keep adding adapter-boundary tests after v0.3 close-out
unless a new issue, regression, or design note identifies the missing case.

## Human-Approval-Only Work

Require explicit human handoff before:

- adding a new runtime adapter
- starting custom command profile implementation
- starting MLX adapter implementation before a design note is accepted
- changing the runtime profile schema version
- changing GitHub visibility, branch protection, collaborators, secrets,
  webhooks, Actions settings, tags, GitHub Releases, release assets, or
  repository packages
- publishing packaged `.app`, zip, dmg, signing, notarization, checksums, or
  binary distribution claims
- automatically replying to, labeling, closing, or otherwise mutating public
  GitHub issues
- changing the saved automation cadence
- adding networked runtime version checks or runtime update checks beyond the
  current explicit `llama.cpp` release-metadata check
- adding unattended runtime install/update execution, model library management,
  download history, model catalog ownership, multimedia generation workflow,
  proxy, LAN exposure, authentication, multiple-profile management,
  launch-at-login, or automatic restart behavior
- mutating dependencies, lockfiles, package managers, or version-manager files

## Packaged-Release Boundary

`kLSNoExecutableErr` is a packaged-app launch-smoke blocker, not a blocker for
source-only public work. Do not retry that path in hourly automation unless a
fresh hypothesis exists or a normal macOS verification environment is
available.

The packaging track should remain separate from source milestones:

- P0: Codex-environment reproduction record
- P1: normal macOS external verification
- P2: bundle metadata, signing, or launch-path fix
- P3: unsigned local app artifact
- P4: signed and notarized distribution

## When To Update Docs

Update `docs/current_status.md` when the true current lane, known blocker, or
next best slice changes.

Update `docs/roadmap.md` when milestone intent, approval gates, or deferred
work changes.

Update `CHANGELOG.md` under `Unreleased` for user-visible docs, workflow, or
behavior changes on `main`.

Update Nenrin only when the change affects future agent behavior, release
gates, verification policy, recurring automation guidance, or repeated blocker
handling.
