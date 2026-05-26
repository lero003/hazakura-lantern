# Hazakura Lantern

Working title: **Hazakura Lantern**.

Hazakura Lantern is a macOS-only app that lights up a local LLM runtime at the
user's desk. It makes the model path, server command, logs, and local endpoint
visible without becoming a chat app or model platform.

It does not implement inference, chat, RAG, tools, or an OpenAI-compatible
proxy. The app starts and supervises an existing local server runtime so other
apps can use a stable local endpoint.

The first supported runtime is `llama-server` from `llama.cpp`.

Current checkpoint: `v1.5.1` is a public source-only checkpoint for
personal/local use. It adds explicit MIT license and contribution metadata on
top of the `v1.5.0` Smoke Console / Setup Guide checkpoint, keeps the existing
`llama-server` control boundary, and does not include a packaged `.app`, zip,
dmg, signing, notarization, checksum, or binary distribution artifact.

## Current Source Scope

- Select a `llama-server` executable.
- Select a local `.gguf` model.
- Configure port, context size, threads, GPU layers, and extra launch args.
- Start, stop, and restart the server process.
- Show stdout/stderr logs in memory.
- Show and copy the selected local OpenAI-compatible endpoint.
- Show and copy the generated launch command for inspection.
- Check the local endpoint health manually.
- Export and import the active runtime profile as `.lantern-profile.json`.
- Save the last GUI configuration with `UserDefaults`.

## Non-Goals

- No bundled inference engine.
- No persistent model library management, conversion, marketplace, ranking, or
  download history.
- No chat UI.
- No proxy layer or OpenAI API compatibility shim.
- No LAN exposure by default.
- No API key/authentication gate in the current source checkpoint.

Lantern includes a narrow, user-triggered Hugging Face GGUF acquisition page
that downloads a selected public `.gguf` file into a user-selected local
directory. This stays outside persistent model library management; see
`docs/gguf_acquisition.md`.

## Local Development

Build and test:

```bash
swift build
swift test
```

In the Codex environment, prefer:

```bash
swift test
swift build --disable-sandbox
```

Run the macOS app bundle:

```bash
./script/build_and_run.sh
```

Verify launch:

```bash
./script/build_and_run.sh --verify
```

As of the current 2026-05-24 automation run, this helper smoke builds the local
bundle, verifies that the `HazakuraLLMManager` process appears, and closes it
before exiting. Treat it as automation-level launch evidence only, not as proof
that a user-facing packaged `.app` release is ready.
`./script/build_and_run.sh --stop` also cleans up a managed runtime child
process that was launched by the app, but a normal desktop/manual launch and
clean-quit pass is still required before app-bundle, zip, dmg, signing, or
notarization release work.

Project planning and automation docs:

- `docs/current_status.md`
- `docs/roadmap.md`
- `docs/development_loop.md`
- `docs/product_brief.md`
- `docs/troubleshooting.md`
- `docs/runtime_profiles.md`
- `docs/runtime_adapters.md`
- `docs/gguf_acquisition.md`
- `docs/llama_server_presets.md`
- `docs/toolbar_and_navigation.md`
- `docs/post_public_operations.md`
- `docs/public_opening_preflight.md`
- `docs/external_review_flow.md`

Public project files:

- `LICENSE`
- `SECURITY.md`
- `CONTRIBUTING.md`

## Runtime Contract

The app launches `llama-server` directly as a child process. It passes arguments
as a process argument array, not through a shell.

Default endpoint:

```text
http://localhost:1234/v1
```

OpenAI SDK style environment values for the selected runtime endpoint:

```bash
OPENAI_BASE_URL=http://localhost:1234/v1
OPENAI_MODEL_ID=local
```

AI Mobile / OpenAI-compatible client smoke:

```bash
curl -fsS --max-time 60 http://localhost:1234/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"max_tokens":64,"messages":[{"content":"Hazakura AI Mobile runtime smoke. Reply with OK.","role":"user"}],"model":"local","stream":false}'
```

`llama-server` does not require an API key unless it is launched with
`--api-key` or `--api-key-file`. Some OpenAI-compatible client libraries still
require a non-empty client-side key value; in that case a local dummy value is
only a client compatibility setting, not Lantern authentication.

## Security Defaults

- Default host is `127.0.0.1`.
- The app does not copy model files.
- Logs are shown in memory and are not persisted automatically.
- The launch command is displayed before start so it can be inspected.

## License

Hazakura Lantern source code is licensed under the MIT License. See
`LICENSE`.

External runtimes and model files, including `llama.cpp` / `llama-server` and
local GGUF models, are not bundled by this repository and remain under their
own licenses.
