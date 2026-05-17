# Hazakura Lantern

Working title: **Hazakura Lantern**.

Hazakura Lantern is a macOS-only app that lights up a local LLM runtime at the
user's desk. It makes the model path, server command, logs, and local endpoint
visible without becoming a chat app or model platform.

It does not implement inference, model download, chat, RAG, tools, or an
OpenAI-compatible proxy. The app starts and supervises an existing local server
runtime so other apps can use a stable local endpoint.

The first supported runtime is `llama-server` from `llama.cpp`.

## v0 Scope

- Select a `llama-server` executable.
- Select a local `.gguf` model.
- Configure port, context size, threads, GPU layers, and extra launch args.
- Start, stop, and restart the server process.
- Show stdout/stderr logs in memory.
- Show and copy the runtime-provided local OpenAI-compatible base URL.
- Show and copy the generated launch command for inspection.
- Check the local endpoint health manually.
- Save the last GUI configuration with `UserDefaults`.

## Non-Goals

- No bundled inference engine.
- No model search, download, conversion, or marketplace.
- No chat UI.
- No proxy layer or OpenAI API compatibility shim.
- No LAN exposure by default.
- No API key/authentication gate in v0.

## Local Development

Build and test:

```bash
swift build
swift test
```

Run the macOS app bundle:

```bash
./script/build_and_run.sh
```

Verify launch:

```bash
./script/build_and_run.sh --verify
```

Project planning and automation docs:

- `docs/current_status.md`
- `docs/roadmap.md`
- `docs/development_loop.md`
- `docs/product_brief.md`

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
OPENAI_API_KEY=local
```

AI Mobile / OpenAI-compatible client smoke:

```bash
curl -sS http://localhost:1234/v1/chat/completions \
  -H 'Authorization: Bearer local' \
  -H 'Content-Type: application/json' \
  -d '{"messages":[{"content":"Hazakura AI Mobile runtime smoke. Reply with OK.","role":"user"}],"model":"local","stream":false}'
```

## Security Defaults

- Default host is `127.0.0.1`.
- The app does not copy model files.
- Logs are shown in memory and are not persisted automatically.
- The launch command is displayed before start so it can be inspected.
