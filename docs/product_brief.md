# Product Brief

## Positioning

Hazakura Lantern is a small Mac app for lighting up a local LLM server endpoint.
It is closer to a server control panel than to a model playground.

It exists so apps such as Hazakura AI Mobile, Habitat, Nenrin, Codex, Hermes,
and other local clients can point at the selected runtime's Mac-hosted endpoint
when it is running, while the model, runtime command, logs, and endpoint remain
visible at the user's desk.

Conceptually, it puts a small lantern beside local LLM work: enough light to see
the runtime and model clearly, without turning the app into a model platform.

## First Slice

The first implementation proves the core loop:

1. Choose a `llama-server` binary.
2. Choose a `.gguf` model.
3. Choose a port and launch settings.
4. Start the child process.
5. Stop it cleanly.
6. Read stdout/stderr into the GUI.
7. Copy the endpoint for external clients.

## Adapter Boundary

The app keeps runtime-specific command construction behind `RuntimeAdapter`.
Only `LlamaServerAdapter` is implemented for v0.

Near-term work should keep improving the existing `llama-server` path before
adding runtime breadth. The next product value is model-family guidance for
existing GGUF models: visible recommended settings, option compatibility, and
advisory presets that help a user start from a sensible configuration without
making Lantern a model manager.

A second runtime such as an MLX-based server is deferred until after the
`llama-server` preset, runtime-advisory, toolbar, and guarded update lanes are
useful. It still requires a design note that fixes the command, model
reference, endpoint, health, and profile boundaries before implementation.

Custom command profiles, Ollama, runtime catalogs, model downloads, unattended
package-manager mutation, and broad adapter expansion are not current roadmap
lanes. A guarded `llama-server` update workflow is allowed only after Lantern
can explain the selected runtime source, show what will change, and require
user confirmation.

## Deferred Work

- YAML import/export
- launch at login
- auto restart
- automatic endpoint health polling
- metrics and benchmark display
- multiple profile management
- LAN exposure controls
