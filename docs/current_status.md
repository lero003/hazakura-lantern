# Current Status

Last reviewed: 2026-05-18

## Project State

Hazakura Lantern is an early macOS SwiftUI app for supervising a local
`llama-server` process from `llama.cpp`.

Current release checkpoint: `v0.2.0-alpha.1` is a source-only alpha for the
runtime profile contract and active-profile import/export UI. It is not a
packaged app release.

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
- Runtime profile files can be previewed through a typed envelope helper before
  full import, validating suffix, schema version, profile name, and runtime kind
  without requiring the full runtime configuration to decode.
- Runtime profile import and preview reject blank profile names as invalid, so
  future file UI does not present an unusable unnamed profile.
- Runtime profile documents expose their runtime executable and model file
  references for future portability warnings without checking or copying local
  files, with focused tests.
- Runtime profile documents can build an adapter-scoped launch command preview
  without applying the profile as active configuration, with focused mismatch
  tests.
- Runtime profile command preview is covered through a test-only matching
  adapter, so the profile preview contract is not pinned to `LlamaServerAdapter`
  before runtime breadth is intentionally added.
- Active runtime profile documents can be persisted through the configuration
  store; missing or unsupported future profile data falls back to the current
  single-runtime configuration instead of breaking startup, with focused tests.
- The app loads the active runtime profile into the editable configuration and
  provides minimal `.lantern-profile.json` import/export UI for that active
  profile without adding multiple-profile management.
- Endpoint display, environment snippets, health-check curl, and AI Mobile
  smoke commands now flow through an adapter-owned `RuntimeEndpoint` contract,
  with focused tests preserving the `llama-server` endpoint/health behavior.
- Runtime adapter validation is now an explicit adapter contract that can be
  tested before command construction, preserving the current `llama-server`
  validation behavior without adding runtime breadth.
- `llama-server` launch preflight is owned by the adapter boundary: executable
  and model file checks are tested before process launch while preserving the
  existing UI controller behavior.
- Adapter-owned endpoint construction is fallible and rejects invalid
  host/port values instead of force-unwrapping URL construction; the endpoint
  view and manual health check surface the validation error without adding
  runtime breadth.
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

The automation should treat the project as having a source-only v0.2 alpha
checkpoint for local profile portability, while the Launch Services helper
smoke remains a documented packaged-app blocker. Do not spend every hourly run
retrying the same `kLSNoExecutableErr` path unless there is a new hypothesis.
It is acceptable to carry that blocker as risk and continue with safe source
work that does not depend on app-bundle launch verification.

No user-facing app-bundle release should be cut until app launch verification
succeeds on a normal macOS environment.

The saved automation may continue into v0.3 when `docs/development_loop.md` and
`docs/roadmap.md` agree that the next smallest risk is adapter boundary
clarity. v0.3 should tighten adapter protocols, tests, and docs before adding
another runtime adapter.

## Next Best Slice

Good next automated candidates:

- tighten the adapter boundary when there is a concrete validation, error
  mapping or lifecycle case that can be tested without adding runtime breadth;
  do not repeat the initial explicit validation-contract slice or the
  profile-preview generic adapter-boundary test without a new ambiguity, and
  do not repeat the invalid endpoint host/port fallibility slice or
  adapter-owned launch preflight slice
- harden restart behavior only if a stop/start race or ambiguous restart state
  is observed
- improve a copy flow, empty state, or setup hint only when there is a concrete
  repeated-use ambiguity; keep the slice local and small
- diagnose why Launch Services reports `kLSNoExecutableErr` for the generated
  app bundle only if there is a fresh hypothesis beyond the attempts above
- add profile migration transform tests only after a concrete schema version `2`
  shape exists

Do not begin endpoint auto-polling, runtime version checks, multiple-profile
management, adapter expansion, model management, or chat features during this
handoff.
