# Current Status

Last reviewed: 2026-05-21

## Project State

Hazakura Lantern is an early macOS SwiftUI app for supervising a local
`llama-server` process from `llama.cpp`.

Current release checkpoint: `v0.9.0-alpha.1` is a public source-only alpha for
release-quality UI, menu bar, toolbar, localization, setup guidance, and
non-mutating `llama-server` update-readiness work. It is not a packaged app
release.

Implemented scope:

- SwiftPM package with macOS 14 minimum.
- SwiftUI app target plus a small core library target.
- Runtime configuration stored in `UserDefaults`.
- Runtime executable and model selections are stored in the active runtime
  configuration; the Configuration view keeps path rows compact by omitting
  recent-path menus.
- Installed `llama-server` discovery observes executable files from PATH plus
  common Homebrew and MacPorts binary locations, surfacing them as selectable UI
  choices without running package-manager commands.
- Settings now includes a System / Japanese / English language toggle for UI
  labels and controls only; runtime logs, command text, profile data, and
  adapter-owned messages remain outside the localization scope.
- Settings now shows the current source checkpoint and makes the source-only,
  no-packaged-app boundary visible inside the app without adding release assets.
- HelpTooltip explanation button accessibility and help text now follows the
  selected app UI language while leaving adapter-owned diagnostics unchanged.
- `llama-server` launch command construction without shell interpolation.
- Copyable launch command preview for terminal inspection.
- Start, stop, restart, process id, status, and in-memory stdout/stderr logs.
- Restart requests now show an explicit `Restarting` state while Lantern waits
  for the current process to terminate before starting the next one.
- Runtime termination logs and error text distinguish normal exit codes from
  signal-based termination.
- Expected Stop and Restart termination logs now say the requested action
  completed instead of making a normal `SIGTERM` look like an unexpected crash.
- Bounded in-memory log buffering with clear-log behavior covered by focused
  core tests.
- Runtime log rows expose a combined accessibility label for the stream and
  message so assistive reading keeps each entry together.
- Basic runtime/model path preflight before launching.
- Local endpoint and environment snippet display.
- Blank runtime or model selections now show a setup hint before start, so the
  empty state points to the next local selection step without installing or
  downloading anything.
- Non-`.gguf` model selections now show a setup hint before start, so an
  unsupported local model file is explained without adding conversion or
  download behavior.
- Invalid numeric launch settings now show a setup hint before start, so port,
  context size, threads, and GPU layers point to the required local value
  without waiting for a failed launch attempt.
- Invalid host values now show a setup hint before start, so endpoint-copy and
  launch-host mistakes are explained before a failed launch attempt.
- Malformed Additional Args quoting now shows a setup hint before start, so
  launch argument typos can be fixed before a failed launch attempt.
- Copied endpoint/client URLs keep local defaults copyable while respecting a
  configured reachable host, with focused tests.
- AI Mobile / OpenAI-compatible chat-completions smoke command display.
- Copied AI Mobile / OpenAI-compatible client smoke commands are fail-fast and
  timeout-bounded so a local client check does not hang indefinitely.
- Local endpoint health-check URL and timeout-bounded copyable curl smoke
  command display.
- Manual endpoint health status check using the local health-check URL.
- Endpoint health status resets when the runtime starts, stops, or terminates
  so a stale healthy result is not shown as current process state.
- Endpoint health status presentation has a core icon/tone contract used by the
  SwiftUI endpoint view and covered by focused tests.
- Healthy endpoint status detail now states that the manual check is a snapshot
  rather than automatic polling.
- Endpoint health failures distinguish common connection and timeout cases with
  focused tests.
- Endpoint health non-success HTTP responses now include the checked URL and
  point users toward model-load completion or runtime logs.
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
  missing runtime/model file references, runtime executable directories,
  non-executable runtime paths, model directories, and non-`.gguf` model paths
  without copying or auto-fixing local files.
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
- Runtime Profile import/export buttons now expose explicit accessibility
  labels and hints that name the active `.lantern-profile.json` file flow
  without changing profile behavior.
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
- Runtime adapter docs now distinguish child-process, external-service, and
  custom-command lifecycle classes before future adapter breadth begins.
- Runtime profile JSON shape, import failure behavior, and portability
  boundaries are documented with a readable schema-version `1` example.
- CI workflow permissions are pinned to read-only repository contents for the
  SwiftPM verification job.
- Public repository hygiene now includes local CODEOWNERS coverage for
  repository-critical files, a SHA-pinned checkout action in CI, weekly
  Dependabot version-update proposals for GitHub Actions and SwiftPM manifests,
  and ignore rules for common local secret or credential files. This does not
  change remote repository settings or apply public labels.
- Public bug-report guidance now asks for reproduction steps, runtime adapter
  id, profile schema version, command previews, and redacted logs while keeping
  chat, model download, proxy, LAN exposure, authentication, runtime installer,
  and packaged-app requests outside the current source-only alpha boundary.
- Local/static public-opening review has checked workflow, issue-template,
  manifest, script, README, changelog, and docs guidance for surprising CI
  triggers or permissions, `curl | sh`, package-manager mutation, packaged-app
  distribution claims, and release-asset claims without changing remote GitHub
  settings.
- Local verification baseline has run `swift test` and
  `swift build --disable-sandbox` successfully; the current 2026-05-21 local
  app-bundle helper smoke regressed with `kLSNoExecutableErr` in this Codex
  environment.
- App bundle launch helper at `script/build_and_run.sh`.
- App smoke cleanup helper: `--verify` closes the app on exit, and `--stop`
  can close a leftover `HazakuraLLMManager` process.
- Compact troubleshooting guide for setup, endpoint health, app-bundle smoke,
  and source-only alpha release boundaries.
- Troubleshooting now includes local file checks for confirming the selected
  `llama-server` executable and `.gguf` model before widening runtime scope.
- Post-public operations guidance for issue triage, automation-safe work,
  human approval gates, and packaged-release separation.
- Post-public triage guidance now includes local label proposals and safe draft
  response shapes that automation can prepare without mutating public issues.
- Post-public `llama-server` triage guidance now separates Lantern-owned
  behavior from runtime-owned behavior before proposing a local fix.
- llama-server preset guidance now defines v0.6/v0.7 as model-family
  recommendation, option compatibility, and runtime capability advisory work
  before any second runtime adapter.
- Core `llama-server` presets now model Standard, Qwen Recommended, and Gemma
  Recommended settings as visible configuration values and additional launch
  arguments, keeping model-family guesses small and reviewable.
- The server configuration view now lets users choose a `llama-server` preset,
  review its context/thread/GPU/additional-argument summary, and apply it to
  the active configuration while preserving the selected runtime, model, host,
  and port.
- Local `llama-server` capability probing can now run timeout-bounded
  `--version` and `--help` checks without model launch or runtime mutation,
  parse supported option names, and report preset options that appear
  unsupported by the selected runtime.
- The server configuration view now offers a manual runtime capability check
  that displays the selected `llama-server` version when available and shows
  supported, unsupported, or unknown preset-option advisory text before launch.
- Advanced Settings and Advanced Connection Details now use full-row clickable
  disclosure headers, so the text label and surrounding row open the section.
- Advanced Settings accepts context sizes up to 1,048,576 tokens through the
  slider and direct field, while help text now makes clear that threads and GPU
  layers are delegated to `llama-server` when set to auto rather than measured
  from the Mac by Lantern.
- The Logs destination now stretches its log area vertically and top-aligns
  empty and populated log content, making the view behave like a working log
  surface instead of a short centered panel.
- The main window now has a native toolbar shell for the existing start, stop,
  restart, and manual endpoint health-check actions, with availability derived
  from the same controller state as the in-page controls.
- The main window toolbar now exposes copy actions for the existing launch
  command, endpoint, environment, health-check, and AI Mobile smoke snippets
  without changing runtime behavior.
- Existing UI copy actions now write to the pasteboard through one shared app
  helper, keeping toolbar, menu bar, endpoint, command-preview, and Setup Guide
  copy behavior aligned without changing copied values.
- The main window toolbar now exposes active runtime profile import/export
  actions that reuse the existing `.lantern-profile.json` file flow without
  adding multiple-profile management.
- The main window toolbar now exposes clear-log behavior using the existing
  in-memory log reset path, disabled when there are no logs.
- The main window toolbar now exposes a command-preview action that opens the
  dashboard command preview without changing runtime behavior.
- A menu bar control surface now mirrors the existing server lifecycle, health,
  copy, active-profile import/export, log clear, open-window, and quit actions
  while keeping the app as a regular Dock/windowed app.
- Menu bar copy action labels now match the toolbar copy menu for environment,
  health-check, and AI Mobile smoke snippets without changing copied values.
- The server configuration view now shows non-mutating install-source advice for
  selected `llama-server` paths that look Homebrew-managed, MacPorts-managed,
  source-checkout-built, or manual, while keeping update execution outside
  Lantern.
- The server configuration view now shows non-mutating update-readiness dry-run
  guidance that combines selected runtime source with local version/help
  capability evidence before any future guarded update plan can be prepared.
- Manual-path update-readiness guidance now explicitly keeps unsupported update
  sources outside Lantern's future guarded update planning, with focused tests.
- Incomplete update-readiness dry-run guidance now names the missing local
  `--version` or `--help` evidence, so a guarded update plan is not prepared
  from a generic "capability incomplete" state.
- The main window now uses a sidebar-based layout with Dashboard,
  Configuration, and Logs destinations. Setup Guide is a toolbar-toggled
  inspector that opens automatically when runtime or model selection is empty,
  and the Dashboard setup hint can reveal it without changing runtime behavior.
- The Setup Guide model-search link no longer force-unwraps its static URL,
  removing the known app-UI crash edge from the automation smoke backlog.
- Setup Guide step headers now expose complete/incomplete accessibility values
  and hints while keeping decorative step indicators out of the reading order.
- Process status and endpoint health indicators now expose explicit
  accessibility labels and values while keeping decorative status artwork out of
  the reading order.
- Advanced configuration fields are now grouped behind disclosure controls, with
  context, thread, and GPU-layer sliders supplementing the existing editable
  values.
- menu bar/toolbar/navigation guidance now restores v0.8 as a native Mac
  control-surface lane before any second runtime adapter.
- update-readiness guidance now places v0.9/v1.0 on guarded `llama-server`
  update workflow work, with real runtime mutation requiring explicit user
  confirmation.
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

Current Codex launch-smoke status (2026-05-21 current run):
`./script/build_and_run.sh --verify` builds the bundle, but Launch Services
returns `kLSNoExecutableErr`. `./script/build_and_run.sh --stop` completes
afterward; a follow-up `pgrep -fl HazakuraLLMManager` check could not read the
process list because `sysmond` was unavailable in this environment. The
generated bundle contains `Info.plist`, the `HazakuraLLMManager` executable,
and English/Japanese localization resources under
`dist/Hazakura Lantern.app/Contents`.

Treat this as an automation-level launch-smoke regression, not a source-build
failure. It does not prove packaged-release readiness, and it should not block
source-only work that is verified through SwiftPM.

Historical 2026-05-17 diagnostics: re-signing the generated bundle with
`codesign --force --sign -`, adding standard bundle metadata, adding
`Contents/Resources`, and registering the app with `lsregister -f` did not
clear the Launch Services failure. `lsregister` still fails to scan the bundle
with `-10822`, while `open -W -n /System/Applications/Calculator.app` works in
the same environment. The blocker appears specific to the generated Lantern
bundle rather than a blanket inability to call Launch Services.

Additional historical 2026-05-17 diagnostics: signing the completed bundle can make
`codesign --verify --deep --strict` pass, and a top-level
`open -n /absolute/path/to/Hazakura Lantern.app` launch request can be accepted.
However, the helper can still fail when `open` is invoked from inside the shell
script after rebuilding the bundle. The 2026-05-21 current run reproduced that
failure even though the bundle executable and `CFBundleExecutable` value
matched.

## Known Constraints

- The project is a Git repository tracking `origin/main` at
  `https://github.com/lero003/hazakura-lantern.git`.
- No real `llama-server` binary or `.gguf` model is bundled.
- There is no automatic endpoint health polling yet. The health-check URL, a
  timeout-bounded curl command, and a manual status check are available for
  local smoke checks.
- Runtime setup and update awareness should remain advisory. The app should not
  install, upgrade, or mutate runtimes automatically.
- Model-family presets should remain advisory and visible. They may suggest
  `llama-server` settings or additional arguments, but they must not hide
  command construction or infer unsupported options silently.
- The app does not manage multiple profiles, launch-at-login, YAML import/export,
  auto restart, model downloads, chat, RAG, or proxy behavior.
- LAN exposure and authentication are intentionally outside v0.

## Automation Focus

The automation should treat version checkpoints as history, not as the work
queue. The useful question is whether the next slice moves Lantern closer to
release-quality daily use while preserving the current `llama-server` boundary.

No user-facing packaged release should be cut until the remaining release
quality gates below are resolved or explicitly deferred by a human.

Open release-quality gates:

- restore or externally verify the local app-bundle helper launch path, then
  complete a normal desktop/manual launch and clean-quit pass
- verify the menu bar daily-use path on a normal macOS desktop, including
  status visibility, lifecycle actions, copy actions, and `Open Window`
  behavior from hidden or backgrounded window states
- decide whether the toolbar remains a secondary power-user surface, is reduced,
  or is removed after the menu bar becomes the primary resident control surface
- review the Setup Guide inspector against the normal configuration flow so
  onboarding help does not duplicate or obscure the main window controls
- perform one manual UI smoke pass that covers main-window launch, Setup Guide
  inspector toggling, menu bar commands, toolbar commands, and clean quit
  behavior
- keep menu-bar-only lifecycle, launch-at-login, and automatic restart policy
  out of the release unless a later explicit product decision reopens them

Use `docs/automation_smoke_backlog.md` for pre-release rough-edge discovery and
small automatable polish. Use `docs/post_public_operations.md` for public issue
triage, automation-safe work, and human approval gates. Keep
`docs/public_opening_preflight.md` as a pre-open and release-handoff reference,
not as the normal work queue.

Closed source-work areas should stay closed unless a concrete regression or
release-quality ambiguity appears: adapter boundary documentation, core
`llama-server` launch/health validation, profile schema version `1`, the core
preset model and picker, the initial runtime capability advisory, and the
initial menu bar/toolbar/setup-guide surfaces.

Automation must not change GitHub visibility, settings, tags, releases, release
assets, repository packages, public issue state, automation cadence, a new
adapter, custom command implementation, profile schema version, dependencies,
runtime installation/update, model download, or hidden auto-optimization
without an explicit human handoff.

## Next Best Slice

Good next automated candidates:

- use `docs/automation_smoke_backlog.md` to expose or fix one concrete
  pre-release rough edge in UI labels, localization, menu bar/toolbar behavior,
  Setup Guide inspector flow, runtime setup, endpoint/health/copy/logs,
  profiles, packaging-prep, or non-mutating update-readiness
- classify public feedback or review notes with
  `docs/post_public_operations.md`, then make one safe local change only when
  the classification identifies a `llama-server` bug, profile import/export bug,
  docs confusion, or current-lane daily-use ambiguity
- verify menu bar daily-use gaps or decide toolbar demotion before adding any
  new control surfaces
- review the Setup Guide inspector against the normal Configuration flow and
  remove duplication or crowding if it is visible
- refine `llama-server` presets, runtime capability advisories, or
  update-readiness wording only when it reduces a concrete release-quality risk
  and remains advisory, visible, and non-mutating
- improve one `llama-server` reliability or daily-use path when the confusing
  behavior is concrete and testable: launch validation, launch failure wording,
  missing runtime/model file empty states beyond the blank or non-`.gguf`
  setup hints, endpoint/client snippets, health-check wording,
  restart/terminated/stopped state clarity, profile portability warnings,
  README, or troubleshooting beyond the local file-check guidance already
  covered; malformed Additional Args and invalid-host setup hints are already
  covered
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
  timeout-bounded health-check curl slice, numeric launch setup-hint slice, or
  malformed Additional Args setup-hint slice
- improve post-public docs hygiene when old pre-open or v0.3/v0.4 wording would
  steer automation toward already-completed visibility or reliability
  preparation
- re-diagnose historical `kLSNoExecutableErr` behavior only if helper smoke
  regresses or a fresh Launch Services hypothesis appears
- add profile migration transform tests only after a concrete schema version `2`
  shape exists

Do not begin endpoint auto-polling, multiple-profile management, adapter
expansion, custom command implementation, MLX implementation, model management,
unattended runtime installation/update, model download, automatic benchmarking,
or chat features during this handoff. Runtime version and option checks are
allowed only as local, timeout-bounded, read-only advisory work that improves
release quality. Guarded update execution must be opt-in and user-confirmed.
