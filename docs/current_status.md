# Current Status

Last reviewed: 2026-05-16

## Project State

Hazakura Lantern is an early macOS SwiftUI app for supervising a local
`llama-server` process from `llama.cpp`.

Implemented scope:

- SwiftPM package with macOS 14 minimum.
- SwiftUI app target plus a small core library target.
- Runtime configuration stored in `UserDefaults`.
- `llama-server` launch command construction without shell interpolation.
- Start, stop, restart, process id, status, and in-memory stdout/stderr logs.
- Basic runtime/model path preflight before launching.
- Local endpoint and environment snippet display.
- App bundle launch helper at `script/build_and_run.sh`.
- Unit tests for command tokenization, adapter behavior, and configuration
  storage.

## Development Baseline

Use:

```bash
swift test
swift build --disable-sandbox
```

Use `./script/build_and_run.sh --verify` only when a macOS launch smoke check is
needed. It builds an app bundle under `dist/`, which is a local artifact.

## Known Constraints

- The project directory is not currently a Git repository.
- No real `llama-server` binary or `.gguf` model is bundled.
- There is no endpoint health polling yet, even though the adapter can provide a
  health check URL.
- The app does not manage multiple profiles, launch-at-login, YAML import/export,
  auto restart, model downloads, chat, RAG, or proxy behavior.
- LAN exposure and authentication are intentionally outside v0.

## Next Best Slice

The most useful next automated slice is a focused correctness or test hardening
change inside the existing v0 boundary. Good candidates:

- test invalid numeric options for threads and GPU layers
- test command preview behavior for quoted additional arguments
- harden restart behavior if stop/start races are observed
- add endpoint health status only if kept local and read-only

Do not begin adapter expansion, model management, or chat features until the v0
control loop is stable.
