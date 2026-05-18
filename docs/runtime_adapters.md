# Runtime Adapters

Runtime adapters describe how Hazakura Lantern talks to an existing local
runtime. They are not installers, downloaders, package managers, proxies, or
runtime catalogs.

The only implemented adapter is `llama-server`.

## Adapter Responsibilities

An adapter owns the runtime-shaped parts of the control loop:

- a stable adapter id and display name
- supported model file types
- configuration validation before command construction
- launch preflight checks that belong to the runtime shape
- launch command construction as an argument array, not a shell string
- endpoint display data, including optional health-check and client smoke URLs
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
- rejects URL-like or `host:port` host values before command construction so
  the configured port remains the single port source
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
