# Changelog

All notable changes to Hazakura Lantern will be documented in this file.

## Unreleased

### Added

- Added post-public operations guidance for issue triage, automation-safe work,
  human approval gates, and packaged-release separation after the repository
  became public.
- Added post-public label proposals and draft response shapes that automation
  can prepare without mutating public GitHub issues.
- Added post-public `llama-server` ownership triage guidance so automation
  separates Lantern-owned fixes from runtime-owned behavior before acting.
- Added a start-time setup hint for blank runtime or model selections so the
  empty state points to the next local choice before launch.
- Added a start-time setup hint for non-`.gguf` model selections so unsupported
  local model files are called out before launch without adding conversion or
  download behavior.
- Added start-time setup hints for invalid numeric launch settings so port,
  context, threads, and GPU layers point to the required local value before
  launch.
- Added a start-time setup hint for invalid host values so launch-host and
  endpoint-copy mistakes are explained before a failed launch attempt.
- Added a start-time setup hint for malformed Additional Args quoting so users
  can fix launch arguments before a failed start attempt.
- Added a fail-fast, timeout-bounded copied client smoke curl command so local
  OpenAI-compatible checks do not hang indefinitely.
- Added troubleshooting guidance for locally checking the selected
  `llama-server` executable and `.gguf` model without adding installer or
  model-download behavior.

### Changed

- Clarified Stop and Restart termination log messages so expected process
  termination is not worded like an unexpected runtime crash.
- Clarified runtime termination logs and error text so signal-based termination
  is no longer described as a normal exit code.
- Clarified imported profile portability warnings when a saved runtime
  executable path points to a directory instead of a `llama-server` binary.
- Clarified manual endpoint health-check wording for non-success HTTP responses
  so users can verify model load completion or inspect runtime logs.
- Clarified the healthy endpoint status detail so manual checks read as a
  snapshot rather than automatic endpoint polling.
- Re-aligned the roadmap so v0.4 focuses on `llama-server` reliability,
  v0.5 on post-public issue triage, v0.6 on an MLX server design note, and
  v0.7 on MLX implementation only after explicit approval.
- Updated automation guidance so runs may continue through v0.5 when v0.4 has
  no concrete safe `llama-server` reliability slice.

## v0.3.0-alpha.1 - 2026-05-19

### Added

- Added public-opening preflight guidance so automation can prepare docs,
  workflow hygiene, and release-boundary checks before any GitHub visibility
  handoff.
- Added a public bug-report issue template that asks for reproduction steps,
  runtime/profile context, command previews, and redacted logs without widening
  Lantern beyond its source-only alpha boundary.

### Changed

- Tightened the CI workflow to declare read-only repository contents permission
  for SwiftPM verification.
- Recorded a local/static public-opening scan of workflow, issue-template,
  manifest, script, and docs guidance without changing remote GitHub settings.
- Recorded a local public-opening verification baseline for SwiftPM tests and
  build while keeping the packaged-app launch-smoke blocker explicit.
- Sanitized public agent guidance to avoid local home-directory paths and
  surfaced the known app-bundle smoke blocker in README local-development
  instructions.

### Known Issues

- `./script/build_and_run.sh --verify` can still fail with Launch Services
  `kLSNoExecutableErr` in the Codex environment. This checkpoint is source-only
  and does not attach a packaged `.app`, zip, dmg, signing, or notarization
  artifact.

## v0.2.0-alpha.1 - 2026-05-18

### Added

- Added runtime profile JSON helpers with schema version `1`, runtime kind, and
  embedded runtime configuration.
- Added typed import failures for missing or unsupported profile schema
  versions, runtime kinds, profile names, and unsupported profile file names.
- Added active runtime profile persistence fallback so unsupported future
  profile data does not break startup.
- Added profile export filename and `.lantern-profile.json` recognition
  contracts.
- Added profile import preview, local file reference reporting, and
  adapter-scoped launch command preview helpers.
- Added minimal active-profile import/export UI for `.lantern-profile.json`
  files without adding multiple-profile management.
- Added runtime profile documentation with a readable schema-version `1`
  example and portability boundaries.
- Added compact troubleshooting guidance for setup, endpoint health,
  app-bundle smoke, and source-only alpha release boundaries.

### Changed

- Adopted Nenrin for release, automation, and scope judgment while keeping
  ordinary implementation logs out of durable records.

### Known Issues

- `./script/build_and_run.sh --verify` can still fail with Launch Services
  `kLSNoExecutableErr` in the Codex environment. This checkpoint is source-only
  and does not attach a packaged `.app`, zip, dmg, signing, or notarization
  artifact.

## v0.1.0-alpha.1 - 2026-05-17

### Added

- Added macOS SwiftPM CI for `swift test` and `swift build --disable-sandbox`.
- Added a copy button for the generated launch command preview.
- Added a real-model-free fake runtime smoke test for adapter-built launch
  commands.
- Added recent runtime executable and model path menus, stored separately from
  the active runtime configuration.

### Changed

- Clarified that OpenAI-compatible endpoint URLs are provided by the selected
  runtime, not by a Lantern proxy layer.
- Reset endpoint health status when the runtime starts, stops, or terminates so
  stale healthy checks do not survive process state changes.
- Clarified that v0.1 daily-use confidence work may proceed while the
  `kLSNoExecutableErr` app-bundle launch-smoke issue remains a release blocker.

### Known Issues

- `./script/build_and_run.sh --verify` can still fail with Launch Services
  `kLSNoExecutableErr` in the Codex environment. Do not cut a user-facing app
  bundle release until launch verification succeeds on a normal macOS
  environment.
