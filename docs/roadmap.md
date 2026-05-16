# Roadmap

This roadmap keeps Hazakura Lantern pointed at a small, useful local tool. It
is not a promise of release dates.

## Product Direction

Hazakura Lantern should make a local LLM runtime visible and controllable
without becoming a model platform.

Core promise:

- light up the selected model, runtime command, logs, and endpoint
- keep local server control understandable at a glance
- make the endpoint easy for other local clients to reuse
- avoid hidden shell behavior or surprising background automation

The product should feel like a calm local control surface, not a chat app, model
marketplace, or orchestration system.

## Current Lane: v0 Hardening

The current lane is v0 hardening. Work here until the single-runtime control loop
is boring, reliable, and covered by focused tests.

Done or mostly done:

- SwiftPM macOS app skeleton
- `llama-server` adapter
- executable and `.gguf` model path fields
- launch command preview
- direct `Process` launch without shell interpolation
- start, stop, restart, pid, status, and in-memory logs
- local endpoint and OpenAI-style environment snippet
- `UserDefaults` configuration persistence
- app bundle launch helper
- focused core unit tests

Still needed before treating v0 as quiet:

- stronger tests for invalid threads and GPU layer values
- test coverage for endpoint and environment snippet behavior
- clearer handling for missing runtime/model paths in the UI
- safer restart behavior if stop/start races are observed
- small launch smoke documentation that does not require a real model
- current-status cleanup after each meaningful implementation slice

## v0 Exit Criteria

v0 is ready to call stable enough for local use when:

- `swift test` passes.
- `swift build --disable-sandbox` passes.
- The app can be launched with `./script/build_and_run.sh --verify`.
- A user can configure an existing `llama-server` binary and `.gguf` model.
- Invalid configuration is surfaced before launch where practical.
- Logs remain bounded and can be cleared.
- Stop and restart leave the UI in a predictable state.
- The generated command, base URL, and environment snippet match the selected
  configuration.
- README, current status, development loop, and this roadmap agree on scope.

## v0.1: Daily-Use Polish

Only start this lane after v0 hardening is quiet.

Candidate work:

- endpoint health indicator using the existing local health URL
- recent runtime and model path lists
- clearer launch and termination error states
- safer restart timing or explicit restart state
- copy affordances for command, base URL, and environment snippet
- small UI polish for repeated local use

Keep this lane local-only. Do not add LAN exposure, authentication, or background
restart policy here.

## v0.2: Profiles And Portability

Start this only after the app feels dependable for one local runtime.

Candidate work:

- multiple local profiles
- profile rename, duplicate, and delete
- YAML or JSON import/export for profiles
- portable profile format documentation
- tests that preserve command construction and persistence compatibility

This lane should still manage existing local runtimes. It should not download
models or install runtime dependencies.

## v0.3: Runtime Breadth

Only consider this after the profile boundary is clear.

Candidate adapters:

- Ollama
- llama-cpp-python server
- MLX-based local servers
- custom command profiles

Each adapter needs:

- explicit command construction
- local endpoint contract
- focused tests
- docs that describe what is and is not managed

Do not add a new adapter if it forces broad architecture changes before the
existing adapter is calm.

## Later

These may be useful, but they are not near-term lanes:

- launch at login
- explicit auto-restart policy
- metrics or benchmark display
- signed release packaging
- LAN exposure controls
- optional local authentication guidance

Treat these as separate design decisions, not incidental additions.

## Non-Goals

Do not use this project for:

- chat UI
- model search or downloads
- model conversion
- bundled inference engines
- OpenAI-compatible proxy implementation
- RAG or tool execution
- remote deployment management
- cloud runtime orchestration

## Automation Guidance

Automated development should choose one small slice from the current lane. Good
next slices are:

- add focused tests for invalid numeric options
- improve validation/error presentation without changing the runtime model
- document launch smoke expectations
- harden restart behavior with a testable state transition
- update docs when implementation changes make this roadmap stale

If none of those is justified by current evidence, a verified no-op is a valid
result.
