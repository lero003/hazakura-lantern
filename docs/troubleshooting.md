# Troubleshooting

Hazakura Lantern supervises an existing local runtime. It does not install
runtimes, download models, or proxy requests. Use this page to sort common setup
and smoke-check failures before widening scope.

## Runtime Or Model Path

Symptoms:

- Start fails before a process is launched.
- The error points at the selected `llama-server` binary or `.gguf` model.

Checks:

- The runtime path should point to an executable Mac binary.
- The model path should point to an existing `.gguf` file.
- The generated launch command is copyable from the app for terminal
  inspection.

Local file checks:

```bash
test -x /path/to/llama-server
test -f /path/to/model.gguf
file /path/to/llama-server
```

Use these only to confirm that the selected files already exist on this Mac.
They are not install, update, or model-conversion steps.

Do not add installer or model-download behavior to fix these cases. Lantern
should point to the missing local setup step and remain advisory.

## Endpoint Health

Symptoms:

- The app is running, but the manual health check fails.
- Copied client smoke commands cannot reach the local endpoint.

Checks:

- Confirm the runtime process is running and has a PID.
- Confirm the configured port matches the copied endpoint.
- Use the timeout-bounded copyable health-check curl command before adding new
  app behavior.
- Use the timeout-bounded copied client smoke command after health succeeds if
  the endpoint is reachable but a client still fails.
- If the health endpoint returns a non-success HTTP status, confirm
  `llama-server` finished loading the model and inspect the app logs before
  changing Lantern behavior.
- Health state is intentionally manual; there is no automatic polling yet.

The health check is a local smoke signal from this Mac. LAN exposure,
authentication, and remote reachability remain outside the current source
checkpoint.

## App Bundle Launch Smoke

Symptoms:

- Historical runs of `./script/build_and_run.sh --verify` failed with Launch
  Services `kLSNoExecutableErr`.
- SwiftPM build and tests still pass.

Current status:

- The current 2026-05-24 verify hardening pass builds the local bundle,
  requests launch through Launch Services, confirms a `HazakuraLLMManager`
  process id, and closes the app before exiting.
- Treat helper-smoke results as automation evidence only. The current release
  posture is: source verification passes, helper launch smoke can prove a local
  process launch, and normal desktop/manual launch and clean quit are still
  required before packaged-release work.
- Do not treat helper smoke as packaged-release proof. A normal desktop/manual
  launch and clean-quit pass is still required before app-bundle distribution
  work.
- Do not keep retrying historical Launch Services diagnostics without a fresh
  regression or hypothesis.

Useful fresh hypotheses:

- Confirm that the newly generated `Info.plist` `CFBundleExecutable` value
  exactly matches the executable under `Contents/MacOS/`.
- Compare Launch Services behavior after an explicit bundle registration or
  cache reset on a normal macOS environment. Treat cache reset commands as
  environment-mutating diagnostics, not as an hourly automation default.

Before a user-facing `.app`, zip, dmg, signing, or notarization release, record
a normal desktop/manual launch and clean-quit pass and update
`docs/current_status.md`.

## Release Boundary

Allowed before a packaged-release smoke pass exists:

- SwiftPM build/test verification.
- Source-only release candidates and checkpoints.
- Prerelease notes that clearly state no packaged `.app` artifact is attached.

Not allowed yet:

- User-facing packaged `.app` release.
- zip/dmg artifacts.
- Signing or notarization work as a release claim.
- Any workaround that expands Lantern into chat, model download, proxy, LAN
  exposure, auth, updater, or adapter breadth.
