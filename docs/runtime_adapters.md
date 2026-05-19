# Runtime Adapters

Runtime adapters describe how Hazakura Lantern talks to an existing local
runtime. They are not installers, downloaders, package managers, proxies, or
runtime catalogs.

The only implemented adapter is `llama-server`.

## Adapter Lifecycle Classes

Use these classes before adding runtime breadth. A future adapter should name
which class it belongs to before implementation starts.

### Child-Process Adapter

Lantern launches and supervises the runtime process directly. It owns the child
process lifecycle for the command it started, including PID, stop, restart,
logs, endpoint display, and process-run failure wording.

The current `llama-server` adapter is a child-process adapter.

### External-Service Adapter

Lantern observes an already-running local service. It may provide endpoint
display, health checks, and copyable client snippets, but it does not own
installation, model management, service startup, or service shutdown unless a
separate design explicitly grants that ownership.

External-service adapters need lifecycle wording before code. Do not make a
service look like a child process if Lantern did not start it.

### Custom-Command Profile

Lantern launches a user-declared executable with explicit arguments and visible
risk warnings. It should not store secrets, run shell strings by default,
perform placeholder expansion, or claim runtime-specific understanding unless a
later design adds those contracts deliberately.

Custom-command profile work requires design approval before implementation.

## Adapter Responsibilities

An adapter owns the runtime-shaped parts of the control loop:

- a stable adapter id and display name
- the profile `runtimeKind` value that selects this adapter
- supported model file types
- configuration validation before command construction
- launch preflight checks that belong to the runtime shape
- launch command construction as an argument array, not a shell string
- endpoint display data, including optional health-check and client smoke URLs
  plus adapter-scoped health-check timeout hints
- the timeout hint used by both copied health-check commands and manual
  health-check requests
- process-run failure wording when macOS refuses to start the command

The app owns the shared Lantern behavior:

- editable configuration state
- active profile import/export
- direct child-process lifecycle for command-based adapters
- PID, status, restart state, and in-memory logs
- manual health-check triggering
- UI presentation and copy buttons

## Current `llama-server` Contract

The `llama-server` adapter:

- requires an executable runtime path and a local `.gguf` model path before
  launch
- builds a direct `Process` command with `-m`, `--host`, `--port`, and `-c`
- treats blank or whitespace-only hosts as the default loopback bind host for
  launch
- unwraps bracketed IPv6 host values before launch while keeping copied
  endpoint URLs URL-safe
- rejects URL-like, URL-delimiter, malformed bracket, or `host:port` host
  values before command construction so the configured port remains the single
  port source
- rejects malformed DNS labels before command construction, including
  underscores, empty labels, and leading or trailing hyphens
- keeps copied client URLs reachable through the configured host while local
  health checks use the loopback endpoint
- validates context size, port, thread count, GPU layer count, additional
  arguments, and endpoint host shape before launch
- maps process-run failures to `llama-server`-specific recovery hints

## Boundary For Future Adapters

Future adapters should start by proving the boundary with tests and docs before
adding UI breadth. A new adapter should not require broad rewrites of profile
storage, endpoint views, logs, restart state, or the app lifecycle model.

Adapters that do not launch a child process, or that manage a long-running
runtime outside Lantern, need an explicit lifecycle design first. Do not hide
that difference behind the existing command-based adapter shape.

Adapters may observe runtime facts only when the check is timeout-bounded,
adapter-scoped, and advisory. They must not install, upgrade, download, expose
LAN access, add authentication, or mutate package managers.
