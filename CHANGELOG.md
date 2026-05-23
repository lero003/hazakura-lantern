# Changelog

All notable changes to Hazakura Lantern will be documented in this file.

## Unreleased

### Changed

- Added Smoke Console support for runtime-reported
  `timings.predicted_per_second` values from compatible `llama-server`
  responses, showing them as Runtime TPS while keeping approximate fallback
  metrics explicitly labeled.
- Added a Smoke Console response parser fallback for legacy-compatible
  `/v1/chat/completions` responses that provide `choices[0].text` instead of
  `choices[0].message.content`, keeping endpoint smoke evidence readable
  without changing the non-streaming request boundary.
- Trimmed surrounding whitespace from compatible `reasoning_content` smoke
  responses before display or copy, keeping Smoke Console evidence tidy without
  changing the non-streaming request boundary.
- Added a clearer Dashboard server summary with the managed process PID and
  current resident memory when `llama-server` is running, without adding CPU,
  request, or benchmark tracking.
- Added Smoke Console finish-reason metrics for OpenAI-compatible responses, so
  local smoke evidence can show cases such as `stop` or `length` alongside the
  existing elapsed time, usage, and timeout details.

## v1.2.0 - 2026-05-23

### Changed

- Released a source-only v1.2 checkpoint for personal/local use, with no
  packaged `.app`, zip, dmg, signing, notarization, checksum, or binary
  distribution artifact.
- Hardened Stop, Restart, and app-quit process termination so Lantern escalates
  from `SIGTERM` to `SIGKILL` when the child runtime does not exit, reducing
  the chance that a hung `llama-server` keeps the configured port occupied.
- Hardened Smoke Console response parsing for OpenAI-compatible runtimes that
  return assistant text as `message.content` text parts instead of a plain
  string, while keeping the surface non-persistent and smoke-only.
- Adjusted Smoke Console after manual review: the sidebar now uses the shorter
  Japanese label, response metrics appear above the response body with TPS
  first and prominent, the prompt area is shorter, the response area/page can
  use more vertical space, and empty `content` responses can display decoded
  `reasoning_content` output from compatible local runtimes.
- Raised the default Smoke Console request token cap to a bounded 2,048 tokens
  so thinking-capable local runtimes have more room during an explicit smoke
  run without becoming an open-ended benchmark.
- Raised the default Smoke Console timeout to a bounded 180 seconds for larger
  explicit local verification runs without turning the feature into automatic
  benchmarking.
- Relaxed the launch preflight port probe so recently closed local ports are
  not treated as indefinitely unavailable by the app-side availability check.
- Added failed-attempt metrics to Smoke Console errors, so failed local endpoint
  smoke evidence now shows started time, elapsed time, request mode, and
  timeout used when displayed or copied.
- Seeded the Smoke Console prompt with the same bounded local smoke prompt used
  by the copyable curl command, so a running server can be checked immediately
  while the prompt remains editable.
- Extended Smoke Console success copies to include the displayed v1.2 metrics
  alongside the response text, while failed smoke copies still copy the visible
  error message.
- Added Smoke Console started-time evidence to successful v1.2 metrics, so the
  latest local endpoint smoke result shows when the request began alongside
  elapsed time, output size, usage, request mode, and timeout.
- Changed Smoke Console copy behavior so the result copy button copies the
  currently displayed success response or error message, making failed local
  endpoint smoke evidence easier to share.
- Normalized and bounded Smoke Console HTTP error snippets so multiline runtime
  error bodies stay readable in the local smoke error surface.
- Aligned post-public automation guidance after `v1.0.0-rc.2`, keeping the
  source-only checkpoint posture explicit and packaged release as a later
  handoff.
- Clarified Smoke Console disabled-run feedback: when the server is running but
  the prompt is blank or the endpoint configuration is invalid, the view now
  shows localized next-step guidance instead of only disabling Run.
- Added the first v1.2 Smoke Console metrics slice: successful local endpoint
  smoke results now record elapsed time, output character count, request mode,
  and timeout used, with focused core coverage and localized UI labels.
- Added the first v1.1 Smoke Console UI slice: a separate sidebar destination
  for a user-triggered local endpoint smoke request with prompt, run state,
  response display, copy response, clear result, and localized app UI strings.
- Added the first core v1.1 Smoke Console client slice: a timeout-bounded,
  non-streaming OpenAI-compatible chat-completions runner with focused tests for
  request construction, response parsing, and endpoint/timeout/HTTP/error
  mapping.
- Reoriented automated development after `v1.0.0-rc.2` toward a 30-minute
  v1.1/v1.2 lane: non-persistent local endpoint smoke testing first, then
  careful approximate smoke metrics, while keeping packaged releases and chat
  product features out of scope.

## v1.0.0-rc.2 - 2026-05-23

### Changed

- Released a second source-only release candidate for personal/local use, with
  no packaged `.app`, zip, dmg, signing, notarization, checksum, or binary
  distribution artifact.
- Added a `Loading Model` process state after launch so Lantern does not mark a
  runtime as running until known server-readiness log text is observed.
- Localized update-readiness and update-check status text in the Configuration
  view so English/Japanese app UI switching covers the non-mutating runtime
  update guidance.
- Split Configuration runtime diagnostics from presets and localized the
  install-source / capability probe status text for English and Japanese app UI.
- Tightened embedded Settings and Setup Guide inspector widths so the
  sidebar-based main window keeps those utility surfaces compact.
- Clarified update-check outcome wording so the user-triggered `llama.cpp`
  check stays metadata-only and does not imply Lantern prepares or runs
  updates.
- Treated `/usr/local/bin/llama-server` as a Homebrew-style runtime path for
  non-mutating install-source and update-readiness advice.
- Added explicit accessibility labels and values to the Setup Guide process
  status and API health rows.
- Refined Setup Guide step-card accessibility hints so each setup state
  announces the specific next action in English and Japanese.
- Added localized accessibility labels and hints to the main toolbar's
  icon-only Setup Guide, profile import/export, and Copy controls.
- Recorded the 2026-05-23 source verification evidence while keeping the
  existing app-bundle helper smoke regression separate from packaged-release
  proof.

## v1.0.0-rc.1 - 2026-05-22

### Changed

- Released a source-only release candidate for personal/local use, with no
  packaged `.app`, zip, dmg, signing, notarization, checksum, or binary
  distribution artifact.
- Added an external review flow for paste-ready release-readiness and
  future-direction feedback requests, including a bounded way to ask whether
  image or multimedia generation belongs in Lantern, a future design note, or a
  separate sibling project.
- Folded the 2026-05-22 Chika release-readiness follow-up into automation
  guidance, marking already-covered polish separately from remaining manual
  smoke and human-decision items.
- Localized HelpTooltip titles, descriptions, tips, and section headings, and
  replaced Endpoint advanced-section bilingual literal keys with standard app
  localization keys.
- Reduced the main-window toolbar to Setup Guide, profile import/export, and
  copy actions; server lifecycle, health, command reveal, and log clearing stay
  in the main UI or menu bar.
- Moved the language selector into the main window sidebar Settings destination
  while keeping the existing macOS Settings scene available.
- Disabled manual endpoint health checks unless the server is running.
- Widened the minimum main-window and Setup Guide inspector layout, and kept
  advanced Settings auto value pills on one line.
- Added a non-mutating `llama.cpp` update availability check that fetches the
  latest official GitHub release metadata, compares `bNNNN` build numbers when
  local runtime version evidence is available, and never executes an update.
- Added a Setup Guide Homebrew update command copy affordance for manual
  `llama.cpp` upgrades.
- Clarified the recurring automation posture leading into the source-only RC,
  keeping packaged-release judgment separate while automated runs continue
  code-quality checks and narrow improvements.
- Folded the 2026-05-21 Gemini v1 polish review into the automation smoke
  backlog, with bounded follow-up tasks for localization coverage,
  HelpTooltip copy, launch-helper hypotheses, toolbar evidence, and log-policy
  decisions.
- Folded the 2026-05-21 DeepSeek v1 polish review into the automation smoke
  backlog, prioritizing copy feedback, preset localization, localization-key
  cleanup, menu bar accessibility, disabled button styling, and stopped-state
  background rendering as small release-polish candidates.
- Folded the 2026-05-21 Chika v1 polish review into the automation smoke
  backlog, clarifying helper-smoke evidence consistency, manual desktop smoke,
  health-check policy, Setup Guide empty states, copy accessibility, logs
  retention wording, and source-checkpoint centralization.
- Marked the Logs retention wording slice as covered in automation guidance so
  future polish runs do not repeat the completed in-memory-only caption work.
- Clarified automation guidance so human-decision items block only their exact
  slice and do not prevent unrelated safe release-polish work.
- Removed duplicate `Process Status` localization entries and added focused
  tests for English/Japanese localization key parity.
- Added focused tests for English/Japanese localization format-placeholder
  parity so translated UI strings keep matching interpolation contracts.
- Localized Configuration preset guidance so English UI no longer shows the
  Japanese-only helper description.
- Added a localized Logs caption that clarifies runtime logs stay in memory and
  are not saved automatically.
- Added Setup Guide empty-state wording for Macs where no installed
  `llama-server` runtime is detected while keeping manual runtime selection
  available.
- Added transient copied feedback to Endpoint destination copy controls for the
  base URL, environment snippet, health-check curl, and AI Mobile smoke curl.
- Added transient copied feedback to the Dashboard launch command preview copy
  button.
- Added transient copied feedback to the main window toolbar Copy menu after
  copying the launch command, endpoint, environment snippet, health-check curl,
  or AI Mobile smoke curl.
- Added transient copied feedback to the menu bar copy actions for the launch
  command, endpoint, environment snippet, health-check curl, and AI Mobile
  smoke curl.
- Mirrored active profile import/export file-flow messages into the toolbar
  Profile menu and menu bar controls, so the result remains visible outside the
  Configuration profile panel.
- Added localized accessibility hints to menu bar copy actions for the launch
  command, endpoint, environment snippet, health-check curl, and AI Mobile
  smoke curl.
- Centralized the in-app source checkpoint metadata so Settings reads the
  source-only checkpoint from one tested value without implying packaged app
  artifacts.
- Improved the Setup Guide endpoint copy button so its icon-only control exposes
  localized accessibility text for the copied client connection URL.
- Improved shared primary and secondary button disabled states so inactive
  controls keep visible labels and outlines without changing their actions.
- Paused the decorative Aurora background animation while the server is
  stopped, keeping the idle window calmer without changing runtime behavior.
- Added English/Japanese accessibility values for disclosure headers so
  Advanced sections announce expanded and collapsed state in the selected app
  language.

## v0.9.0-alpha.1 - 2026-05-21

Source-only alpha checkpoint for release-quality UI, menu bar, toolbar,
localization, setup guidance, and non-mutating `llama-server` update-readiness
work. This checkpoint does not include a packaged `.app`, zip, dmg, signing,
notarization, checksum, or binary distribution artifact.

### Changed

- Improved Runtime Profile import/export accessibility so the buttons announce
  the active `.lantern-profile.json` file flow.
- Recorded the 2026-05-21 automated smoke regression where SwiftPM tests,
  localization lint, and source build passed but the app-bundle helper launch
  returned `kLSNoExecutableErr`, keeping manual desktop UI smoke and helper
  stability as release gates.
- Aligned menu bar copy action labels with the toolbar copy menu so endpoint,
  environment, health-check, and AI Mobile smoke snippets use the same visible
  wording.
- Improved process status and endpoint health accessibility so status
  indicators report explicit labels and values without reading decorative
  artwork.
- Improved Setup Guide step-card accessibility so each step reports
  complete/incomplete state with localized hints.
- Moved Setup Guide out of the primary sidebar and into a toolbar-toggled
  inspector, with the Dashboard setup hint opening the same onboarding surface.
- Added non-mutating installed `llama-server` discovery for PATH, Homebrew, and
  MacPorts locations so runtime selection can use an in-app menu before falling
  back to manual file choice.
- Added a Settings language toggle for System, Japanese, and English UI labels,
  backed by app-local localization resources.
- Added Settings source-checkpoint text so the app states that the current
  alpha is source-only and has no packaged app artifact.
- Removed the Setup Guide's forced static model-search URL construction so the
  inspector no longer carries that app-UI crash edge.
- Added an automation smoke backlog for pre-release rough-edge discovery and
  small verifiable polish slices.
- Folded external general-distribution improvement feedback into the automation
  smoke backlog with explicit automation and human-decision boundaries.
- Added a sidebar-based main window layout with a dashboard for server controls,
  endpoint details, and launch command preview while keeping runtime behavior
  unchanged.
- Folded advanced configuration fields behind disclosure controls and adjusted
  the visual treatment toward a warmer lantern palette.
- Documented the pre-release UI blockers for the recent menu bar, toolbar, and
  Setup Guide additions before a user-facing packaged release.
- Added a native toolbar shell for existing start, stop, restart, and manual
  endpoint health-check actions without adding new runtime behavior.
- Added a toolbar copy menu for the existing launch command, endpoint,
  environment, health-check, and AI Mobile smoke snippets.
- Added toolbar profile import/export entry points that reuse the existing
  active-profile file flow without adding multiple-profile management.
- Added a toolbar clear-log action that reuses the existing in-memory log reset
  behavior and disables itself when there are no logs.
- Added a toolbar command-preview action that reveals the existing launch
  command audit surface without changing runtime behavior.
- Added a menu bar control surface for the existing server actions, copy
  helpers, profile import/export, log clearing, window opening, and quitting
  while keeping the regular main window intact.
- Added non-mutating `llama-server` install-source advice for Homebrew-style,
  MacPorts-style, source-checkout, and manual runtime paths.
- Added non-mutating update-readiness dry-run guidance that explains whether
  Lantern still needs runtime capability evidence before any guarded update
  plan can be prepared.
- Clarified manual-path update-readiness wording so unsupported update sources
  do not look eligible for an in-app guarded update plan.
- Refined update-readiness dry-run wording so incomplete evidence names the
  missing `--version` or `--help` signal before any guarded update plan.
- Localized HelpTooltip accessibility and help text through the app language
  resources instead of leaving the explanation button assistive text fixed.
- Centralized UI pasteboard writes for existing copy actions so toolbar,
  menu bar, endpoint, command-preview, and Setup Guide copy behavior use one
  shared helper without changing copied values.
- Added post-public repository hygiene for CI action pinning, CODEOWNERS,
  Dependabot proposal configuration, and common local secret-ignore rules
  without changing remote GitHub settings or shipping packaged artifacts.
- Surfaced the local `llama-server` capability probe in the server
  configuration view so users can manually check the selected runtime version
  and see advisory preset-option support before launch.
- Added a local, timeout-bounded `llama-server` capability probe that reads
  `--version` and `--help` output without model launch or runtime mutation,
  giving preset compatibility warnings a tested core boundary.
- Added a compact preset picker in the server configuration view so
  `llama-server` presets can be previewed and applied to the active
  configuration while keeping generated settings visible before launch.
- Added a core `llama-server` preset model for conservative, balanced local,
  long-context, low-memory, and MTP-capable settings while keeping every
  generated option visible in the launch command.
- Reworked the post-v0.5 roadmap so v0.6 and v0.7 stay on the existing
  `llama-server` path: model-family presets, option compatibility, and
  advisory runtime/version checks now come before any second-runtime adapter
  design.
- Restored toolbar and navigation work as the v0.8 lane and moved the
  llama-server update workflow into v0.9/v1.0, with automation allowed to
  implement guarded update UX but not to mutate real runtimes unattended.
- Improved log-row accessibility so each runtime log entry is announced with
  its stream and message together.
- Updated the preset vocabulary to Standard, Qwen Recommended, and Gemma
  Recommended, keeping generated `llama-server` options visible while leaving
  speculative decoding out of the default presets.
- Kept Configuration path rows compact by removing the Recent menus from the
  runtime/model picker surface while preserving stored recent-path data.
- Made Advanced Settings and Advanced Connection Details full-row clickable
  disclosure headers, raised the context slider ceiling, and clarified that
  thread/GPU auto values are delegated to `llama-server`.
- Expanded the Logs destination so empty and populated log content top-aligns
  inside the available view space.
- Reframed automation guidance around unfinished release-quality gates rather
  than advancing through version-numbered lanes.

## v0.5.0-alpha.1 - 2026-05-20

Source-only alpha checkpoint for post-public issue triage and automation
discipline. This checkpoint does not include a packaged `.app`, zip, dmg,
signing, notarization, checksum, or binary distribution artifact.

### Added

- Added post-public operations guidance for issue triage, automation-safe work,
  human approval gates, and packaged-release separation after the repository
  became public.
- Added post-public label proposals and draft response shapes that automation
  can prepare without mutating public GitHub issues.
- Added post-public `llama-server` ownership triage guidance so automation
  separates Lantern-owned fixes from runtime-owned behavior before acting.
- Added a start-time setup hint for blank runtime or model selections so the
  empty state points to the next local choice before launch.
- Added a start-time setup hint for non-`.gguf` model selections so unsupported
  local model files are called out before launch without adding conversion or
  download behavior.
- Added start-time setup hints for invalid numeric launch settings so port,
  context, threads, and GPU layers point to the required local value before
  launch.
- Added a start-time setup hint for invalid host values so launch-host and
  endpoint-copy mistakes are explained before a failed launch attempt.
- Added a start-time setup hint for malformed Additional Args quoting so users
  can fix launch arguments before a failed start attempt.
- Added a fail-fast, timeout-bounded copied client smoke curl command so local
  OpenAI-compatible checks do not hang indefinitely.
- Added troubleshooting guidance for locally checking the selected
  `llama-server` executable and `.gguf` model without adding installer or
  model-download behavior.

### Changed

- Clarified Stop and Restart termination log messages so expected process
  termination is not worded like an unexpected runtime crash.
- Clarified runtime termination logs and error text so signal-based termination
  is no longer described as a normal exit code.
- Clarified imported profile portability warnings when a saved runtime
  executable path points to a directory instead of a `llama-server` binary.
- Clarified manual endpoint health-check wording for non-success HTTP responses
  so users can verify model load completion or inspect runtime logs.
- Clarified the healthy endpoint status detail so manual checks read as a
  snapshot rather than automatic endpoint polling.
- Re-aligned the roadmap so v0.4 focuses on `llama-server` reliability,
  v0.5 on post-public issue triage, v0.6/v0.7 on `llama-server` presets and
  runtime advisories, and MLX work stays deferred until a later design lane.
- Updated automation guidance so runs may continue through v0.5 when v0.4 has
  no concrete safe `llama-server` reliability slice.

### Known Issues

- `./script/build_and_run.sh --verify` can still fail with Launch Services
  `kLSNoExecutableErr` in the Codex environment. This remains a packaged-app
  launch-smoke blocker, not a source-only checkpoint blocker.

## v0.3.0-alpha.1 - 2026-05-19

### Added

- Added public-opening preflight guidance so automation can prepare docs,
  workflow hygiene, and release-boundary checks before any GitHub visibility
  handoff.
- Added a public bug-report issue template that asks for reproduction steps,
  runtime/profile context, command previews, and redacted logs without widening
  Lantern beyond its source-only alpha boundary.

### Changed

- Tightened the CI workflow to declare read-only repository contents permission
  for SwiftPM verification.
- Recorded a local/static public-opening scan of workflow, issue-template,
  manifest, script, and docs guidance without changing remote GitHub settings.
- Recorded a local public-opening verification baseline for SwiftPM tests and
  build while keeping the packaged-app launch-smoke blocker explicit.
- Sanitized public agent guidance to avoid local home-directory paths and
  surfaced the known app-bundle smoke blocker in README local-development
  instructions.

### Known Issues

- `./script/build_and_run.sh --verify` can still fail with Launch Services
  `kLSNoExecutableErr` in the Codex environment. This checkpoint is source-only
  and does not attach a packaged `.app`, zip, dmg, signing, or notarization
  artifact.

## v0.2.0-alpha.1 - 2026-05-18

### Added

- Added runtime profile JSON helpers with schema version `1`, runtime kind, and
  embedded runtime configuration.
- Added typed import failures for missing or unsupported profile schema
  versions, runtime kinds, profile names, and unsupported profile file names.
- Added active runtime profile persistence fallback so unsupported future
  profile data does not break startup.
- Added profile export filename and `.lantern-profile.json` recognition
  contracts.
- Added profile import preview, local file reference reporting, and
  adapter-scoped launch command preview helpers.
- Added minimal active-profile import/export UI for `.lantern-profile.json`
  files without adding multiple-profile management.
- Added runtime profile documentation with a readable schema-version `1`
  example and portability boundaries.
- Added compact troubleshooting guidance for setup, endpoint health,
  app-bundle smoke, and source-only alpha release boundaries.

### Changed

- Adopted Nenrin for release, automation, and scope judgment while keeping
  ordinary implementation logs out of durable records.

### Known Issues

- `./script/build_and_run.sh --verify` can still fail with Launch Services
  `kLSNoExecutableErr` in the Codex environment. This checkpoint is source-only
  and does not attach a packaged `.app`, zip, dmg, signing, or notarization
  artifact.

## v0.1.0-alpha.1 - 2026-05-17

### Added

- Added macOS SwiftPM CI for `swift test` and `swift build --disable-sandbox`.
- Added a copy button for the generated launch command preview.
- Added a real-model-free fake runtime smoke test for adapter-built launch
  commands.
- Added recent runtime executable and model path menus, stored separately from
  the active runtime configuration.

### Changed

- Clarified that OpenAI-compatible endpoint URLs are provided by the selected
  runtime, not by a Lantern proxy layer.
- Reset endpoint health status when the runtime starts, stops, or terminates so
  stale healthy checks do not survive process state changes.
- Clarified that v0.1 daily-use confidence work may proceed while the
  `kLSNoExecutableErr` app-bundle launch-smoke issue remains a release blocker.

### Known Issues

- `./script/build_and_run.sh --verify` can still fail with Launch Services
  `kLSNoExecutableErr` in the Codex environment. Do not cut a user-facing app
  bundle release until launch verification succeeds on a normal macOS
  environment.
