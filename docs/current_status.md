# Current Status

Last reviewed: 2026-05-17

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
- AI Mobile / OpenAI-compatible chat-completions smoke command display.
- App bundle launch helper at `script/build_and_run.sh`.
- Unit tests for command tokenization, adapter behavior, and configuration
  storage, including invalid numeric options, endpoint snippet generation, and
  quoted command preview display, plus the copied client smoke command.
- Focused adapter validation tests for missing runtime/model paths and invalid
  context size.

## Development Baseline

Use:

```bash
swift test
swift build --disable-sandbox
```

Use `./script/build_and_run.sh --verify` only when a macOS launch smoke check is
needed. It builds an app bundle under `dist/`, which is a local artifact.

Current Codex launch-smoke status: `./script/build_and_run.sh --verify`
builds the bundle, but Launch Services reports `kLSNoExecutableErr` even though
`dist/Hazakura Lantern.app/Contents/MacOS/HazakuraLLMManager` exists and is
executable. Treat this as an unresolved launch-smoke blocker; do not count the
v0 app-launch exit criterion as satisfied until this is fixed or verified
outside the restricted Codex environment.

2026-05-17 follow-up diagnostics: re-signing the generated bundle with
`codesign --force --sign -`, adding standard bundle metadata, adding
`Contents/Resources`, and registering the app with `lsregister -f` did not
clear the Launch Services failure. `lsregister` still fails to scan the bundle
with `-10822`, while `open -W -n /System/Applications/Calculator.app` works in
the same environment. The blocker appears specific to the generated Lantern
bundle rather than a blanket inability to call Launch Services.

## Known Constraints

- The project is a Git repository tracking `origin/main` at
  `https://github.com/lero003/hazakura-lantern.git`.
- No real `llama-server` binary or `.gguf` model is bundled.
- There is no endpoint health polling yet, even though the adapter can provide a
  health check URL.
- Runtime setup and update awareness should remain advisory. The app should not
  install, upgrade, or mutate runtimes automatically.
- The app does not manage multiple profiles, launch-at-login, YAML import/export,
  auto restart, model downloads, chat, RAG, or proxy behavior.
- LAN exposure and authentication are intentionally outside v0.

## Next Best Slice

The most useful next automated slice is to resolve the launch-smoke blocker if
the environment allows it. If not, choose a focused correctness or test
hardening change inside the existing v0 boundary. Good candidates:

- diagnose why Launch Services reports `kLSNoExecutableErr` for the generated
  app bundle, starting beyond ad-hoc signing and minimal Info.plist checks
- document runtime setup expectations without adding installer behavior
- harden restart behavior if stop/start races are observed
- add endpoint health status only if kept local and read-only

Do not begin adapter expansion, model management, or chat features until the v0
control loop is stable.
