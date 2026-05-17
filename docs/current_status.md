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
- Bounded in-memory log buffering with clear-log behavior covered by focused
  core tests.
- Basic runtime/model path preflight before launching.
- Local endpoint and environment snippet display.
- AI Mobile / OpenAI-compatible chat-completions smoke command display.
- Local endpoint health-check URL and copyable curl smoke command display.
- Manual endpoint health status check using the local health-check URL.
- Endpoint health failures distinguish common connection and timeout cases with
  focused tests.
- Launch configuration errors point to the next setup action before launch, with
  focused tests for the user-facing descriptions.
- Runtime/model file preflight errors point to the binary permission or missing
  `.gguf` file action before launch, with focused tests for the descriptions.
- Process-run launch failures now preserve the system error while pointing to
  the selected `llama-server` binary, permissions, or Mac binary mismatch, with
  focused tests for the descriptions.
- App bundle launch helper at `script/build_and_run.sh`.
- App smoke cleanup helper: `--verify` closes the app on exit, and `--stop`
  can close a leftover `HazakuraLLMManager` process.
- Unit tests for command tokenization, adapter behavior, and configuration
  storage, including invalid numeric options, endpoint snippet generation, and
  quoted command preview display, bounded log buffering, clear-log behavior,
  plus the copied client and health smoke commands and manual health checker.
- Focused adapter validation tests for missing runtime/model paths and invalid
  context size, including unsupported model file types and launch-configuration
  error descriptions before launch command construction.

## Development Baseline

Use:

```bash
swift test
swift build --disable-sandbox
```

Use `./script/build_and_run.sh --verify` only when a macOS launch smoke check is
needed. It builds an app bundle under `dist/`, which is a local artifact, and
it closes the app before the script exits. If a manual smoke leaves the app
open, use `./script/build_and_run.sh --stop`.

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

Additional 2026-05-17 diagnostics: signing the completed bundle can make
`codesign --verify --deep --strict` pass, and a top-level
`open -n /absolute/path/to/Hazakura Lantern.app` launch request can be accepted.
However, the helper still fails when `open` is invoked from inside the shell
script after rebuilding the bundle. Treat this as a Launch Services invocation
or cache-context issue, not proof that the Mach-O executable is actually absent.

## Known Constraints

- The project is a Git repository tracking `origin/main` at
  `https://github.com/lero003/hazakura-lantern.git`.
- No real `llama-server` binary or `.gguf` model is bundled.
- There is no automatic endpoint health polling yet. The health-check URL, a
  fail-fast curl command, and a manual status check are available for local
  smoke checks.
- Runtime setup and update awareness should remain advisory. The app should not
  install, upgrade, or mutate runtimes automatically.
- The app does not manage multiple profiles, launch-at-login, YAML import/export,
  auto restart, model downloads, chat, RAG, or proxy behavior.
- LAN exposure and authentication are intentionally outside v0.

## Automation Lane

The automation should treat the project as v0 / v0.1 transition. The v0
control loop is mostly in place, while the Launch Services helper smoke remains
a documented blocker. Do not spend every hourly run retrying the same
`kLSNoExecutableErr` path unless there is a new hypothesis. It is acceptable to
carry that blocker as risk and advance into v0.1 daily-use confidence work that
does not depend on app-bundle launch verification.

The saved automation may continue later into v0.2 when `docs/development_loop.md`
and `docs/roadmap.md` lane handoff criteria are satisfied. v0.2 should start
with local profile contract and portability, not runtime breadth.

## Next Best Slice

Good next automated candidates:

- diagnose why Launch Services reports `kLSNoExecutableErr` for the generated
  app bundle only if there is a fresh hypothesis beyond the attempts above
- improve endpoint health status presentation without adding automatic polling
- tighten copied client smoke / endpoint reuse flows
- document runtime setup expectations without adding installer behavior
- harden restart behavior if stop/start races are observed
- add small profile-contract tests or docs when v0.1 confidence work is quiet,
  keeping v0.2 local and persistence-focused

Do not begin adapter expansion, model management, or chat features during this
handoff.
