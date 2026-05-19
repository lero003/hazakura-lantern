# Current Status

Last reviewed: 2026-05-19

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
- Restart requests now show an explicit `Restarting` state while Lantern waits
  for the current process to terminate before starting the next one.
- Bounded in-memory log buffering with clear-log behavior covered by focused
  core tests.
- Basic runtime/model path preflight before launching.
- Local endpoint and environment snippet display.
- Copied endpoint/client URLs keep local defaults copyable while respecting a
  configured reachable host, with focused tests.
- AI Mobile / OpenAI-compatible chat-completions smoke command display.
- Local endpoint health-check URL and timeout-bounded copyable curl smoke
  command display.
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
- Runtime file preflight now distinguishes a missing selected `llama-server`
  binary from an existing but non-executable file before process launch, with
  focused tests.
- Runtime/model file preflight now rejects directory selections before process
  launch, so a folder named like a binary or `.gguf` model does not fall
  through to a later runtime failure.
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
- Runtime profile imports now surface local advisory portability warnings for
  missing runtime/model file references, non-executable runtime paths, model
  directories, and non-`.gguf` model paths without copying or auto-fixing local
  files.
- Runtime profile documents can build an adapter-scoped launch command preview
  without applying the profile as active configuration, with focused mismatch
  tests.
- Runtime profile command preview is covered through a test-only matching
  adapter, so the profile preview contract is not pinned to `LlamaServerAdapter`
  before runtime breadth is intentionally added.
- Runtime profile `runtimeKind` remains pinned to the implemented adapter id,
  with a focused test guarding the `llama-server` profile/adapter boundary.
- Active runtime profile documents can be persisted through the configuration
  store; missing or unsupported future profile data falls back to the current
  single-runtime configuration instead of breaking startup, with focused tests.
- The app loads the active runtime profile into the editable configuration and
  provides minimal `.lantern-profile.json` import/export UI for that active
  profile without adding multiple-profile management.
- Endpoint display, environment snippets, timeout-bounded health-check curl,
  and AI Mobile smoke commands now flow through an adapter-owned
  `RuntimeEndpoint` contract, with focused tests preserving the `llama-server`
  endpoint/health behavior.
- Adapter-owned health endpoints can carry an adapter-scoped health-check curl
  timeout through `RuntimeEndpoint`, with focused tests preserving the default
  five-second timeout.
- Manual endpoint health checks now honor the adapter-scoped health-check
  timeout, keeping the actual request aligned with the copied curl smoke
  command.
- Adapter-owned environment snippets shell-quote adapter-scoped base URL and API
  key values when needed, while keeping the default local snippet readable.
- Runtime adapter validation is now an explicit adapter contract that can be
  tested before command construction, preserving the current `llama-server`
  validation behavior without adding runtime breadth.
- Runtime adapter default preflight and endpoint URL helpers are covered with a
  minimal adapter test, so future adapters can inherit the protocol defaults
  without `llama-server` assumptions.
- `llama-server` launch preflight is owned by the adapter boundary: executable
  and model file checks are tested before process launch while preserving the
  existing UI controller behavior.
- Adapter-owned endpoint construction is fallible and rejects invalid
  host/port values instead of force-unwrapping URL construction; the endpoint
  view and manual health check surface the validation error without adding
  runtime breadth.
- `llama-server` launch command construction normalizes blank profile host
  values to the default loopback host and trims configured hosts before launch,
  keeping imported profile endpoint display and process arguments aligned.
- `llama-server` launch command construction unwraps bracketed IPv6 host values
  before passing them to `--host`, while copied endpoint URLs keep URL-safe
  brackets.
- Copied endpoint URLs now treat bracketed IPv6 bind-all (`[::]`) as a local
  default, keeping client snippets copyable as `localhost` while launch still
  passes `::` to `llama-server`.
- `llama-server` host validation rejects URL-like, URL-delimiter, malformed
  bracket, or `host:port` values before command construction, while still
  allowing valid IPv6 literals for launch and copied endpoint URLs.
- `llama-server` host validation now also rejects malformed DNS labels such as
  underscores, empty labels, or leading/trailing hyphens before command
  construction, while keeping ordinary DNS hosts valid for endpoint reuse.
- `llama-server` host validation now rejects invalid IPv4-like dotted quads
  before command construction instead of treating them as DNS names, while
  preserving valid IPv4 hosts for endpoint reuse.
- Runtime process-run failure descriptions now flow through the runtime adapter
  boundary, preserving the current `llama-server` recovery hints while keeping
  the default protocol behavior free of `llama-server` assumptions.
- Default runtime adapter launch-failure descriptions use the adapter display
  name for common POSIX failures, with focused tests proving the protocol
  fallback does not drift back to `llama-server` wording.
- Runtime adapter responsibilities and lifecycle boundaries are documented so
  future adapter work starts with protocol clarity rather than runtime breadth.
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
  timeout-bounded curl command, and a manual status check are available for
  local smoke checks.
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
  adapter-owned launch preflight slice or missing-runtime-file preflight slice
  or runtime/model directory preflight slice
  or default adapter preflight/helper slice or process-run
  failure-description slice or blank-host launch normalization slice or
  bracketed-IPv6 launch-host normalization slice or host-with-port validation
  slice or bracketed-IPv6 bind-all endpoint copy slice or
  URL-delimiter/stray-bracket host validation slice or DNS-label host
  validation slice or invalid-IPv4-like host validation slice or
  adapter-contract documentation slice or
  default-adapter POSIX launch-failure display-name slice or
  profile-runtime-kind adapter id alignment slice or
  adapter-scoped health-check timeout propagation slice or
  adapter-scoped environment-snippet shell-quoting slice or
  manual health-check request timeout propagation slice
- harden restart behavior only if a new stop/start race or ambiguous restart
  state is observed beyond the explicit pending-restart status
- improve a copy flow, empty state, or setup hint only when there is a concrete
  repeated-use ambiguity; keep the slice local and small, and do not repeat the
  timeout-bounded health-check curl slice
- diagnose why Launch Services reports `kLSNoExecutableErr` for the generated
  app bundle only if there is a fresh hypothesis beyond the attempts above,
  such as proving `CFBundleExecutable` / `Contents/MacOS` consistency on the
  newly generated bundle or testing Launch Services cache behavior outside the
  normal hourly loop
- add profile migration transform tests only after a concrete schema version `2`
  shape exists

Do not begin endpoint auto-polling, runtime version checks, multiple-profile
management, adapter expansion, model management, or chat features during this
handoff.
