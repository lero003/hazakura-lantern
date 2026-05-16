# Roadmap

This roadmap exists to keep automated development narrow. It is not a promise
of release dates.

## v0: Local Control Loop

Goal: make one local `llama-server` process easy to inspect, start, stop, and
reuse from other local clients.

Acceptance criteria:

- Runtime executable and `.gguf` model can be selected.
- Launch command is previewed before start.
- Arguments are passed as a process argument array, not through a shell.
- Server can be started, stopped, and restarted.
- Process status, pid, and stdout/stderr logs are visible.
- The local OpenAI-compatible base URL can be copied or reused.
- Last configuration persists locally.
- `swift test` and `swift build --disable-sandbox` pass.

## v0 Hardening

Work here before adding larger features.

- Strengthen validation around paths, ports, context size, threads, GPU layers,
  and additional arguments.
- Keep process lifecycle behavior predictable when start, stop, restart, and
  unexpected exit overlap.
- Keep log memory bounded and clearable.
- Add tests around command construction and persistence boundaries.
- Improve local launch smoke checks without requiring a real model.

## v0.1 Candidate

Only after v0 hardening is quiet:

- endpoint health indicator
- recent runtime and model paths
- safer restart timing
- clearer error states
- small app polish that improves repeated local use

## Later

These are deliberately deferred:

- YAML import/export
- launch at login
- auto restart policy
- multiple profiles
- metrics or benchmark display
- additional runtime adapters
- LAN exposure controls

## Non-Goals

Do not use this project for:

- chat UI
- model search or downloads
- model conversion
- bundled inference engines
- OpenAI-compatible proxy implementation
- RAG or tool execution
- remote deployment management
