# Hazakura Lantern Roadmap

This roadmap keeps Hazakura Lantern narrow, deep, and useful.
It is not a promise of release dates.

Hazakura Lantern should become a calm Mac-first control surface for local LLM
runtimes that already exist on the user's machine. It should not become a model
platform, runtime installer, inference engine, chat app, marketplace, proxy, or
agent orchestration layer.

The guiding idea:

> Lantern lights the local runtime table. It does not become the engine.

## Product Thesis

Hazakura Lantern is a thin, reliable app that assembles existing local runtime
pieces into one understandable control surface:

```text
existing runtime binary or command
+ existing model or server configuration
+ visible launch state
+ logs
+ endpoint
+ reusable client snippets
= one calm local control panel
```

The project wins by making a small number of things boring and trustworthy:

- the selected runtime command is explicit
- the selected model or server target is visible
- start, stop, and restart are predictable
- logs are bounded and useful
- the local endpoint is easy to copy and reuse
- failures are understandable before users reach for a terminal
- nothing surprising happens in the background

It does not need to predict the winning runtime stack. Runtimes, models,
quantization formats, and server APIs will keep changing. Lantern should benefit
from that change by wrapping what exists, not by trying to own the stack.

## Roadmap Rule: Depth Before Breadth

Every roadmap item must strengthen at least one of these:

1. safer launch
2. clearer runtime state
3. more predictable process control
4. better endpoint reuse
5. more portable profiles
6. thinner adapter boundaries
7. more accurate documentation

If an item does not improve one of those, park it.

Do not add runtime breadth while the single-runtime loop still feels surprising.
A new adapter is allowed only when it can be added without changing the core
lifecycle model.

## Product Boundary

### Lantern owns

- profile storage
- command construction and command preview
- path validation for user-selected files and executables
- direct process lifecycle control where applicable
- PID, status, health, and restart state
- bounded logs and clear log reset behavior
- local base URL display
- reusable environment snippets for local clients
- adapter documentation and focused tests
- a small Mac UI that makes the above visible

### Lantern does not own

- model search or downloads
- model conversion
- bundled inference engines
- runtime installation or updates
- cloud runtime orchestration
- OpenAI-compatible proxy implementation
- chat UI
- RAG or tool execution
- benchmarking as a product feature
- full environment inventory
- remote deployment management

### Lantern may pass through

- user-provided runtime flags
- user-provided server commands
- runtime-specific endpoints when documented
- runtime-specific health URLs when adapter-scoped
- custom command profiles when the risks are visible

Pass-through is not ownership. If a runtime changes, Lantern should fail clearly,
not silently invent behavior.

### Lantern may observe

- selected runtime executable version when it can be checked safely
- user-declared install source, such as Homebrew, source build, or manual binary
- latest available version metadata from an official source when network access
  is explicit and adapter-scoped
- advisory "update available" status for registered runtimes
- setup guidance that points users toward official runtime installation docs

Observation is not management. Lantern may tell users that a runtime appears
old, missing, or installed in an unusual way. It should not run installers,
upgrade runtimes, mutate package managers, or hide where a runtime came from.

## Current Lane: v0 - Make One Runtime Boring

Stay here until the `llama-server` path is quiet, predictable, and documented.
The goal is not feature breadth. The goal is a single-runtime control loop that
feels safe to use every day.

Already done or mostly done:

- SwiftPM macOS app skeleton
- `llama-server` adapter
- executable and `.gguf` model path fields
- launch command preview
- direct `Process` launch without shell interpolation
- start, stop, restart, PID, status, and in-memory logs
- local endpoint and OpenAI-style environment snippet
- copied endpoint/client URLs keep local defaults copyable while reflecting a
  configured reachable host
- local endpoint health-check URL and copyable curl smoke command
- manual endpoint health status check
- health status reset on start, stop, and termination so stale health does not
  survive process state changes
- endpoint health status presentation contract for title, detail, icon, and
  tone covered by focused tests
- `UserDefaults` configuration persistence
- recent executable/model path menus stored outside exported runtime
  configuration
- app bundle launch helper
- bounded log buffering and clear-log behavior covered by focused tests
- focused core unit tests
- focused tests for invalid numeric options, endpoint URLs, and environment
  snippets
- focused tests for copied endpoint host behavior
- focused tests for quoted launch command preview display
- focused tests for missing runtime/model paths and invalid context size
- focused tests for launch configuration error descriptions
- focused tests for file-preflight launch failure descriptions
- focused tests for process-run launch failure descriptions
- real-model-free fake runtime smoke test for adapter-built launch commands
- initial v0.2 runtime profile document schema version contract
- stable readable JSON export/import helpers for runtime profile documents
- typed import failures for missing or unsupported runtime profile schema
  versions
- typed import failures for missing or unsupported runtime profile runtime
  kinds, keeping imported profiles on the current `llama-server` boundary
- active runtime profile persistence fallback through the configuration store
- profile JSON shape and portability boundaries documented with a readable
  schema-version `1` example
- suggested profile export filename contract using `.lantern-profile.json`,
  covered by focused tests before file-based UI is added
- supported profile filename and URL recognition for `.lantern-profile.json`,
  covered by focused tests before file-based import UI is added
- profile-file import preflight that rejects unsupported file names before
  decoding JSON contents, covered by focused tests before file-based import UI
  is added
- profile-file import preview that validates suffix, schema version, non-blank
  profile name, and runtime kind before requiring the full runtime configuration
  to decode
- profile local file reference contract for runtime executable and model paths,
  covered by focused tests before portability warnings or file UI are added
- profile-level launch command preview through the matching adapter, covered by
  focused tests before profile UI is added
- minimal active-profile import/export UI for `.lantern-profile.json` files
  without adding multiple-profile management
- adapter-owned endpoint display contract for base URL, environment snippet,
  health-check curl, and AI Mobile smoke command generation, covered by focused
  tests without adding another runtime adapter
- explicit adapter-owned validation contract that can be tested before command
  construction, preserving `llama-server` validation without adding runtime
  breadth

Finish before leaving v0:

- surface missing runtime and missing model paths clearly before launch
- make restart state explicit enough to avoid stop/start race confusion
- fix or externally verify the app-bundle launch smoke path
- keep README, current status, development loop, and roadmap in agreement

v0 exit criteria:

- `swift test` passes
- `swift build --disable-sandbox` passes
- `./script/build_and_run.sh --verify` launches the app path successfully
- a user can configure an existing `llama-server` binary and `.gguf` model
- invalid configuration is surfaced before launch where practical
- generated command, base URL, and environment snippet match selected settings
- stop and restart leave the UI in a predictable state
- logs remain bounded and can be cleared
- docs match the actual app behavior

Do not add another runtime adapter before this is true.

## v0.1 - Daily-Use Confidence

Status: mostly satisfied for the source-only v0.2 checkpoint. Remaining ideas
from this lane are not current defaults; use them only when a concrete
repeated-use ambiguity is observed.

Purpose:

Make the existing one-runtime app pleasant enough for repeated local use.

Candidate work:

- endpoint health presentation improvements using the existing local health URL
- clearer launch, crash, and termination states
- lightweight runtime setup guidance for users who do not know how to install a
  server runtime yet
- copy buttons for command, base URL, and environment snippet
- small UI polish for repeated local use when a specific ambiguity is visible
- clearer empty states for missing runtime/model paths
- a compact troubleshooting section in docs

Deferred from this lane:

- endpoint health auto-polling
- selected runtime version display unless a later adapter contract defines a
  safe, advisory, timeout-bounded check

Keep this lane local-only. Do not add LAN exposure, authentication, automatic
background restart policy, runtime installers, or automatic runtime updates
here.

Completion criteria:

- users can tell whether the runtime is stopped, starting, healthy, unhealthy,
  or terminated
- common launch failures point to a practical next step, including process-run
  errors surfaced by macOS
- repeated start/stop/restart use does not make the UI ambiguous
- users can see what runtime binary they selected and, where safe, what version
  it reports
- copying endpoint details is obvious
- docs cover the daily-use loop without becoming a runtime tutorial

## v0.2 - Profile Contract And Portability

Status: source-only `v0.2.0-alpha.1` checkpoint.

Purpose:

Turn one working configuration into portable local profiles without expanding
runtime scope too early.

Candidate work:

- profile-level command preview
- JSON profile export/import
- file-based profile export/import UI boundaries
- migration behavior for future profile schema changes
- migration tests for persisted settings
- tests that preserve command construction compatibility
- profile documentation with examples

Deferred from this checkpoint:

- multiple local profiles
- profile rename, duplicate, and delete
- profile-level runtime metadata, such as install source and last observed
  runtime version

This lane still manages existing local runtimes. It should not download models,
install dependencies, or hide where a command comes from.

Completion criteria:

- the active profile can be exported, moved, backed up, and restored
- exported profile data is understandable without opening the app
- command construction is stable across persistence changes
- unsupported future profile data does not break startup
- docs clearly separate profile data from runtime/model files

## v0.3 - Adapter Boundary, Not Runtime Expansion

Purpose:

Define the adapter contract so future runtimes can be wrapped without turning
Lantern into a platform.

Candidate work:

- explicit adapter protocol or adapter-shaped boundary
- adapter-owned command construction
- adapter-owned health contract
- adapter-owned endpoint snippet behavior
- adapter-owned validation and error mapping
- tests that prove adapters do not require UI rewrites
- one experimental adapter or custom command profile only if the boundary is
  already stable

Adapter requirements:

- command construction must be explicit
- shell interpolation must stay avoided unless a custom command mode makes the
  risk visible
- lifecycle semantics must be documented
- endpoint behavior must be documented
- health behavior must be documented
- unsupported runtime behavior must fail clearly

Possible first adapter experiments:

- custom command profile
- Ollama
- llama-cpp-python server
- MLX-based local server

Prefer custom command profile if runtime churn is high. It lets users benefit
from new runtimes without Lantern pretending to understand them deeply.

Completion criteria:

- adding an adapter does not force broad architecture changes
- adapter tests catch command, endpoint, and health regressions
- UI language remains about local control, not runtime marketplace features
- docs describe what Lantern manages and what the runtime still owns

## v0.4 - Existing Runtime Aggregation

Purpose:

Support a small set of existing local runtime shapes as thin wrappers.

Candidate work:

- one or two additional well-scoped adapters
- custom command profiles with visible risk warnings
- adapter-specific docs
- adapter-specific fixture tests
- profile examples for each supported runtime shape
- compatibility notes for known runtime quirks

This is still not a model platform. Each adapter should be small enough to
remove if it becomes brittle.

Completion criteria:

- each adapter has a clear local endpoint contract
- each adapter has focused tests
- each adapter has docs that explain what is not managed
- unsupported flags and runtime-specific features are pass-through, not hidden
  product promises
- Lantern remains understandable with all adapters disabled except one

## v0.5 - Release And Trust Hygiene

Purpose:

Make the project easier to use and review without broadening scope.

Candidate work:

- signed or clearly documented unsigned local builds
- release notes
- changelog
- checksum guidance if distributing binaries
- versioned profile schema notes
- compatibility notes for runtime adapters
- advisory runtime update-check documentation that explains what is observed and
  what Lantern will not update
- issue templates that ask for command preview, logs, adapter, and profile data
- docs cleanup before public or wider use

Completion criteria:

- users understand how to install or build the app locally
- users understand what data a bug report should include
- release-to-release changes are understandable
- profile compatibility expectations are documented
- runtime update information is clearly advisory, not an automatic updater
- docs do not imply that Lantern installs, owns, or updates runtimes

## Later, Separate Design Decisions

These may become useful, but they should not slip into earlier lanes casually:

- launch at login
- explicit auto-restart policy
- LAN exposure controls
- optional local authentication guidance
- metrics or benchmark display
- signed release packaging and notarization
- richer runtime setup assistant that remains documentation-first
- opt-in runtime update notifications for registered runtimes
- richer adapter catalog
- agent-facing integration notes

Treat each as a design decision with its own trade-offs, not incidental polish.

## Non-Goals

Do not use this project for:

- chat UI
- model search or downloads
- model conversion
- bundled inference engines
- runtime installer or updater
- automatic package-manager or source-build mutation
- OpenAI-compatible proxy implementation
- RAG or tool execution
- cloud runtime orchestration
- remote deployment management
- broad machine diagnostics
- model benchmark dashboard
- plugin marketplace

## Automation Guidance

Automated development should pick one small slice from the current lane.

Good next slices:

- tighten adapter-owned lifecycle, error-mapping, or protocol boundaries with
  focused tests before adding runtime breadth; validation already has an
  initial explicit contract
- tighten copied client smoke / endpoint reuse flows only when a concrete
  copy-target ambiguity remains
- improve common launch failure messages, empty states, or setup hints only
  when a specific ambiguity is visible, without adding installer behavior
- harden restart behavior only with an observed ambiguity and a testable state
  transition
- document launch smoke expectations only when there is a fresh verification
  hypothesis or new evidence
- update current status after implementation changes

Rules for automated work:

- do not add a new adapter unless the current lane explicitly allows it
- do not add endpoint auto-polling before manual health and adapter health
  boundaries are intentionally revisited
- do not add multiple-profile management while the source-only checkpoint only
  promises active-profile import/export
- do not add model download or install flows
- do not turn advisory runtime update status into automatic update execution
- do not hide command construction
- do not change runtime ownership assumptions casually
- update tests and docs with each meaningful behavior change
- if no change is justified by current evidence, a verified no-op is acceptable

## Issue Triage Checklist

Evaluate new ideas with these questions:

1. Does this make local runtime launch safer or clearer?
2. Does this make endpoint reuse easier?
3. Does this reduce surprise around process state, logs, or restart behavior?
4. Does this preserve the existing-runtime boundary?
5. Can it be tested without requiring a real model download?
6. Can it be documented without turning Lantern into a runtime tutorial?
7. If it checks runtime versions or update availability, is that advisory and
   adapter-scoped?
8. Will it still make sense when runtimes evolve?

If most answers are no, defer the idea even if it is interesting.

## v1 Shape

A narrow successful Lantern v1 looks like this:

- Mac-first local app
- existing runtimes only
- explicit command preview
- predictable process lifecycle
- clear local endpoint reuse
- portable profiles
- bounded logs
- small, documented adapter set
- advisory runtime version and update awareness
- no hidden shell behavior
- no model marketplace
- no runtime installation
- no cloud orchestration

The product should feel like a lantern on the desk: it makes the local runtime
visible, warm, and usable, while letting the engine underneath keep evolving.
