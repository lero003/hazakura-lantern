# Changelog

All notable changes to Hazakura Lantern will be documented in this file.

## Unreleased

### Added

- Added compact troubleshooting guidance for setup, endpoint health,
  app-bundle smoke, and source-only alpha release boundaries.

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
