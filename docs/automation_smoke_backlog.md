# Automation Smoke Backlog

This document gives recurring automation concrete rough-edge discovery and
polish work before a user-facing packaged release. It is intentionally narrower
than the full roadmap.

Use this after reading `docs/current_status.md`, `docs/roadmap.md`, and
`docs/development_loop.md`.

## Purpose

Automation should help expose and fix small product-quality issues while the app
is source-only and not yet packaged:

- UI labels that are confusing, clipped, duplicated, or stale
- menu bar, toolbar, and Setup Guide flows that mirror existing behavior poorly
- setup, health, copy, profile, and localization rough edges
- non-mutating update-readiness gaps that can be explained or tested locally

Each run should still choose at most one coherent slice.

## Safe Automated Smoke

Automation may run these checks without a new human prompt when the working tree
state is compatible with the current task:

```bash
git diff --check
swift test
swift build --disable-sandbox
plutil -lint Sources/HazakuraLLMManager/Resources/en.lproj/Localizable.strings Sources/HazakuraLLMManager/Resources/ja.lproj/Localizable.strings
./script/build_and_run.sh --verify
./script/build_and_run.sh --stop
```

Use `./script/build_and_run.sh --verify` only as a smoke check. It must not
become packaged-release proof by itself. For user-facing packaged release, a
normal macOS desktop pass is still required.

Latest source-verification result (2026-05-22 21:47 JST hourly run):

- `git diff --check` passed.
- `plutil -lint` passed for English and Japanese `Localizable.strings`.
- `swift test` passed: 200 XCTest tests, 0 failures.
- `swift build --disable-sandbox` passed.
- App-bundle helper smoke was not rerun in this slice because no fresh Launch
  Services hypothesis or normal desktop verification environment was available.

Latest app-bundle helper smoke result (2026-05-21 current run):

- `git diff --check` passed.
- `plutil -lint` passed for English and Japanese `Localizable.strings`.
- `swift test` passed: 180 XCTest tests, 0 failures.
- `swift build --disable-sandbox` passed.
- `./script/build_and_run.sh --verify` built the local bundle but Launch
  Services returned `kLSNoExecutableErr`.
- `./script/build_and_run.sh --stop` completed afterward. A follow-up
  `pgrep -fl HazakuraLLMManager` check could not read the process list because
  `sysmond` was unavailable in this environment.

Treat the helper launch path as a current automation-level regression again.
The generated bundle still contains `Info.plist`, the `HazakuraLLMManager`
executable, and English/Japanese localization resources, so this remains a
Launch Services smoke issue rather than source-build proof. It is not a manual
UI smoke pass and should not be treated as packaged release evidence.

## Manual UI Smoke Targets

When automation has access to a normal app launch, or when the user reports a
visual rough edge, prefer these targets:

- first launch with no runtime or model selected
- Setup Guide inspector open, close, and reopen from toolbar and Dashboard
- Runtime row with Installed and manual Choose controls present
- Japanese and English Settings language changes
- menu bar status, Start, Stop, Restart, Check Health, copy actions, Open Window,
  and Quit
- reduced toolbar state: Setup Guide, profile import/export, and Copy remain
  reachable while lifecycle, health, command reveal, and log clear are absent
- Dashboard launch command preview and endpoint copy controls
- Logs empty state, append state, and clear action

Do not claim a UI smoke target passed unless the run actually launched and
observed the app or the user supplied specific visual evidence.

## External Proposal Intake

The 2026-05-20 external improvement proposal is accepted as input for
pre-release rough-edge discovery, not as an automatic mandate to implement every
item. Automation should classify each item into one of the buckets below before
acting.

The 2026-05-21 Gemini v1.0 polish review is also accepted as backlog input.
Its localization, launch-helper, and toolbar/log-policy notes are useful, but
automation must keep the existing source-only and UI-localization boundaries.
Treat repo evidence as the deciding source when a proposal names a likely
cause.

The 2026-05-21 DeepSeek v1.0 polish review is accepted as a second backlog
input. Its strongest repo-grounded findings are copy feedback inconsistency,
localized UI gaps in preset and tooltip copy, duplicate localization keys,
disabled button styling, and stopped-state background animation behavior.
Automation should use these as small smoke-polish candidates, not as permission
for broad redesign.

The 2026-05-21 Chika v1.0 polish review is accepted as a third backlog input.
Its highest-value contribution is release-evidence hygiene: docs must agree
that SwiftPM verification passes while helper launch smoke is mixed/failing and
normal desktop manual smoke remains the packaged-release gate. It also adds
small daily-use candidates for health-check availability, Setup Guide empty
states, endpoint-copy accessibility, logs retention wording, and checkpoint
string centralization.

The 2026-05-22 Chika release-readiness follow-up was reviewed as external
release judgment, not as permission to broaden scope. Several concrete findings
were already covered on `main` after the reviewed snapshot: copy feedback,
running-only health checks, Setup Guide no-runtime wording, endpoint copy
accessibility, logs retention wording, source-checkpoint centralization,
localized preset descriptions, duplicate localization key cleanup, and toolbar
reduction. The v1.0 release posture is now decided: `v1.0.0-rc.1` is
source-only, while packaged release remains a later handoff. Keep the remaining
current signals narrow: normal desktop/manual UI smoke is still missing, helper
launch smoke is still not packaged-release proof, and Hugging Face setup
guidance / Homebrew command placement remain human-decision items.

### 2026-05-21 Gemini Intake

Accepted for automation:

- verify language switching across one visible surface at a time, especially
  sidebar labels, menu bar actions, toolbar labels, Settings text, Setup Guide
  copy, Endpoint headings, and HelpTooltip popovers
- keep the focused localization resource checks current for English and
  Japanese `Localizable.strings`; duplicate keys, key parity, and
  format-placeholder parity are covered
- replace one visible hard-coded app UI string group with explicit localized
  keys when the string is not runtime log text, copied shell text, profile JSON,
  or adapter-owned diagnostic payload
- keep HelpTooltip titles, descriptions, tips, and section headings localized
  through English/Japanese app UI resources while preserving the boundary that
  runtime logs, copied shell text, profile JSON, and adapter diagnostics are not
  localized
- modernize deprecated SwiftUI APIs such as `onChange` only when the current
  toolchain emits a warning or the change stays mechanical and verified by
  build/tests
- investigate `kLSNoExecutableErr` only through a fresh, bounded hypothesis,
  such as comparing absolute-path `open` with the current helper invocation or
  checking bundle metadata after rebuild

Conditionally accepted:

- ad-hoc codesigning may be used only as a local diagnostic for the helper
  smoke. Do not present it as signing/notarization readiness, and do not add it
  to the default script unless it is proven necessary and harmless.
- install-source and update-readiness advisory text may gain localized
  presentation only if the app keeps adapter diagnostics and copied command
  text outside the localization scope.

Deferred or human decision:

- toolbar removal beyond the current reduced utility strip remains a product
  decision; automation may polish Setup Guide, profile import/export, and copy
  controls, but must not add broad toolbar controls without approval
- log persistence is post-v1 unless the user explicitly reopens it; keep
  in-memory logs and clear-log behavior simple
- signing, notarization, packaging, zip/dmg/checksum creation, and official
  binary distribution remain outside automation unless there is a release
  handoff for that exact work

### 2026-05-21 DeepSeek Intake

Accepted for automation:

- make copy feedback consistent for one copy-action family at a time. The
  Setup Guide Homebrew command and Endpoint destination copy controls now show
  copied feedback, and the Dashboard Command Preview now confirms launch-command
  copies. The main window toolbar Copy menu now confirms command, endpoint,
  environment, health-check, and AI Mobile smoke copies. The menu bar copy
  actions now confirm command, endpoint, environment, health-check, and AI
  Mobile smoke copies. Profile import/export uses file-flow status messages
  rather than pasteboard copy feedback.
- add or tighten accessibility labels and hints for the menu bar control
  surface, one action group at a time. The menu bar copy-action group now has
  localized hints for launch command, endpoint, environment, health-check curl,
  and AI Mobile smoke curl copy actions.
- localize preset description copy in `ConfigurationView` instead of keeping
  `presetDescriptionJP` Japanese-only when the app language is English.
- remove duplicate English/Japanese `Localizable.strings` keys such as the
  repeated `Process Status` entries, then keep parity coverage in tests or a
  focused validation helper.
- keep disabled-state visibility for shared button styles covered: inactive
  `PrimaryButtonStyle` / `SecondaryButtonStyle` controls now retain readable
  labels and outlines without changing behavior.
- keep stopped-state Aurora/background rendering covered: the decorative
  background timeline now pauses while the server is stopped, keeping the idle
  window calmer without changing lifecycle behavior.
- modernize deprecated SwiftUI APIs such as `onChange` when the current
  toolchain reports a warning or the change is purely mechanical.

Conditionally accepted:

- source checkpoint/version display may be centralized only if it stays within
  source-checkpoint messaging and does not imply packaged artifact metadata.
  The in-app Settings source checkpoint now reads from one tested core metadata
  value; build-script injection or `Info.plist` version plumbing still needs a
  narrow design before automation changes it.
- `Show Command` toolbar behavior may be clarified only after evidence shows
  the current Dashboard reveal action is confusing in normal use.

Human decision:

- toolbar simplification is decided for the current lane: keep Setup Guide,
  profile import/export, and copy actions only. Automation may polish those
  controls or record smoke evidence, but should not add lifecycle, health,
  command-reveal, or log-clear actions back without approval.
- log persistence remains deferred; keep the v1 path on bounded in-memory logs
  unless the user explicitly changes the product requirement.

### 2026-05-21 Chika Intake

Accepted for automation:

- keep README, current status, troubleshooting, automation backlog, and roadmap
  aligned on helper-smoke status: SwiftPM tests/build pass, helper launch smoke
  has mixed/failing Launch Services evidence, and normal desktop/manual launch
  plus clean quit remain required before packaged release
- add a dated manual-smoke record when a normal macOS desktop pass is actually
  performed; do not infer UI smoke from SwiftPM or helper-script evidence
- keep health-check enabled states aligned with the chosen product rule:
  manual checks are disabled until the server is running
- keep the Setup Guide no-installed-runtime empty state covered: it now states
  that no installed `llama-server` was detected while keeping manual Choose
  available and avoiding package-manager execution
- add an explicit accessibility label/hint or visible `Label` for icon-only
  copy controls such as the Setup Guide endpoint copy action
- keep the Logs retention caption covered: it now states that logs are kept in
  memory and are not saved automatically
- keep source-checkpoint display centralized in app code without build-script,
  `Info.plist`, or packaged-artifact claims

Already covered on current `main`:

- copy feedback consistency across Endpoint, Dashboard command preview, toolbar
  copy menu, menu bar copy actions, and Setup Guide Homebrew command copy
- running-only health-check availability through the shared controller rule
- Setup Guide no-installed-runtime empty-state wording
- Setup Guide endpoint copy accessibility
- Logs memory-only retention caption
- source-checkpoint display centralized in app code
- preset description localization and duplicate localization key cleanup
- HelpTooltip title, description, tips, and `Description` / `Tips` headings
  localized through app UI resources
- Endpoint advanced section headings use standard English localization keys
  instead of bilingual literal keys
- reduced toolbar scope: Setup Guide, profile import/export, and copy actions
  only
- main toolbar icon-only controls now expose localized accessibility labels and
  hints for Setup Guide, active profile import/export, and the Copy menu

Human decision:

- decide whether the in-app Hugging Face search link stays, is demoted to docs,
  or gets stronger no-download/no-catalog wording
- decide whether the Homebrew command copy button remains in Setup Guide or
  moves to docs-only setup guidance

### Automatable P0/P1 Candidates

These can be selected by automation when they are narrowed to one view, one
behavior, or one testable controller boundary:

- accessibility labels, values, and hints for toolbar buttons, sidebar items,
  menu bar actions, copy buttons, status badges, health status, log rows, and
  Setup Guide step cards
- removal of any newly discovered force unwrap in app UI code. The known static
  URL construction in the Setup Guide model-search link is covered.
- one focused `ServerController` thread-safety or lifecycle hardening slice,
  backed by tests or a small audit note
- graceful child-process shutdown fallback, app-termination cleanup, or
  repeated start/stop/restart edge handling when testable without real
  `llama-server`
- About/settings version information if it can be implemented without signing,
  notarization, packaging, or release-asset claims (covered for the current
  source-only checkpoint and no-packaged-app boundary)
- copy feedback consistency for one family of copy controls at a time,
  prioritizing any newly surfaced profile-adjacent pasteboard action
- profile import/export file-flow feedback is covered for the current toolbar
  and menu bar entry points by mirroring the existing profile message outside
  the Configuration profile panel
- shared pasteboard-copy helper extraction when it reduces real duplicated UI
  code without changing behavior (covered for the current toolbar, menu bar,
  endpoint, command-preview, and Setup Guide copy surfaces)
- improved error visibility for one existing error surface, such as launch
  errors or profile import/export messages
- one explicit localization gap in app UI, such as sidebar labels, preset
  helper text, HelpTooltip text, or endpoint section headings
- preset description localization when the selected app language is English or
  Japanese
- Setup Guide follow-up wording only if the no-installed-runtime empty state is
  observed as unclear in manual smoke
- icon-only copy action accessibility labels and hints
- disclosure header expanded/collapsed accessibility values are covered for the
  current Advanced Settings and Advanced Connection Details controls
- one focused language-switching verification note for a named view or control
  surface, followed by a small fix only when the mismatch is observed
- localization key and format-placeholder parity coverage for English and
  Japanese app UI resources is covered; revisit only when a new localization
  resource class appears
- endpoint-use guidance that stays local and does not introduce chat, proxy,
  model download, or remote exposure behavior
- fake-driven `ServerController` state-transition tests for existing start,
  stop, restart, early-crash, or port-conflict-like behavior
- lightweight `Logger` instrumentation for app lifecycle or controller events
  when it is useful for debugging and does not replace the visible `LogBuffer`
- Aurora/background animation throttling or stopped-state static rendering is
  covered for the current stopped-state timeline; revisit only if manual smoke
  shows the idle surface is still visually noisy
- shared button disabled-state visibility is covered for the current
  `PrimaryButtonStyle` / `SecondaryButtonStyle` surfaces
- logs retention wording is covered for the current Logs destination; revisit
  only if manual smoke shows the caption is hidden, clipped, or misleading

### Needs Human Decision First

Do not start these from automation unless the user explicitly approves the exact
slice:

- custom app icon or brand asset creation
- first-run Welcome screen that changes onboarding flow beyond the existing
  Setup Guide inspector
- toolbar removal beyond the current reduced utility strip, or menu-bar-only
  lifecycle
- launch-at-login, automatic restart policy, endpoint auto-polling, multiple
  profiles, or window-close education dialogs
- log persistence or automatic log-file writing
- SwiftLint, SwiftFormat, or any new tool that changes developer workflow,
  dependency behavior, CI requirements, or formatting churn
- entitlements, hardened runtime, signing, notarization, zip, dmg, checksums,
  tags, GitHub Releases, or App Store preparation
- broad Core-module localization of adapter diagnostics, runtime logs, copied
  commands, profile JSON, or error payloads; the current localization boundary
  is UI labels and controls only

These items block only the exact slice that needs the decision. They should not
stop automation from choosing an unrelated P0/P1 candidate, improving docs
consistency, or recording focused smoke evidence.

### Useful But Low Priority

These are valid polish only after P0/P1 candidates are quiet or a concrete user
report makes them urgent:

- Dynamic Type and large accessibility text clipping checks
- light-mode contrast review for hard-coded white/black opacity surfaces
- window frame restoration
- SwiftUI previews or snapshot-style view checks
- CI macOS version matrix expansion
- memory-pressure log trimming or high-volume log throttling

### Proposal Boundaries

When working from the external proposal, automation must preserve these
boundaries:

- do not turn accessibility or localization into a full UI redesign
- do not add product features outside local `llama-server` supervision
- do not treat signing, notarization, or packaged release work as approved
- do not localize technical logs or copied shell commands unless a later product
  decision changes that boundary
- do not install linters, formatters, package-manager tools, or runtime tools
  without explicit approval

## Good Automation Slices

Pick one small item from this list when no higher-priority build or test failure
exists.

### UI And Localization

- Fix one clipped or awkward Japanese label in a named view.
- Add a missing English/Japanese localization key for an already-visible UI
  label.
- Replace one hard-coded app UI string with an explicit localized key when the
  string is visible to users and not adapter-owned diagnostic text.
- Localize one HelpTooltip or preset helper text group at a time, keeping
  translations reviewable.
- Keep language switching scoped to UI labels and controls; do not localize
  runtime logs, copied commands, profile JSON, or adapter-owned diagnostic text.
- Tighten Setup Guide inspector spacing only when a concrete overflow or
  crowding case is visible.
- Keep the toolbar reduced to Setup Guide, profile import/export, and copy
  actions unless a human explicitly reopens toolbar scope.

### Menu Bar And Toolbar

- Verify that menu bar actions mirror existing controller behavior and disabled
  states.
- Fix stale or inconsistent menu bar labels, status presentation, or copy
  wording.
- Improve `Open Window` only when hidden/backgrounded window behavior is
  reproducibly confusing.
- Prefer making toolbar actions clearer over adding new actions.

### Runtime Setup

- Improve the Installed Runtime empty state further only if manual smoke shows
  the current no-installed-runtime wording is unclear.
- Keep runtime/model path rows compact; do not reintroduce a Recent menu unless
  a concrete daily-use path-switching need outweighs the width cost.
- Improve runtime/model selection hints only when the existing blank,
  non-`.gguf`, directory, missing-file, or non-executable-file guidance leaves a
  concrete gap.
- Keep setup guidance advisory. Do not run Homebrew, Git, downloads, or model
  search.

### Health, Endpoint, Copy, And Logs

- Fix stale health presentation when process state changes, if a concrete case
  is observed.
- Improve endpoint-unavailable wording when a specific invalid host or port
  configuration is confusing.
- Tighten copy button labels or disabled states when the copied target is not
  obvious.
- Add feedback for one copy action family when the user cannot tell whether a
  copy succeeded. The shared pasteboard write helper is already covered; future
  copy work should address a visible feedback or disabled-state ambiguity.
- Improve one visible error surface when truncation hides the next action.
- Keep log buffering bounded and clear-log behavior simple; do not add log
  persistence without a human decision.

### Accessibility

- Add accessibility labels to one visible control group at a time.
- Add accessibility values for status and health indicators.
- Combine stream and text into one useful accessibility label for log rows.
- Add Setup Guide step-card accessibility hints for complete and incomplete
  states.
- Verify changes with build/tests and, when possible, one VoiceOver-oriented
  manual smoke note.

### Controller And Process Robustness

- Remove force unwraps in app UI code when a safe fallback is obvious.
- Add one fake-driven controller state-transition test before changing process
  lifecycle behavior.
- Harden app termination or graceful shutdown only when the behavior is
  bounded, testable, and does not add hidden automatic restart.
- Improve `ConfigurationStore` failure visibility only when the user-facing
  reporting surface is clear; do not invent a broad persistence subsystem.

### Performance

- Keep decorative animation paused when the server is stopped; revisit only if
  manual smoke shows the idle background remains visually noisy.
- Improve log rendering only when a concrete high-volume output issue is
  observed or a focused test can prove the behavior.
- Keep performance work local; do not add benchmarking dashboards or automatic
  optimization.

### Profiles

- Improve `.lantern-profile.json` import/export UI wording when portability
  warnings are confusing.
- Add tests for one profile warning or preview edge case if the behavior is
  concrete.
- Do not add multiple-profile management or profile schema changes without a
  human handoff.

### v0.9 Update Readiness

- Add or refine a non-mutating source/readiness explanation for Homebrew,
  MacPorts, source builds, manual binaries, or unknown sources.
- Keep `llama.cpp` Check for Updates advisory: it may fetch official latest
  release metadata only after the user presses the button, compare `bNNNN`
  build numbers when possible, and must not execute updates.
- Add fake-driven tests for update-readiness planning or unsupported-source
  messaging.
- Keep all update-readiness work advisory. Do not execute package-manager,
  Git, download, or binary replacement commands.

### Packaging Prep

- Keep `script/build_and_run.sh` aligned with SwiftPM resources and app-bundle
  layout.
- Improve local launch-smoke cleanup only if a new leftover-process or failed
  cleanup case is observed.
- Document normal-desktop packaged-release evidence when the user supplies it.
- Do not create zip, dmg, signing, notarization, checksums, tags, or GitHub
  Releases without an explicit release handoff.

## Slice Acceptance

A good automated polish slice should answer all of these:

- What exact rough edge is being fixed?
- Which view, command, or doc owns it?
- How was it verified?
- Did it avoid runtime installs, package-manager mutation, model downloads,
  GitHub mutation, and hidden background behavior?
- Is the remaining risk recorded if verification was only source-level?

If these cannot be answered, do a verified no-op or update this backlog with
the missing observation instead of guessing.

## Report Shape

Automation should end with:

- changed files
- smoke or test commands run
- any visual or manual evidence used
- remaining formal-release blocker, if touched
- next smallest rough edge, if obvious
