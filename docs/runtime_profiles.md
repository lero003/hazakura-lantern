# Runtime Profiles

Runtime profiles are local Lantern configuration documents. They describe how
to start an existing runtime; they do not include runtime binaries, model files,
download instructions, credentials, logs, or generated app artifacts.

The current profile document schema is version `1` and supports the first
runtime kind, `llama-server`.

## JSON Shape

Profile JSON is intended to stay readable enough for backup, review, and small
local edits:

```json
{
  "configuration" : {
    "additionalArguments" : "--verbose",
    "contextSize" : 8192,
    "gpuLayers" : "0",
    "host" : "127.0.0.1",
    "modelPath" : "/models/hazakura.gguf",
    "port" : 4321,
    "runtimeExecutablePath" : "/opt/llama.cpp/llama-server",
    "threads" : "6"
  },
  "name" : "Desk runtime",
  "runtimeKind" : "llama-server",
  "schemaVersion" : 1
}
```

Paths are local machine paths. Moving a profile to another Mac may require
choosing a different runtime executable or model path before launch.

## Import Behavior

Lantern imports profile JSON through the schema-version guard:

- missing `schemaVersion` fails as an invalid runtime profile
- schema versions newer than this build supports fail closed
- unsupported profile data does not replace the active single-runtime
  configuration during startup recovery

Future migration work should add explicit transform tests when there is a
concrete version `2` shape. Until then, avoid accepting unknown schema versions
or silently rewriting profile data.

## Boundary

Profiles remain a portability layer for existing local runtimes. They should
not trigger model download, runtime installation, package-manager updates,
LAN exposure, authentication setup, or adapter expansion.
