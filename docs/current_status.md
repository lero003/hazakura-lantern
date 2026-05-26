# Current Status

Last reviewed: 2026-05-26

## Project State

Hazakura Lantern is an early macOS SwiftUI app for supervising a local
`llama-server` process from `llama.cpp`.

Current release checkpoint: `v1.5.1` is a public source-only checkpoint for
personal/local use. It keeps the existing `llama-server` control boundary, adds
explicit public license and contribution metadata on top of `v1.5.0`, and is
not a packaged app release. The previous public source-only checkpoint was
`v1.5.0`.

Repository licensing is explicit: Hazakura Lantern source code is MIT-licensed
through the top-level `LICENSE` file and README license section. External
runtimes and local model files are not bundled and remain under their own
licenses.

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
- When the Setup Guide inspector is visible, the main window synchronizes its
  SwiftUI and `NSWindow` minimum size to keep the sidebar, main content, and
  inspector from clipping or sliding offscreen during narrow-window smoke
  checks.
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
- Dashboard now shows the managed process PID and current resident memory when
  `llama-server` is running, keeping the visibility limited to Lantern's own
  supervised process rather than broader system telemetry.
- Startup now shows an explicit `Loading Model` state after the child process
  starts, then moves to `Running` only after known `llama-server` readiness log
  text is observed.
- Restart requests now show an explicit `Restarting` state while Lantern waits
  for the current process to terminate before starting the next one.
- Stop, restart, and app quit now escalate from `SIGTERM` to `SIGKILL` if the
  child process does not exit, so a hung runtime is less likely to keep the
  configured port occupied after Lantern closes.
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
- OpenAI-compatible smoke requests also include a bounded 2,048-token cap and
  180-second timeout, so user-triggered local smoke has room for
  thinking-capable runtimes without becoming a benchmark or chat surface.
- The first v1.1 Local Smoke Console core client slice can now send a
  user-triggered, timeout-bounded, non-streaming OpenAI-compatible
  `/v1/chat/completions` request and map invalid endpoint, connection, timeout,
  HTTP status, and malformed-response failures through focused core tests.
- The first v1.1 Local Smoke Console UI slice now adds a separate sidebar
  destination for a user-triggered local endpoint smoke request with prompt,
  run state, response display, copy result, clear result, and localized
  app-owned UI strings.
- GGUF Acquisition now adds a separate sidebar destination for user-triggered
  Hugging Face public GGUF search, repository file selection, foreground
  download into `<owner>/<repo>/<file.gguf>` under a user-selected directory,
  visible progress/cancel/failure state, best-effort partial-file resume, and a
  completion action that sets the downloaded file as the active model path.
- GGUF Acquisition tree parsing now ignores unsafe `.gguf` paths containing
  empty, current-directory, parent-directory, absolute, or backslash-style path
  components before building download candidates.
- Smoke Console now explains why Run is unavailable when the server is running
  but the smoke prompt is blank or the endpoint configuration cannot be built.
- Smoke Console HTTP error snippets now collapse multiline runtime error bodies
  into a bounded readable summary before showing them in the error surface.
- Smoke Console HTTP error snippets now prefer OpenAI-compatible
  `error.message` payloads when present, so local runtime errors are shown as
  readable bounded messages instead of raw JSON.
- Smoke Console HTTP error snippets now also prefer structured top-level
  `detail` or `message` payloads when present, keeping compatible local
  endpoint failures readable without adding logs, history, or persistence.
- Smoke Console HTTP error snippets also read compatible structured `error`,
  `detail`, and FastAPI-style detail-array payloads before falling back to raw
  bounded response bodies.
- Smoke Console HTTP error snippets now also read code-only structured error
  objects and blank-message objects with fallback codes, keeping compatible
  local endpoint failures readable when the message field is missing or empty.
- Smoke Console HTTP error snippets now skip blank preferred structured error
  messages and fall through to readable sibling `detail` or `message` fields,
  keeping compatible local endpoint failures out of raw JSON when runtimes mix
  error payload shapes.
- Smoke Console HTTP error snippets now also read compatible structured message
  arrays nested under `error.message`, `detail`, `msg`, or `code`, keeping
  multi-message local endpoint failures readable without adding logs or
  persistence.
- Smoke Console result copy now copies the latest success response with the
  displayed v1.2 metrics, or the displayed error message when a smoke request
  fails, so local smoke evidence is easier to share without adding logs or
  persistence.
- Failed Smoke Console attempts now show and copy bounded attempt metrics:
  started time, elapsed time, request URL, request mode, and timeout used,
  keeping failure evidence shareable without adding logs, history, or
  benchmark claims.
- Smoke Console now localizes app-owned failure messages for invalid endpoint,
  connection, timeout, HTTP status, malformed-response, and request failures,
  keeping Japanese UI smoke evidence readable while leaving core adapter and
  runtime boundaries unchanged.
- Smoke Console now opens with the same bounded local smoke prompt used by the
  copyable OpenAI-compatible curl command, keeping the explicit prompt editable
  while avoiding a blank first run.
- Smoke Console now keeps the empty result state compact, and the endpoint/model
  summary plus run/copy/clear actions can fall back to narrower stacks instead
  of forcing a single wide row in Japanese UI.
- The main window minimum width is now 860 pt instead of 980 pt, allowing the
  Smoke Console compact layout to be exercised in a narrower release-smoke
  window without changing packaging or distribution scope.
- The v1.2 Runtime Smoke Metrics path now records successful Smoke Console
  started time, elapsed time, output character count, runtime-reported usage
  when available, explicitly approximate fallback output token count/rate,
  request mode, and timeout used, then shows those values with the response
  with localized app-owned labels.
- Smoke Console now preserves OpenAI-compatible response finish reasons such as
  `stop` or `length` in displayed and copied metrics, keeping bounded-output
  evidence visible without adding benchmark or conversation history behavior.
- Smoke Console finish-reason parsing now ignores malformed optional values
  when the response body is otherwise readable, keeping advisory metadata from
  turning local smoke evidence into a malformed-response failure.
- Smoke Console metric labels now explicitly distinguish usage reported by the
  runtime from approximate output-token fallback metrics, keeping copied smoke
  evidence honest without adding benchmark claims.
- Smoke Console now reads compatible `llama-server`
  `timings.predicted_per_second` values as Runtime TPS when present, while still
  falling back to elapsed-time or approximate rates without benchmark claims.
- Smoke Console also reads compatible `llama-server`
  `timings.cache_n`, `timings.prompt_n`, and `timings.predicted_n` token counts
  as runtime-reported usage when standard `usage` is missing, keeping token
  evidence explicit instead of approximate.
- Smoke Console metric parsing now tolerates numeric-string usage/timing values
  and ignores malformed optional metric fields when the response text itself is
  readable, so advisory metrics do not turn a valid smoke response into a
  malformed-response failure.
- Smoke Console metric parsing now preserves runtime-reported zero token counts
  from standard `usage` and compatible `llama-server` `timings` payloads, so
  explicit runtime evidence does not get replaced with approximate fallback
  metrics.
- Smoke Console metric parsing now also treats compatible `usage.input_tokens`
  and `usage.output_tokens` fields as runtime-reported usage, while keeping
  standard `prompt_tokens` / `completion_tokens` values authoritative when both
  shapes are present.
- Smoke Console now promotes runtime-reported or approximate output TPS ahead
  of the response body, and can display compatible `reasoning_content` output
  or text-part `message.content` arrays from OpenAI-compatible local runtimes.
- Compatible `reasoning_content` smoke output is trimmed before display and
  copy, keeping last-run smoke evidence tidy without adding conversation
  history or persistence.
- Smoke Console can now read compatible `message.reasoning` fallback text when
  `message.content` is blank, keeping reasoning-style local smoke output
  readable without adding conversation history or benchmark behavior.
- Smoke Console can now read legacy-compatible `choices[0].text` response text
  when a local `/v1/chat/completions` endpoint omits
  `choices[0].message.content`, keeping the same non-streaming smoke boundary
  while widening response-shape tolerance.
- Smoke Console metric badges now use an adaptive grid with stable badge
  heights and a shorter response pane, keeping dense v1.2 evidence readable in
  narrower windows without adding benchmark, history, or persistence behavior.
- Smoke Console can now read compatible single text-part `message.content`
  objects from local `/v1/chat/completions` responses, keeping odd but readable
  smoke evidence from being reported as malformed JSON.
- Smoke Console text-part response parsing now normalizes content type casing
  and whitespace before accepting `text` parts, keeping compatible local smoke
  responses readable when runtimes return loose type labels.
- Smoke Console text-part response parsing now also accepts compatible
  `output_text` parts inside `message.content`, keeping response-style local
  smoke payloads readable without adding chat history or benchmark behavior.
- Smoke Console text-part response parsing now also accepts compatible `content`
  fields inside text and output-text parts, keeping readable local smoke output
  visible when a runtime uses that field name instead of `text`.
- Smoke Console text-part response parsing now also accepts plain string items
  inside compatible `message.content` arrays, keeping mixed readable local
  smoke output from being reported as malformed JSON.
- Smoke Console text-part response parsing now ignores unreadable structured
  non-text content parts inside compatible `message.content` arrays, keeping
  readable text/output-text evidence visible when a local runtime includes
  tool-call-like payloads.
- Smoke Console response parsing now uses the first readable choice in
  compatible multi-choice responses, keeping a blank earlier choice from hiding
  later local smoke evidence.
- Smoke Console success metrics now retain and display the actual
  `/v1/chat/completions` request URL, and copied success evidence includes it
  with the other bounded metrics.
- Smoke Console success and failure metrics now retain and copy the tested
  model ID, keeping shared local smoke evidence tied to both endpoint URL and
  model alias without adding chat history, persistence, or benchmark behavior.
- Smoke Console Run, Copy Result, and Clear Result controls now expose localized
  accessibility hints that keep the surface framed as an explicit endpoint
  smoke, not saved conversation history.
- Smoke Console Japanese unavailable-run messages now use the localized
  "動作確認" surface name instead of mixing in the English "Smoke Console"
  label.
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
  chat, model library management, proxy, LAN exposure, authentication, runtime
  installer, and packaged-app requests outside the current source-only
  checkpoint boundary.
- Local/static public-opening review has checked workflow, issue-template,
  manifest, script, README, changelog, and docs guidance for surprising CI
  triggers or permissions, `curl | sh`, package-manager mutation, packaged-app
  distribution claims, and release-asset claims without changing remote GitHub
  settings.
- Local source verification passed on 2026-05-23 during the Smoke Console
  TPS/manual-review polish pass with
  `git diff --check`, localization lint, `swift test` (218 XCTest tests,
  0 failures), and
  `swift build --disable-sandbox`. The 2026-05-24 local app-bundle helper
  smoke later reproduced `kLSNoExecutableErr` in this Codex environment even
  though the generated bundle contained the expected executable and resources.
  The previous 2026-05-23 Smoke Console HTTP-snippet, disabled-run feedback,
  and v1.2 metrics passes also had passing source-verification results.
- Local source verification passed again on 2026-05-23 during process
  termination hardening with `git diff --check`, `swift test` (219 XCTest tests,
  0 failures), and `swift build --disable-sandbox`.
- Local source verification passed again on 2026-05-23 during `v1.2.0`
  source-checkpoint prep with `git diff --check`, English/Japanese
  `Localizable.strings` lint, `swift test` (219 XCTest tests, 0 failures), and
  `swift build --disable-sandbox`.
- Local source verification passed again on 2026-05-23 during the 30-minute
  automation evidence refresh with `git diff --check`, English/Japanese
  `Localizable.strings` lint, `swift test` (221 XCTest tests, 0 failures), and
  `swift build --disable-sandbox`. App-bundle helper smoke was not rerun
  because there was no fresh Launch Services hypothesis or normal desktop
  verification environment.
- Local source verification passed again on 2026-05-23 during the
  `reasoning_content` smoke-evidence trim pass with `git diff --check`,
  English/Japanese `Localizable.strings` lint, `swift test` (221 XCTest tests,
  0 failures), and `swift build --disable-sandbox`.
- Local source verification passed again on 2026-05-23 during the
  `choices[0].text` smoke-response fallback pass with `git diff --check`,
  English/Japanese `Localizable.strings` lint, `swift test` (222 XCTest tests,
  0 failures), and `swift build --disable-sandbox`.
- Local source verification passed again on 2026-05-23 during the
  runtime-reported Smoke Console TPS pass with `git diff --check`,
  English/Japanese `Localizable.strings` lint, `swift test` (223 XCTest tests,
  0 failures), and `swift build --disable-sandbox`.
- Local source verification passed again on 2026-05-23 during the structured
  Smoke Console HTTP-error snippet pass with `git diff --check`,
  English/Japanese `Localizable.strings` lint, `swift test` (227 XCTest tests,
  0 failures), and `swift build --disable-sandbox`.
- Local source verification passed again on 2026-05-24 during the zero-token
  Smoke Console metrics pass with `git diff --check`, English/Japanese
  `Localizable.strings` lint, `swift test` (246 XCTest tests, 0 failures), and
  `swift build --disable-sandbox`.
- Local source verification passed again on 2026-05-24 during the
  `message.reasoning` smoke-response fallback pass with `git diff --check`,
  English/Japanese `Localizable.strings` lint, `swift test` (249 XCTest tests,
  0 failures), and `swift build --disable-sandbox`.
- App bundle launch helper at `script/build_and_run.sh`.
- App smoke cleanup helper: `--verify` closes the app on exit, and `--stop`
  closes a leftover `HazakuraLLMManager` process plus any direct child runtime
  process captured from that app instance, without killing unrelated external
  `llama-server` processes.
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
  accessibility labels and values in the main status surfaces and Setup Guide
  while keeping decorative status artwork out of the reading order.
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

Current source-verification status (2026-05-26 GGUF Acquisition pass):
`git diff --check`, English/Japanese `Localizable.strings` lint,
`swift test` (256 XCTest tests, 0 failures), and
`swift build --disable-sandbox` passed. A no-download Hugging Face API smoke
found public repo `unsloth/Qwen3.6-27B-MTP-GGUF` and 26 `.gguf` files through
the same search/tree endpoint shape used by the app. App-bundle and real
runtime smoke were not rerun for this source/UI slice.

The previous 2026-05-24 v1.5 release-prep pass included a real local endpoint
smoke against the selected lightweight `gemma-4-E2B-it-UD-Q3_K_XL` model with
the Setup Guide inspector visible, showed the in-app source checkpoint as
`v1.5.0`, expanded a requested 860 pt window to the 1320 pt guide-safe minimum,
and returned an `OK` Smoke Console response with visible runtime TPS, start
time, elapsed time, output character count, finish reason, and timeout metrics.
The same pass verified Stop leaves the app running while removing the managed
`llama-server`, and Quit removes both `HazakuraLLMManager` and the managed
runtime.

Current Codex launch-smoke status (2026-05-24 verify hardening pass):
`./script/build_and_run.sh --verify` builds the local bundle, requests launch
through Launch Services, confirms a `HazakuraLLMManager` process id, and closes
the app before the script exits. A follow-up process and port check found no
remaining `HazakuraLLMManager`, managed `llama-server`, or `9993` listener.
After the helper change, the normal `./script/build_and_run.sh` path also
opened the app, started the selected lightweight `gemma-4-E2B-it-UD-Q3_K_XL`
runtime, completed a short in-app Japanese Smoke Console request, and
`./script/build_and_run.sh --stop` left no app, managed runtime, or `9993/9994`
listener behind.

Final Smoke Console goal audit on 2026-05-24 re-ran the current worktree at an
860 pt window width with the selected lightweight model: short Japanese prompt,
medium two-sentence Japanese prompt, and an error-path request against unused
`9994` all produced readable Smoke Console evidence through the app UI. The
short success view was also captured by screenshot, showing the prompt,
run/copy/clear buttons, adaptive metrics, endpoint/model labels, and response
without visible clipping.

Post-`v1.5.1` normal desktop smoke on 2026-05-25 launched the local bundle via
`./script/build_and_run.sh`, used the selected lightweight
`gemma-4-E2B-it-UD-Q3_K_XL` runtime, opened Setup Guide without clipping,
confirmed Dashboard health status in Japanese, ran a Smoke Console request that
returned `OK` with runtime TPS/elapsed/finish/usage evidence, opened and
cancelled toolbar Profile export/import panels, inspected the Server menu, used
the menu-bar Stop command, and then quit the app. Follow-up process checks
found no `HazakuraLLMManager` or managed `llama-server` process.

Follow-up launch probing also exposed a fragile main-window presentation path
after the menu-bar-only state was reached. The app now keeps one shared
`ServerController`, routes Open Window through an app-owned presenter, and
uses a small AppKit fallback only to present the existing SwiftUI `ContentView`
when SwiftUI scene restoration reports no usable main window. This is still
source-confidence evidence; full visual confirmation of every Settings/control
surface remains part of the final packaged-release UI pass.

Treat these as source-confidence and normal desktop smoke evidence, not
packaged-release proof. A packaged-release pass still needs artifact-specific
review for a distributed `.app`, zip/dmg, signing, notarization, checksum,
release notes, and final full-route manual UI review.

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
However, the helper could still fail when `open` was invoked after rebuilding
the bundle. The 2026-05-21 and earlier 2026-05-24 runs reproduced that failure
even though the bundle executable and `CFBundleExecutable` value matched.

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
- The app does not manage multiple profiles, launch-at-login, YAML
  import/export, auto restart, model libraries, download history, chat, RAG, or
  proxy behavior.
- Runtime update availability checks are advisory and networked only when the
  user presses Check for Updates. Lantern does not run package-manager, Git,
  download, or binary replacement commands.
- LAN exposure and authentication are intentionally outside the current source
  checkpoint.

## Automation Focus

The automation should treat version checkpoints as history, not as the work
queue. The useful question is whether the next slice moves Lantern closer to
release-quality daily use while preserving the current `llama-server` boundary.

Current human direction: continue automated development and manual desktop
verification after the `v1.5.1` source-only checkpoint and the first GGUF
Acquisition slice, then fix one quality or smoke-observed rough edge at a time
before any later source checkpoint.
Packaged app release remains separate: automation should
continue code-quality checks, narrow verified improvements, and
packaged-release readiness evidence, but should not create packaged artifacts,
change GitHub settings, mutate public issues, or decide packaged-release
readiness by itself.

No user-facing packaged release should be cut until the remaining release
quality gates below are resolved or explicitly deferred by a human.

Open release-quality gates:

- keep the normal desktop smoke fresh after UI or lifecycle changes; the
  2026-05-25 pass covers launch, Setup Guide, Smoke Console, toolbar
  import/export panel presentation, menu-bar Stop, and clean quit
- keep release-evidence docs aligned so README, current status,
  troubleshooting, automation backlog, and roadmap all describe the same
  helper-smoke/manual-smoke boundary
- verify app-language switching on the remaining high-traffic UI surfaces,
  especially menu bar, Settings, Endpoint advanced details, and HelpTooltip
  copy; fix one concrete mismatch at a time
- verify profile file-flow completion on a normal macOS desktop, especially
  successful export/import round trips with safe temporary files when that
  local file mutation is explicitly in scope
- verify the most visible UI-localization surfaces after the recent preset,
  Endpoint, and HelpTooltip cleanup; fix one concrete mismatch at a time
- verify the remaining menu bar daily-use path on a normal macOS desktop,
  especially copy actions and a final `Open Window` regression check from
  hidden or backgrounded window states
- verify the remaining reduced-toolbar copy menu actions on a normal macOS
  desktop; Setup Guide and profile panel presentation have current smoke
  evidence
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
assets, repository packages, public issue state, a new
adapter, custom command implementation, profile schema version, dependencies,
runtime installation/update, model library management, download history, hidden
auto-optimization, Hugging Face token storage, gated-model workflow, background
download queue, or LM Studio internal metadata integration without an explicit
human handoff. Bounded GGUF Acquisition is now implemented as a foreground
search/download lane, so ordinary automation may harden that lane only through
tests, no-download public API smoke, UI copy/accessibility, and focused
download-state fixes inside `docs/gguf_acquisition.md`.

## Next Best Slice

Good next automated candidates:

- fix any failing `swift test`, `swift build --disable-sandbox`, localization
  lint, or `git diff --check` result before picking a polish slice
- after v1.5, run smoke and fix one concrete rough edge at a time while keeping
  conversation history, prompt libraries, RAG/tools, benchmark rankings, and
  runtime optimization out of scope
- harden GGUF Acquisition in one bounded slice: fake Hugging Face responses,
  `.gguf` tree parsing, destination-path safety, partial resume/cancel/failure
  states, localized UI copy, completion-to-model-path handoff, or a no-download
  public API shape check
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
- prepare post-checkpoint readiness evidence, such as release-gate clarity,
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
download history, unattended runtime installation/update, automatic
benchmarking, or chat features during this handoff. Any follow-up to GGUF
Acquisition should stay inside `docs/gguf_acquisition.md` and must not become a
model database or background downloader. Runtime version and option checks are
allowed only as local, timeout-bounded, read-only advisory work that improves
release quality. Guarded update execution must be opt-in and user-confirmed.
