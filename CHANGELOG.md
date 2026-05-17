# Changelog

All notable changes to Hazakura Lantern will be documented in this file.

## Unreleased

### Added

- Added macOS SwiftPM CI for `swift test` and `swift build --disable-sandbox`.
- Added a copy button for the generated launch command preview.

### Changed

- Clarified that OpenAI-compatible endpoint URLs are provided by the selected
  runtime, not by a Lantern proxy layer.
- Clarified that v0.1 daily-use confidence work may proceed while the
  `kLSNoExecutableErr` app-bundle launch-smoke issue remains a release blocker.

### Known Issues

- `./script/build_and_run.sh --verify` can still fail with Launch Services
  `kLSNoExecutableErr` in the Codex environment. Do not cut a user-facing app
  bundle release until launch verification succeeds on a normal macOS
  environment.
