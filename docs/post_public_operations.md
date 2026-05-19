# Post-Public Operations

This document is the operating guide for the public source-only alpha after
the repository is visible. It is not permission to publish packaged app
artifacts, change GitHub settings, or widen runtime scope.

Use `docs/public_opening_preflight.md` for historical pre-open checks and
future visibility or release handoffs. Use this document for ongoing public
feedback, automation triage, and post-public docs hygiene.

## Operating Posture

Hazakura Lantern is currently public as a source-only alpha. Automated work
should keep the project understandable, narrow, and easy to review before it
adds runtime breadth.

The default next lane is post-public stewardship:

- classify public feedback before implementing it
- keep source-only and packaged-release boundaries clear
- fix small reproducible bugs in the existing behavior
- improve docs, empty states, setup hints, or copy flows only when a concrete
  user-facing ambiguity exists
- accept verified no-op when no safe slice is justified

Do not treat public interest as permission to turn Lantern into a chat app,
model manager, runtime installer, proxy, marketplace, or general command
runner.

## Issue Triage Taxonomy

Classify incoming issues or review notes before choosing work:

- `source-alpha bug`: a reproducible failure in SwiftPM build, tests, profile
  JSON, adapter validation, command preview, logs, endpoint display, health
  check, or current docs.
- `packaged-release blocker`: app-bundle launch, `.app`, zip, dmg, signing,
  notarization, checksums, GitHub Release assets, or installer expectations.
- `adapter-boundary ambiguity`: unclear ownership around command construction,
  validation, launch preflight, endpoint display, health timeout, environment
  snippets, or launch failure wording.
- `post-public docs hygiene`: stale pre-open wording, unclear source-only
  status, missing troubleshooting, or issue-template improvements.
- `daily-use friction`: small setup hints, empty states, copy-flow confusion,
  or failure messages that are concrete and testable.
- `runtime-breadth request`: custom command profiles, new adapters, runtime
  version checks, endpoint polling, or second-runtime support.
- `out-of-scope request`: chat, model downloads, model catalogs, RAG, tools,
  proxy behavior, LAN exposure, authentication, runtime installation,
  automatic updates, package-manager mutation, or marketplace behavior.

When reporting a triage result, prefer:

```text
Classification:
Recommended action:
Human approval needed:
Verification:
Confidence:
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
- improve small empty-state, setup-hint, copy-flow, or error-message wording
  when the current docs or issue text identify the ambiguity
- record a known blocker or verified no-op when no safe slice exists

Automation should not keep adding adapter-boundary tests after v0.3 close-out
unless a new issue, regression, or design note identifies the missing case.

## Human-Approval-Only Work

Require explicit human handoff before:

- adding a new runtime adapter
- starting custom command profile implementation
- changing the runtime profile schema version
- changing GitHub visibility, branch protection, collaborators, secrets,
  webhooks, Actions settings, tags, GitHub Releases, release assets, or
  repository packages
- publishing packaged `.app`, zip, dmg, signing, notarization, checksums, or
  binary distribution claims
- automatically replying to, labeling, closing, or otherwise mutating public
  GitHub issues
- changing the saved automation cadence
- adding networked runtime version checks
- adding runtime install, update, model download, model catalog, proxy, LAN
  exposure, authentication, multiple-profile management, launch-at-login, or
  automatic restart behavior
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
