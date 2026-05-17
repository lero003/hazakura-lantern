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

The core profile contract can list the local file references a profile depends
on: the runtime executable and model file paths, when present. File-based UI can
use that list for portability warnings without checking the file system,
installing runtimes, or copying model data into the profile.

Profile documents can build a launch command through the matching runtime
adapter. This lets future profile UI show the command preview for a profile
without applying it as the active runtime configuration first. A profile whose
runtime kind does not match the adapter fails closed instead of guessing a
command shape.

When the app adds file-based profile export, the suggested filename should use
the profile name plus `.lantern-profile.json`. The name is sanitized for local
file systems only; the JSON `name` field remains the user-facing profile name.
File-based import UI should recognize files with the same
`.lantern-profile.json` suffix before reading their JSON contents. The core
import helper also validates that suffix before decoding JSON, so an ordinary
`.json` file can fail as an unsupported profile file without relying on JSON
parser errors.

File-based import UI can preview the profile envelope before full import. The
preview validates the file suffix, supported schema version, profile name, and
runtime kind, but it does not require decoding the full runtime configuration.

## Import Behavior

Lantern imports profile JSON through the schema-version guard:

- missing `schemaVersion` fails as an invalid runtime profile
- missing `name` fails as an invalid runtime profile
- schema versions newer than this build supports fail closed
- missing or unsupported `runtimeKind` fails closed; the current supported kind
  is `llama-server`
- unsupported profile data does not replace the active single-runtime
  configuration during startup recovery

Future migration work should add explicit transform tests when there is a
concrete version `2` shape. Until then, avoid accepting unknown schema versions
or silently rewriting profile data.

## Boundary

Profiles remain a portability layer for existing local runtimes. They should
not trigger model download, runtime installation, package-manager updates,
LAN exposure, authentication setup, or adapter expansion.
