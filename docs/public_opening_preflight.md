# Public Opening Preflight

This checklist is for preparing Hazakura Lantern before the GitHub repository
is made public. It is not the public-opening command itself.

Status: this checklist was used for the `v0.3.0-alpha.1` source-only public
opening. Keep it as a pre-open and release-handoff reference. For ongoing
public issue triage and automation guidance, use
`docs/post_public_operations.md`.

The automation may work through this checklist after the v0.3 adapter-boundary
lane is mostly quiet, or earlier only when a documentation or release-boundary
gap would mislead future public readers.

## Hard Stop

Do not change repository visibility, branch protection, collaborators, secrets,
webhooks, GitHub Actions settings, tags, GitHub Releases, or release assets
without an explicit human handoff for that exact public-opening action.

Do not publish a packaged `.app`, zip, dmg, signing, or notarization claim until
the app-bundle launch smoke succeeds on a normal macOS environment.

## Automation-Ready Preparation

An automated run may complete one small, verifiable preparation slice:

- make README, current status, roadmap, troubleshooting, changelog, and runtime
  docs agree on the source-only checkpoint and packaged-app blocker
- keep install and build instructions honest: SwiftPM source build is supported;
  packaged app distribution is not yet claimed
- keep non-goals visible: no chat, model download, proxy, LAN exposure,
  authentication, runtime installer, updater, bundled inference, or marketplace
- inspect workflow files statically for surprising triggers, broad token
  permissions, unpinned or unexpected external actions, or secret-printing
  patterns
- inspect manifests, scripts, and docs statically for `curl | sh`, package
  manager mutation, installer claims, release-asset claims, or local-only paths
  that should not be public instructions
- add or tighten public issue/reporting guidance only when it asks for safe
  artifacts such as command preview, logs, adapter id, profile schema version,
  and reproduction steps
- add release notes or changelog entries for main-branch work without creating
  tags or GitHub Releases

Static review means reading repository files and GitHub workflow text. It does
not mean installing dependencies, running package lifecycle scripts, dumping
environment variables, reading secret values, or changing remote settings.

## Last Local Static Review

2026-05-19 local/static pass:

- Reviewed `.github/workflows/ci.yml`, `.github/ISSUE_TEMPLATE/bug_report.yml`,
  `Package.swift`, `script/build_and_run.sh`, README, changelog, and docs.
- CI is limited to `pull_request` and `push` on `main` with read-only
  `contents` permission.
- No committed public instructions were found that ask users to run `curl | sh`,
  mutate package managers, claim packaged `.app` distribution, or publish
  GitHub Release assets.
- The known `kLSNoExecutableErr` app-bundle launch-smoke blocker remains
  visible as a packaged-release blocker.

## Last Local Verification Baseline

2026-05-19 local verification pass:

- `swift test` passed in the Codex environment with 129 XCTest tests.
- `swift build --disable-sandbox` passed in the Codex environment.
- This did not run `./script/build_and_run.sh --verify`; the known
  `kLSNoExecutableErr` app-bundle launch-smoke blocker remains unresolved.

## Pre-Open Checklist

Before asking a human to make the repository public, confirm:

- `git status --short --branch` is clean and local `main` matches `origin/main`
- `swift test` passes
- `swift build --disable-sandbox` passes in the Codex environment
- `git diff --check` passes
- README states the current source-only checkpoint and does not imply a packaged
  app artifact exists
- README and the top-level `LICENSE` state the repository source license, while
  external runtimes and local model files remain under their own licenses
- CHANGELOG has an `Unreleased` section and latest source checkpoint entry
- docs clearly separate source-only checkpoints or release candidates from
  packaged releases
- `.github/workflows/` does not use surprising privileged triggers or broad
  permissions for the current project shape
- no committed docs or scripts ask users to pipe remote scripts into a shell
- no generated artifacts such as `.build/`, `dist/`, app bundles, logs, or
  temporary Habitat reports are staged
- the known `kLSNoExecutableErr` launch-smoke blocker is still visible unless it
  has been fixed or externally verified
- if a GitHub Release is proposed, it is prerelease/source-only unless the
  packaged-app launch smoke has been verified

## Handoff Output

When the checklist is ready, report a concise public-opening brief:

- current checkpoint and commit hash
- verification commands and results
- docs that establish source-only or packaged-release status
- known blockers and non-goals
- static workflow/security notes
- exact actions still requiring human approval, such as visibility change,
  branch protection, GitHub settings, tags, or releases
