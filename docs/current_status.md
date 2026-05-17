# Current Status

Last reviewed: 2026-05-18

## Project State

Hazakura Lantern is an early macOS SwiftUI app for supervising a local
`llama-server` process from `llama.cpp`.

Implemented scope:

- SwiftPM package with macOS 14 minimum.
- SwiftUI app target plus a small core library target.
- Runtime configuration stored in `UserDefaults`.
- Recent runtime executable and model path lists stored separately from the
  active runtime configuration.
- `llama-server` launch command construction without shell interpolation.
- Copyable launch command preview for terminal inspection.
- Start, stop, restart, process id, status, and in-memory stdout/stderr logs.
- Bounded in-memory log buffering with clear-log behavior covered by focused
  core tests.
- Basic runtime/model path preflight before launching.
- Local endpoint and environment snippet display.
- Copied endpoint/client URLs keep local defaults copyable while respecting a
  configured reachable host, with focused tests.
- AI Mobile / OpenAI-compatible chat-completions smoke command display.
- Local endpoint health-check URL and copyable curl smoke command display.
- Manual endpoint health status check using the local health-check URL.
- Endpoint health status resets when the runtime starts, stops, or terminates
  so a stale healthy result is not shown as current process state.
- Endpoint health status presentation has a core icon/tone contract used by the
  SwiftUI endpoint view and covered by focused tests.
- Endpoint health failures distinguish common connection and timeout cases with
  focused tests.
- Launch configuration errors point to the next setup action before launch, with
  focused tests for the user-facing descriptions.
- Runtime/model file preflight errors point to the binary permission or missing
  `.gguf` file action before launch, with focused tests for the descriptions.
- Process-run launch failures now preserve the system error while pointing to
  the selected `llama-server` binary, permissions, or Mac binary mismatch, with
  focused tests for the descriptions.
- Initial v0.2 runtime profile document contract with schema version `1`,
  runtime kind, and embedded runtime configuration; unsupported schema versions
  are rejected by focused tests before profile file UI or persistence behavior
  is added.
- Runtime profile documents can now be exported as stable, readable JSON data
  and imported through the same schema-version guard, with focused tests.
- Runtime profile JSON import reports missing or unsupported schema versions
  through typed errors so future migration UI can recover without string
  matching decoder failures.
- Runtime profile JSON import rejects missing or unsupported runtime kinds
  through typed errors, keeping profile file handling on the current
  `llama-server` boundary until adapter work is explicit.
- Runtime profile documents provide a stable suggested export filename using
  `.lantern-profile.json`, with focused tests for sanitizing local profile
  names before file-based UI is added.
- Runtime profile documents recognize `.lantern-profile.json` filenames and
  URLs for future file-based import UI, with focused tests.
- Runtime profile JSON can be imported through a profile-file helper that
  validates the `.lantern-profile.json` suffix before decoding contents, with
  focused tests for supported names and unsupported ordinary JSON files.
- Runtime profile documents expose their runtime executable and model file
  references for future portability warnings without checking or copying local
  files, with focused tests.
- Runtime profile documents can build an adapter-scoped launch command preview
  without applying the profile as active configuration, with focused mismatch
  tests.
- Active runtime profile documents can be persisted through the configuration
  store; missing or unsupported future profile data falls back to the current
  single-runtime configuration instead of breaking startup, with focused tests.
- Runtime profile JSON shape, import failure behavior, and portability
  boundaries are documented with a readable schema-version `1` example.
- App bundle launch helper at `script/build_and_run.sh`.
- App smoke cleanup helper: `--verify` closes the app on exit, and `--stop`
  can close a leftover `HazakuraLLMManager` process.
- Compact troubleshooting guide for setup, endpoint health, app-bundle smoke,
  and source-only alpha release boundaries.
- Unit tests for command tokenization, adapter behavior, and configuration
  storage, including invalid numeric options, endpoint snippet generation, and
  quoted command preview display, copied endpoint host behavior, bounded log
  buffering, clear-log behavior, endpoint health status presentation, plus the
  copied client and health smoke commands, manual health checker, and a
  real-model-free fake runtime smoke test for launch command execution.
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

The project may proceed with v0.1 daily-use confidence work under this known
Launch Services risk, but no user-facing v0 app-bundle release should be cut
until app launch verification succeeds on a normal macOS environment.

The saved automation may continue later into v0.2 and v0.3 when
`docs/development_loop.md` and `docs/roadmap.md` lane handoff criteria are
satisfied. v0.2 should start with local profile contract and portability, not
runtime breadth. v0.3 should clarify adapter boundaries before adding another
runtime adapter.

## Next Best Slice

Good next automated candidates:

- diagnose why Launch Services reports `kLSNoExecutableErr` for the generated
  app bundle only if there is a fresh hypothesis beyond the attempts above
- improve endpoint health status presentation further only when there is a
  concrete stale-status or ambiguity case, without adding automatic polling
- document runtime setup expectations without adding installer behavior
- harden restart behavior if stop/start races are observed
- add small profile-contract tests or docs when v0.1 confidence work is quiet,
  keeping v0.2 local and persistence-focused; the initial schema-version
  document contract, JSON encoding helpers, typed import-schema/runtime-kind
  failures, active profile persistence fallback, profile JSON shape docs, and
  suggested export filename, supported profile filename, and local file
  reference, profile-file import preflight, and adapter-scoped launch-command
  preview contracts are covered; prefer profile file UI behavior beyond
  filename/import preflight or
  migration transform tests once a concrete v2 shape exists

Do not begin adapter expansion, model management, or chat features during this
handoff.
