# Current Status

Last reviewed: 2026-05-22

## Project State

Hazakura Lantern is an early macOS SwiftUI app for supervising a local
`llama-server` process from `llama.cpp`.

Current release checkpoint: `v1.0.0-rc.1` is a public source-only release
candidate for personal/local use. It keeps the existing `llama-server` control
boundary and is not a packaged app release.

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
- The same language toggle is reachable inside the main window through the
  sidebar Settings destination, so changing app UI language does not require
  opening the separate macOS Settings scene.
- The embedded sidebar Settings view and Setup Guide inspector use compact
  widths so those utility surfaces do not crowd the main window.
- Settings now shows the current source checkpoint and makes the source-only,
  no-packaged-app boundary visible inside the app without adding release assets.
- The in-app source checkpoint identifier now comes from a tested core metadata
  value, keeping the source-only Settings display centralized without implying
  packaged artifacts.
- English/Japanese localization resources are covered by focused tests for
  duplicate keys, key parity, and format-placeholder parity, keeping app UI
  resource cleanup visible before broader localization work.
- HelpTooltip titles, descriptions, tips, and explanation-button accessibility
  text now follow the selected app UI language while leaving adapter-owned
  diagnostics unchanged.
- `llama-server` launch command construction without shell interpolation.
- Copyable launch command preview for terminal inspection.
- Start, stop, restart, process id, status, and in-memory stdout/stderr logs.
- Startup now shows an explicit `Loading Model` state after the child process
  starts, then moves to `Running` only after known `llama-server` readiness log
  text is observed.
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
- Manual endpoint health checks are disabled unless the server is running, so
  Lantern no longer treats stopped-state checks as raw configured-endpoint
  probes.
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
  and packaged-app requests outside the current source-only RC boundary.
- Local/static public-opening review has checked workflow, issue-template,
  manifest, script, README, changelog, and docs guidance for surprising CI
  triggers or permissions, `curl | sh`, package-manager mutation, packaged-app
  distribution claims, and release-asset claims without changing remote GitHub
  settings.
- Local source verification passed on 2026-05-22 17:49 JST with
  `git diff --check`, localization lint, `swift test` (194 XCTest tests,
  0 failures), and `swift build --disable-sandbox`; the current 2026-05-21
  local app-bundle helper smoke still stands as regressed with
  `kLSNoExecutableErr` in this Codex environment.
- App bundle launch helper at `script/build_and_run.sh`.
- App smoke cleanup helper: `--verify` closes the app on exit, and `--stop`
  can close a leftover `HazakuraLLMManager` process.
- Compact troubleshooting guide for setup, endpoint health, app-bundle smoke,
  and source-only release boundaries.
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
- Configuration preset guidance now uses English/Japanese app localization
  resources instead of always showing the Japanese helper description.
- Local `llama-server` capability probing can now run timeout-bounded
  `--version` and `--help` checks without model launch or runtime mutation,
  parse supported option names, and report preset options that appear
  unsupported by the selected runtime.
- The server configuration view now offers a manual runtime capability check
  that displays the selected `llama-server` version when available and shows
  supported, unsupported, or unknown preset-option advisory text before launch.
- Advanced Settings and Advanced Connection Details now use full-row clickable
  disclosure headers, so the text label and surrounding row open the section.
- Disclosure headers now expose localized expanded/collapsed accessibility
  values for English and Japanese app UI.
- Advanced Settings accepts context sizes up to 1,048,576 tokens through the
  slider and direct field, while help text now makes clear that threads and GPU
  layers are delegated to `llama-server` when set to auto rather than measured
  from the Mac by Lantern.
- Shared primary and secondary button styles now keep disabled labels and
  outlines visible, so inactive controls read as unavailable without vanishing
  into the glass surface.
- The decorative Aurora background pauses while the server is stopped, keeping
  the idle main window calmer without changing lifecycle behavior.
- The Logs destination now stretches its log area vertically and top-aligns
  empty and populated log content, making the view behave like a working log
  surface instead of a short centered panel.
- The Logs destination now states that runtime logs stay in memory and are not
  saved automatically, keeping log-retention behavior visible without adding
  persistence.
- The main window toolbar now exposes copy actions for the existing launch
  command, endpoint, environment, health-check, and AI Mobile smoke snippets
  without changing runtime behavior.
- Existing UI copy actions now write to the pasteboard through one shared app
  helper, keeping toolbar, menu bar, endpoint, command-preview, and Setup Guide
  copy behavior aligned without changing copied values.
- Endpoint destination copy controls now show transient copied feedback for the
  base URL, environment snippet, health-check curl, and AI Mobile smoke curl.
- The Dashboard launch command preview copy button now shows transient copied
  feedback after writing the command to the pasteboard.
- The main window toolbar Copy menu now shows transient copied feedback after
  writing the launch command, endpoint, environment snippet, health-check curl,
  or AI Mobile smoke curl to the pasteboard.
- Menu bar copy actions now show transient copied feedback after writing the
  launch command, endpoint, environment snippet, health-check curl, or AI Mobile
  smoke curl to the pasteboard.
- The main window toolbar now exposes active runtime profile import/export
  actions that reuse the existing `.lantern-profile.json` file flow without
  adding multiple-profile management.
- The toolbar Profile menu and menu bar controls now mirror active profile
  import/export file-flow messages, so export, import, and profile-warning
  results remain visible outside the Configuration profile panel.
- The main window toolbar is reduced to Setup Guide visibility, active profile
  import/export, and copy actions; server lifecycle, health, command reveal,
  and log clearing remain in the page content or menu bar.
- Main toolbar icon-only Setup Guide, profile import/export, and copy-menu
  controls now expose localized accessibility labels and hints while preserving
  the reduced toolbar scope.
- A menu bar control surface now mirrors the existing server lifecycle, health,
  copy, active-profile import/export, log clear, open-window, and quit actions
  while keeping the app as a regular Dock/windowed app.
- Menu bar copy action labels now match the toolbar copy menu for environment,
  health-check, and AI Mobile smoke snippets without changing copied values.
- Menu bar copy actions now expose localized accessibility hints for the launch
  command, endpoint, environment snippet, health-check curl, and AI Mobile
  smoke curl.
- The server configuration view now shows non-mutating install-source advice for
  selected `llama-server` paths that look Homebrew-managed, including
  `/opt/homebrew/bin` and `/usr/local/bin`, MacPorts-managed,
  source-checkout-built, or manual, while keeping update execution outside
  Lantern.
- The server configuration view keeps runtime diagnostics separate from presets
  and localizes install-source and capability-probe status text for
  English/Japanese app UI switching.
- The server configuration view now shows non-mutating update-readiness dry-run
  guidance that combines selected runtime source with local version/help
  capability evidence before any future guarded update plan can be prepared.
- The server configuration view now includes a selectable runtime update-check
  target, currently only `llama.cpp`, and a non-mutating Check for Updates
  action that reads the latest official GitHub release metadata and compares
  `bNNNN` build numbers when local version evidence is available.
- Update-readiness and update-check status text in the Configuration view now
  follows the selected English/Japanese app UI language while staying
  non-mutating and advisory.
- The Setup Guide now includes a manual Homebrew update command copy affordance
  for `llama.cpp`, matching the existing install-command style without running
  package-manager commands.
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
- The Setup Guide endpoint copy action now keeps its icon-only visual treatment
  while exposing a localized accessibility label and hint for the copied client
  connection URL.
- The Setup Guide now shows an explicit empty state when installed
  `llama-server` discovery finds no candidate, while keeping manual runtime
  selection available.
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

Current source-verification status (2026-05-22 20:49 JST hourly run):
`git diff --check`, English/Japanese `Localizable.strings` lint,
`swift test` (196 XCTest tests, 0 failures), and
`swift build --disable-sandbox` passed. App-bundle helper smoke was not rerun
in that slice because no fresh Launch Services hypothesis or normal desktop
verification environment was available.

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
- Runtime update availability checks are advisory and networked only when the
  user presses Check for Updates. Lantern does not run package-manager, Git,
  download, or binary replacement commands.
- LAN exposure and authentication are intentionally outside the current source
  release candidate.

## Automation Focus

The automation should treat version checkpoints as history, not as the work
queue. The useful question is whether the next slice moves Lantern closer to
release-quality daily use while preserving the current `llama-server` boundary.

Current human direction: `v1.0.0-rc.1` is the source-only RC for personal/local
use. Packaged app release remains separate: automation should continue
code-quality checks, narrow verified improvements, and packaged-release
readiness evidence, but should not create packaged artifacts, change GitHub
settings, mutate public issues, or decide packaged-release readiness by itself.

No user-facing packaged release should be cut until the remaining release
quality gates below are resolved or explicitly deferred by a human.

Open release-quality gates:

- restore or externally verify the local app-bundle helper launch path, then
  complete a normal desktop/manual launch and clean-quit pass
- keep release-evidence docs aligned so README, current status,
  troubleshooting, automation backlog, and roadmap all describe the same
  helper-smoke/manual-smoke boundary
- verify app-language switching on the highest-traffic UI surfaces, especially
  menu bar, toolbar, sidebar, Settings, Setup Guide, Endpoint, and HelpTooltip
  copy; fix one concrete mismatch at a time
- verify profile file-flow feedback on a normal macOS desktop, especially
  toolbar and menu bar import/export actions when the Profile panel is not
  visible
- verify the most visible UI-localization surfaces after the recent preset,
  Endpoint, and HelpTooltip cleanup; fix one concrete mismatch at a time
- verify the menu bar daily-use path on a normal macOS desktop, including
  status visibility, lifecycle actions, copy actions, and `Open Window`
  behavior from hidden or backgrounded window states
- verify the reduced toolbar on a normal macOS desktop, especially Setup Guide,
  profile import/export, copy actions, and title-bar crowding
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

- fix any failing `swift test`, `swift build --disable-sandbox`, localization
  lint, or `git diff --check` result before picking a polish slice
- make one small code-quality improvement inside the current `llama-server`
  boundary, with tests or build verification in the same run
- use `docs/automation_smoke_backlog.md` to expose or fix one concrete
  pre-release rough edge in UI labels, localization, menu bar/toolbar behavior,
  Setup Guide inspector flow, runtime setup, endpoint/health/copy/logs,
  profiles, packaging-prep, or non-mutating update-readiness
- add English/Japanese localization key parity coverage, or verify one named
  UI surface under Japanese and English language settings before fixing a
  concrete mismatch
- improve one shared daily-use affordance from the DeepSeek review; the
  stopped-state Aurora rendering, profile file-flow message mirror, menu bar
  copy feedback, menu bar copy accessibility, and shared button disabled-state
  visibility slices are covered
- improve one focused Chika-review daily-use gap, such as helper-smoke docs
  consistency when new drift appears, or another concrete rough edge that is not
  already covered by the Setup Guide copy accessibility and Logs retention
  caption slices
- classify public feedback or review notes with
  `docs/post_public_operations.md`, then make one safe local change only when
  the classification identifies a `llama-server` bug, profile import/export bug,
  docs confusion, or current-lane daily-use ambiguity
- verify menu bar daily-use gaps or decide toolbar demotion before adding any
  new control surfaces
- modernize a small SwiftUI API warning, such as `onChange`, only when the
  current toolchain reports it or the change is purely mechanical and covered
  by build/tests
- review the Setup Guide inspector against the normal Configuration flow and
  remove duplication or crowding if it is visible
- prepare post-RC readiness evidence, such as release-gate clarity,
  deterministic smoke notes, packaging-prep checks, guarded update-workflow
  planning, or focused tests, without executing runtime updates or public
  release mutations
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
