# Automation Smoke Backlog

This document gives recurring automation concrete rough-edge discovery and
polish work before a user-facing packaged release. It is intentionally narrower
than the full roadmap.

Use this after reading `docs/current_status.md`, `docs/roadmap.md`, and
`docs/development_loop.md`.

## Purpose

Automation should help expose and fix small product-quality issues while the app
is still pre-1.0:

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

Latest automated smoke result (2026-05-21 current run):

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
- toolbar Start, Stop, Restart, Check Health, Setup Guide, Clear Logs, Profile,
  and Copy menus
- Dashboard launch command preview and endpoint copy controls
- Logs empty state, append state, and clear action

Do not claim a UI smoke target passed unless the run actually launched and
observed the app or the user supplied specific visual evidence.

## External Proposal Intake

The 2026-05-20 external improvement proposal is accepted as input for
pre-release rough-edge discovery, not as an automatic mandate to implement every
item. Automation should classify each item into one of the buckets below before
acting.

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
  notarization, packaging, or release-asset claims
- copy feedback consistency for one family of copy controls at a time
- shared pasteboard-copy helper extraction when it reduces real duplicated UI
  code without changing behavior (covered for the current toolbar, menu bar,
  endpoint, command-preview, and Setup Guide copy surfaces)
- improved error visibility for one existing error surface, such as launch
  errors or profile import/export messages
- one explicit localization gap in app UI, such as sidebar labels, preset
  helper text, HelpTooltip text, or endpoint section headings
- endpoint-use guidance that stays local and does not introduce chat, proxy,
  model download, or remote exposure behavior
- fake-driven `ServerController` state-transition tests for existing start,
  stop, restart, early-crash, or port-conflict-like behavior
- lightweight `Logger` instrumentation for app lifecycle or controller events
  when it is useful for debugging and does not replace the visible `LogBuffer`
- Aurora/background animation throttling or stopped-state static rendering when
  verified by code review, build, and a focused manual smoke

### Needs Human Decision First

Do not start these from automation unless the user explicitly approves the exact
slice:

- custom app icon or brand asset creation
- first-run Welcome screen that changes onboarding flow beyond the existing
  Setup Guide inspector
- toolbar removal, toolbar demotion, or menu-bar-only lifecycle
- launch-at-login, automatic restart policy, endpoint auto-polling, multiple
  profiles, or window-close education dialogs
- SwiftLint, SwiftFormat, or any new tool that changes developer workflow,
  dependency behavior, CI requirements, or formatting churn
- entitlements, hardened runtime, signing, notarization, zip, dmg, checksums,
  tags, GitHub Releases, or App Store preparation
- broad Core-module localization of adapter diagnostics, runtime logs, copied
  commands, profile JSON, or error payloads; the current localization boundary
  is UI labels and controls only

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
- Reduce toolbar density only when a specific repeated-use problem is visible;
  do not remove the toolbar without a human decision.

### Menu Bar And Toolbar

- Verify that menu bar actions mirror existing controller behavior and disabled
  states.
- Fix stale or inconsistent menu bar labels, status presentation, or copy
  wording.
- Improve `Open Window` only when hidden/backgrounded window behavior is
  reproducibly confusing.
- Prefer making toolbar actions clearer over adding new actions.

### Runtime Setup

- Improve the Installed Runtime empty state when `llama-server` is not found.
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

- Throttle or pause decorative animation when the server is stopped, provided
  the app still builds and the visual result is acceptable in manual smoke.
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
