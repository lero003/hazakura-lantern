# Hazakura Lantern Roadmap

This roadmap keeps Hazakura Lantern narrow, deep, and useful.
It is not a promise of release dates.

Hazakura Lantern should become a calm Mac-first control surface for local LLM
runtimes that already exist on the user's machine. It should not become a model
platform, runtime installer, inference engine, chat app, marketplace, proxy, or
agent orchestration layer.

The guiding idea:

> Lantern lights the local runtime table. It does not become the engine.

## Product Thesis

Hazakura Lantern is a thin, reliable app that assembles existing local runtime
pieces into one understandable control surface:

```text
existing runtime binary or command
+ existing model or server configuration
+ visible launch state
+ logs
+ endpoint
+ reusable client snippets
= one calm local control panel
```

The project wins by making a small number of things boring and trustworthy:

- the selected runtime command is explicit
- the selected model or server target is visible
- start, stop, and restart are predictable
- logs are bounded and useful
- the local endpoint is easy to copy and reuse
- failures are understandable before users reach for a terminal
- nothing surprising happens in the background

It does not need to predict the winning runtime stack. Runtimes, models,
quantization formats, and server APIs will keep changing. Lantern should benefit
from that change by wrapping what exists, not by trying to own the stack.

## Roadmap Rule: Depth Before Breadth

Every roadmap item must strengthen at least one of these:

1. safer launch
2. clearer runtime state
3. more predictable process control
4. better endpoint reuse
5. more portable profiles
6. thinner adapter boundaries
7. more accurate documentation

If an item does not improve one of those, park it.

Do not add runtime breadth while the single-runtime loop still feels
surprising. A new adapter is allowed only after the `llama-server` path is
quiet and a design note fixes the next runtime boundary.

## Product Boundary

### Lantern owns

- profile storage
- a narrow, user-triggered GGUF acquisition page
- command construction and command preview
- path validation for user-selected files and executables
- direct process lifecycle control where applicable
- PID, status, health, and restart state
- bounded logs and clear log reset behavior
- local base URL display
- reusable environment snippets for local clients
- adapter documentation and focused tests
- a small Mac UI that makes the above visible

### Lantern does not own

- persistent model library management, download history, model ranking, or
  marketplace behavior
- model conversion
- bundled inference engines
- runtime installation or updates
- cloud runtime orchestration
- OpenAI-compatible proxy implementation
- chat UI
- RAG or tool execution
- benchmarking as a product feature
- full environment inventory
- remote deployment management
- image, video, audio, or other multimedia generation workflows unless a future
  design note proves they fit the same local-runtime supervision contract

### Lantern may pass through

- user-provided runtime flags
- adapter-declared server commands
- runtime-specific endpoints when documented
- runtime-specific health URLs when adapter-scoped
- one explicitly designed second runtime lane after `llama-server` is quiet

### Lantern may acquire

- one user-selected GGUF file from Hugging Face into a user-selected local
  directory
- a best-effort LM Studio-style directory layout such as
  `<models>/<owner>/<repo>/<file.gguf>` without depending on LM Studio internals
- visible download progress, cancellation, failure wording, and best-effort
  resume for the active task

Acquisition is not management. Lantern should not keep a model database,
download history, ratings, usage tracking, cleanup policy, automatic sync, or
background downloader. See `docs/gguf_acquisition.md`.

Pass-through is not ownership. If a runtime changes, Lantern should fail clearly,
not silently invent behavior.

### Lantern may observe

- selected runtime executable version when it can be checked safely
- user-declared install source, such as Homebrew, source build, or manual binary
- latest available version metadata from an official source when network access
  is explicit and adapter-scoped; the current implemented target is `llama.cpp`
- advisory "update available" status for registered runtimes
- setup guidance that points users toward official runtime installation docs

Observation is not management. Lantern may tell users that a runtime appears
old, missing, or installed in an unusual way. It should not run installers,
upgrade runtimes, mutate package managers, or hide where a runtime came from.

## Adjacent Product Question: Multimedia Generation

Image, audio, video, and other multimedia generation may be valuable in the
broader Hazakura ecosystem, but the default assumption is that they belong in a
separate sibling project or a future design note, not in Lantern's current
release-quality lane.

The only plausible bridge into Lantern is the existing product thesis:
supervise an already-installed local runtime, make its command or endpoint
visible, keep logs bounded, and avoid hidden install/update/model-management
behavior. A creative generation workspace, prompt library, asset browser,
model downloader, or media pipeline would be a different product and should be
reviewed separately before any Lantern implementation work starts.

Use `docs/external_review_flow.md` when asking outside reviewers whether this
multimedia direction should stay separate, become a sibling project, or later
share a local-runtime control contract with Lantern.

## Current Source Lane: v1.7 Source-Only Checkpoint

The project has reached a public source-only `v1.7.0` checkpoint for
personal/local use. It keeps the existing `llama-server` control boundary,
includes the bounded GGUF Acquisition lane, and does not include packaged
`.app`, zip, dmg, signing, notarization, checksum, or binary distribution
artifacts. The previous public source-only checkpoint was `v1.5.1`. The
2026-05-24 helper smoke, 2026-05-25 normal desktop smoke, and GGUF Acquisition
hardening checks provide source confidence. This remains source-only evidence;
a packaged-release pass still needs the actual distributed artifact path and
full release review.

Packaged release work remains separate from source milestones. Automation
should keep code quality boring, close small verified `llama-server` daily-use
gaps, and prepare packaged-release evidence such as manual smoke notes,
packaging-prep checks, and guarded update-workflow planning. This preparation
must not create packaged artifacts, mutate runtimes, or change GitHub settings
without a new human handoff.

Use v0 through v1.7 notes below as foundation and backlog context, not as a
reason to reopen closed work without a concrete ambiguity. The next useful
source work should fix failing checks, improve one smoke-observed rough edge,
classify post-public feedback, tighten automation-safe triage, prepare
packaged-release evidence without artifact mutation, or address a specific
`llama-server` reliability issue only when it is concrete and testable. The
next source milestone should be chosen from new evidence rather than the older
v1.3 planning label.

Do not loop on historical `kLSNoExecutableErr` diagnostics without a fresh
Launch Services hypothesis. Continue with release-quality source work that can
be verified through SwiftPM or focused manual smoke.

## v0 Foundation - Make One Runtime Boring

Stay here until the `llama-server` path is quiet, predictable, and documented.
The goal is not feature breadth. The goal is a single-runtime control loop that
feels safe to use every day.

Already done or mostly done:

- SwiftPM macOS app skeleton
- `llama-server` adapter
- executable and `.gguf` model path fields
- launch command preview
- direct `Process` launch without shell interpolation
- start, stop, restart, PID, status, and in-memory logs
- explicit `Restarting` status while a requested restart waits for the current
  process to terminate before the next launch
- runtime termination logs and error text distinguish normal exit codes from
  signal-based termination
- expected Stop and Restart termination logs avoid unexpected-crash wording
  when Lantern intentionally terminates the current process
- local endpoint and OpenAI-style environment snippet
- blank runtime or model selections show a setup hint before start
- non-`.gguf` model selections show a setup hint before start without adding
  conversion or download behavior
- invalid numeric launch settings show a setup hint before start for port,
  context size, threads, and GPU layers
- invalid host values show a setup hint before start so launch-host and
  endpoint-copy mistakes are explained together
- malformed Additional Args quoting shows a setup hint before start so launch
  argument typos do not wait for a failed start attempt
- copied endpoint/client URLs keep local defaults copyable while reflecting a
  configured reachable host
- local endpoint health-check URL and timeout-bounded copyable curl smoke
  command
- fail-fast, timeout-bounded copied client smoke command for AI Mobile and
  other OpenAI-compatible local clients
- manual endpoint health status check
- health status reset on start, stop, and termination so stale health does not
  survive process state changes
- endpoint health status presentation contract for title, detail, icon, and
  tone covered by focused tests
- healthy endpoint status detail makes the manual, snapshot-only check explicit
  without adding automatic polling
- `UserDefaults` configuration persistence
- compact runtime/model path rows without recent-path menus in Configuration
- app bundle launch helper
- bounded log buffering and clear-log behavior covered by focused tests
- focused core unit tests
- focused tests for invalid numeric options, endpoint URLs, and environment
  snippets
- focused tests for copied endpoint host behavior
- focused tests for quoted launch command preview display
- focused tests for missing runtime/model paths and invalid context size
- focused tests for launch configuration error descriptions
- focused tests for file-preflight launch failure descriptions
- focused tests for rejecting runtime/model directory selections during launch
  preflight
- focused tests for process-run launch failure descriptions
- real-model-free fake runtime smoke test for adapter-built launch commands
- initial v0.2 runtime profile document schema version contract
- stable readable JSON export/import helpers for runtime profile documents
- typed import failures for missing or unsupported runtime profile schema
  versions
- typed import failures for missing or unsupported runtime profile runtime
  kinds, keeping imported profiles on the current `llama-server` boundary
- active runtime profile persistence fallback through the configuration store
- profile JSON shape and portability boundaries documented with a readable
  schema-version `1` example
- suggested profile export filename contract using `.lantern-profile.json`,
  covered by focused tests before file-based UI is added
- supported profile filename and URL recognition for `.lantern-profile.json`,
  covered by focused tests before file-based import UI is added
- profile-file import preflight that rejects unsupported file names before
  decoding JSON contents, covered by focused tests before file-based import UI
  is added
- profile-file import preview that validates suffix, schema version, non-blank
  profile name, and runtime kind before requiring the full runtime configuration
  to decode
- profile local file reference contract for runtime executable and model paths,
  covered by focused tests before portability warnings or file UI are added
- imported profile portability warnings for missing runtime/model file
  references, non-executable runtime paths, model directories, and non-`.gguf`
  model paths, kept advisory without copying, downloading, or auto-fixing local
  files
- profile-level launch command preview through the matching adapter, covered by
  focused tests before profile UI is added
- profile command preview through a test-only matching adapter, proving the
  profile preview boundary is not hard-wired to `LlamaServerAdapter`
- profile `runtimeKind` alignment with the implemented adapter id, covered by a
  focused test before runtime breadth is added
- minimal active-profile import/export UI for `.lantern-profile.json` files
  without adding multiple-profile management
- adapter-owned endpoint display contract for base URL, environment snippet,
  timeout-bounded health-check curl, and AI Mobile smoke command generation,
  covered by focused tests without adding another runtime adapter
- adapter-owned health-check timeout propagation through the `RuntimeEndpoint`
  contract, keeping the default five-second curl timeout while allowing future
  adapters to narrow it explicitly
- manual endpoint health checks honor the adapter-scoped timeout from
  `RuntimeEndpoint`, keeping actual local health requests aligned with copied
  curl smoke commands
- adapter-owned environment snippets shell-quote adapter-scoped base URL and API
  key values when needed while preserving the readable default local snippet
- explicit adapter-owned validation contract that can be tested before command
  construction, preserving `llama-server` validation without adding runtime
  breadth
- adapter protocol default preflight and endpoint URL helpers covered with a
  minimal adapter test before runtime breadth is added
- adapter-owned launch preflight for `llama-server` executable and model file
  checks before process launch
- missing selected `llama-server` files are distinguished from existing but
  non-executable runtime files before process launch
- fallible adapter-owned endpoint construction that rejects invalid host/port
  values and lets the UI surface the error instead of crashing during endpoint
  display
- launch command construction normalizes blank profile host values to the
  default loopback host and trims configured hosts before passing them to
  `llama-server`
- launch command construction unwraps bracketed IPv6 host values before passing
  them to `llama-server --host`, while copied endpoint URLs remain URL-safe
- copied endpoint URLs treat bracketed IPv6 bind-all (`[::]`) as a local
  default, keeping client snippets on `localhost` while launch still passes
  `::` to `llama-server`
- host validation rejects URL-like, URL-delimiter, malformed bracket, or
  `host:port` values before command construction, keeping port selection in the
  dedicated profile field while still allowing valid IPv6 literals
- host validation rejects malformed DNS labels such as underscores, empty
  labels, or leading/trailing hyphens before command construction while keeping
  ordinary DNS hosts valid for endpoint reuse
- host validation rejects invalid IPv4-like dotted quads before command
  construction while preserving valid IPv4 hosts for endpoint reuse
- adapter-owned process-run failure descriptions that preserve the
  `llama-server` recovery hints without hard-wiring default protocol behavior
  to the current adapter
- default adapter launch-failure descriptions use the adapter display name for
  common POSIX failures, covered by focused tests before runtime breadth is
  added
- adapter contract documentation for responsibilities, lifecycle boundaries,
  and future adapter no-go lines before runtime breadth is added
- core `llama-server` preset model for Standard, Qwen Recommended, and Gemma
  Recommended settings, with generated options kept visible in the launch
  command
- compact preset picker and apply action in the server configuration view, with
  a visible settings summary before launch
- timeout-bounded, read-only `llama-server --version` and `--help` capability
  probing in the core layer, with a manual server-configuration UI check for
  runtime version display and preset option advisories
- reduced native toolbar utility strip for Setup Guide visibility, profile
  import/export, and copy actions, while lifecycle, health, command reveal, and
  log clear stay in the page content or menu bar
- path-only install-source advice for selected `llama-server` runtimes that look
  Homebrew-managed, MacPorts-managed, source-checkout-built, or manual, without
  executing any runtime update
- non-mutating update-readiness dry-run guidance that combines selected runtime
  source with local version/help capability evidence before any future guarded
  update plan can be prepared
- non-mutating `llama.cpp` update availability check against official GitHub
  release metadata, with build-number comparison only when local version
  evidence is comparable
- incomplete update-readiness evidence wording that names whether local
  `--version` or `--help` evidence is missing before any guarded update plan
- Setup Guide inspector access from the toolbar and Dashboard setup hint, so
  first-run onboarding is available without remaining a primary sidebar
  destination

Remaining before a packaged app release:

- keep the normal desktop/manual launch and clean-quit smoke fresh after
  UI/lifecycle changes, then repeat it against the actual distributed
  packaged-artifact path when packaging work is explicitly in scope
- resolve the pre-release UI blockers for the menu bar, toolbar, and Setup
  Guide additions:
  - verify remaining menu bar copy behavior and one final Open Window
    regression check on a normal macOS desktop
  - verify remaining reduced-toolbar copy menu behavior after future toolbar
    changes
  - confirm the Setup Guide inspector helps onboarding without crowding the
    main flow
  - run a manual UI smoke pass across main window, Setup Guide inspector, menu
    bar, toolbar, and quit behavior
- use `docs/automation_smoke_backlog.md` to keep rough-edge discovery concrete
  and automatable before broad polish or release work
- treat the 2026-05-20 external improvement proposal as triaged backlog input:
  accessibility, force-unwrap removal, copy feedback, error visibility,
  app-UI localization gaps, controller tests, and performance throttling are
  automatable only as small verified slices; branding, first-run flow changes,
  toolchain/CI additions, entitlements, signing, notarization, and packaged
  release work need explicit human handoff
- keep README, current status, development loop, and roadmap in agreement

v0 exit criteria:

- `swift test` passes
- `swift build --disable-sandbox` passes
- `./script/build_and_run.sh --verify` launches the app path successfully
- a user can configure an existing `llama-server` binary and `.gguf` model
- invalid configuration is surfaced before launch where practical
- generated command, base URL, and environment snippet match selected settings
- stop and restart leave the UI in a predictable state
- logs remain bounded and can be cleared
- docs match the actual app behavior

Do not add another runtime adapter before this is true.

## v0.1 - Daily-Use Confidence

Status: mostly satisfied for the source-only v0.2 checkpoint. Remaining ideas
from this lane are not current defaults; use them only when a concrete
repeated-use ambiguity is observed.

Purpose:

Make the existing one-runtime app pleasant enough for repeated local use.

Candidate work:

- endpoint health presentation improvements using the existing local health URL
- clearer launch, crash, and termination states
- lightweight runtime setup guidance for users who do not know how to install a
  server runtime yet
- copy buttons for command, base URL, and environment snippet
- small UI polish for repeated local use when a specific ambiguity is visible
- clearer empty states for missing runtime/model paths
- a compact troubleshooting section in docs

Deferred from this lane:

- endpoint health auto-polling
- selected runtime version display unless a later adapter contract defines a
  safe, advisory, timeout-bounded check

Keep this lane local-only. Do not add LAN exposure, authentication, automatic
background restart policy, runtime installers, or automatic runtime updates
here.

Completion criteria:

- users can tell whether the runtime is stopped, starting, healthy, unhealthy,
  or terminated
- common launch failures point to a practical next step, including process-run
  errors surfaced by macOS
- repeated start/stop/restart use does not make the UI ambiguous
- users can see what runtime binary they selected and, where safe, what version
  it reports
- copying endpoint details is obvious
- docs cover the daily-use loop without becoming a runtime tutorial

## v0.2 - Profile Contract And Portability

Status: source-only `v0.2.0-alpha.1` checkpoint.

Purpose:

Turn one working configuration into portable local profiles without expanding
runtime scope too early.

Candidate work:

- profile-level command preview
- JSON profile export/import
- file-based profile export/import UI boundaries
- advisory portability warnings for imported runtime/model file references
  when they can be checked locally without copying, downloading, or mutating
  runtime files
- migration behavior for future profile schema changes
- migration tests for persisted settings
- tests that preserve command construction compatibility
- profile documentation with examples

Deferred from this checkpoint:

- multiple local profiles
- profile rename, duplicate, and delete
- profile-level runtime metadata, such as install source and last observed
  runtime version

This lane still manages existing local runtimes. It should not download models,
install dependencies, or hide where a command comes from.

Completion criteria:

- the active profile can be exported, moved, backed up, and restored
- exported profile data is understandable without opening the app
- command construction is stable across persistence changes
- unsupported future profile data does not break startup
- docs clearly separate profile data from runtime/model files

## v0.3 - Adapter Boundary, Not Runtime Expansion

Purpose:

Define the adapter contract so future runtimes can be wrapped without turning
Lantern into a platform.

Candidate work:

- explicit adapter protocol or adapter-shaped boundary
- adapter-owned command construction
- adapter-owned health contract
- adapter-owned endpoint snippet behavior
- adapter-owned validation and error mapping
- tests that prove adapters do not require UI rewrites
- documentation that separates child-process, external-service, and
  custom-command lifecycle classes

Adapter requirements:

- command construction must be explicit
- shell interpolation must stay avoided; any future custom command profile
  requires a separate design and approval
- lifecycle semantics must be documented
- endpoint behavior must be documented
- health behavior must be documented
- unsupported runtime behavior must fail clearly

Future adapter experiments require a design note and human approval. The next
candidate is one concrete MLX-based server shape, not Ollama, a custom command
profile, or a broad runtime catalog.

Completion criteria:

- adding an adapter does not force broad architecture changes
- adapter tests catch command, endpoint, and health regressions
- UI language remains about local control, not runtime marketplace features
- docs describe what Lantern manages and what the runtime still owns

### v0.3 Close-Out Criteria

v0.3 is closed when:

- adapter ownership is documented for command construction, validation, launch
  preflight, endpoint display, health contract, health timeout, environment
  snippets, and launch failure descriptions
- `llama-server` regression tests cover executable and model validation,
  `.gguf` boundaries, host and port validation, IPv4/IPv6/bracket behavior,
  blank host normalization, copied local endpoint behavior, and process-run
  failure wording
- a minimal or test-only adapter fixture proves the boundary can be exercised
  without rewriting the UI
- `docs/runtime_adapters.md` explains current responsibilities and future
  adapter lifecycle classes
- `docs/current_status.md` names no concrete unresolved v0.3 adapter ambiguity
- `swift test` and `swift build --disable-sandbox` pass
- historical `kLSNoExecutableErr` helper failures remain regression context
  rather than a v0.3 source-work blocker

After close-out, automation should not add more adapter-boundary tests unless a
new bug report, design note, or regression identifies a specific ambiguity.

## v0.4 - `llama-server` Reliability And Daily-Use Polish

Purpose:

Make the existing `llama-server` workflow quiet, predictable, trustworthy, and
well-documented for repeated personal local use.

Candidate work:

- improve launch failure messages
- improve empty states for missing runtime or model paths
- improve copied command, endpoint, and client snippet clarity
- improve health-check wording and failure classification
- improve restart, terminated, and stopped state clarity
- improve profile portability warnings
- improve README and troubleshooting for common `llama-server` setup issues
- add focused tests for observed edge cases
- update current status and changelog after verified behavior changes

This lane should make the first runtime path boring before any second runtime
is selected.

Completion criteria:

- common `llama-server` setup mistakes produce useful next-step guidance
- copied commands, endpoints, and client snippets are understandable and stable
- health, restart, stopped, and terminated states do not leave stale or
  misleading UI
- profile portability warnings are advisory and clear
- README, troubleshooting, current status, and changelog match behavior
- no new adapter, custom command profile, endpoint auto-polling, model library
  management, runtime install/update, multiple-profile management, LAN/auth,
  chat, proxy, or packaged artifact work starts in this lane

## v0.5 - Post-Public Issue Triage And Automation Discipline

Purpose:

Keep public feedback from widening the product accidentally.

Candidate work:

- maintain `docs/post_public_operations.md`
- classify public issues and review notes before implementation
- distinguish source-build blockers from packaged-release blockers
- distinguish runtime bugs from Lantern bugs
- document out-of-scope response rules
- propose labels without mutating public issue state
- define when automation may act and when human approval is required
- prepare draft responses without mutating public issues automatically

Completion criteria:

- issue categories cover source-build blockers, `llama-server`
  launch/configuration bugs, profile import/export bugs, docs confusion,
  packaged app blockers, runtime-breadth requests, adjacent-product requests,
  out-of-scope requests, and security-sensitive reports
- automation can propose labels, docs fixes, and focused tests without
  promising feature support or mutating GitHub issue state
- roadmap and current status stay aligned with public feedback

## v0.6 - llama-server Model Presets And Option Compatibility

Purpose:

Help users start existing GGUF models with sensible, visible `llama-server`
settings before adding runtime breadth.

Candidate work:

- maintain `docs/llama_server_presets.md`
- define a small preset vocabulary: Standard, Qwen Recommended, and Gemma
  Recommended (core model done)
- map presets to visible configuration values and additional arguments
- preview and apply presets from the server configuration view
- keep launch command preview as the source of truth for what will run
- add focused tests for preset-to-configuration behavior
- keep speculative decoding arguments out of the default preset vocabulary
  until there is an explicit model/preset contract for them
- keep unsupported or unknown options visible and editable instead of hiding or
  silently rewriting them

Completion criteria:

- presets are advisory and user-reviewable
- speculative decoding stays off unless a future preset or user explicitly
  marks the selected model as compatible
- no model library management, download history, conversion, catalog ownership,
  benchmark UI, runtime install/update, endpoint auto-polling,
  multiple-profile management, or adapter expansion is introduced
- profile schema version `1` remains valid unless a concrete migration design
  is accepted

## v0.7 - llama-server Runtime Capability Advisories

Purpose:

Make presets safer as `llama.cpp` changes by checking the selected
`llama-server` binary locally and read-only.

Candidate work:

- timeout-bounded `llama-server --version` or build-info display (manual UI
  display exists)
- timeout-bounded `llama-server --help` parsing for supported option names
  (core parser done)
- preset compatibility warnings when an option appears unsupported (initial
  manual UI advisory exists)
- advisory notes when selected runtime capability is unknown (initial manual
  UI advisory exists)
- tests that capability parsing never launches a model or mutates the runtime
- docs that keep runtime checks local, read-only, and adapter-scoped

Completion criteria:

- option and version checks are local, timeout-bounded, and read-only
- unsupported presets warn rather than silently changing the command
- Lantern does not install, upgrade, download, benchmark, or mutate
  `llama-server`
- automation may complete v0.7 without another human prompt if each slice stays
  within these constraints

## v0.8 - Menu Bar, Toolbar, And Navigation

Purpose:

Make the existing `llama-server` control loop feel like a proper Mac app
without changing runtime ownership. The menu bar is the preferred resident
control surface; the main window remains the full configuration and audit
surface.

Candidate work:

- maintain `docs/toolbar_and_navigation.md`
- keep a reduced native macOS toolbar for Setup Guide visibility, profile
  import/export, and copy actions. Lifecycle, health, command reveal, and log
  clear remain outside the toolbar unless a later human decision reopens scope
- add a `MenuBarExtra` for existing start, stop, restart, health-check, copy,
  profile import/export, log clear, open-window, and quit actions while keeping
  the regular main window intact (initial menu bar surface done)
- organize the main window into native sidebar destinations for dashboard,
  configuration, and logs, with setup guidance available as an inspector while
  preserving existing runtime actions (initial sidebar dashboard and Setup
  Guide inspector done)
- keep toolbar state narrow and derived from the same controller state as the
  main views
- keep menu bar state derived from the same controller state as the main views
- add focused tests or view-model checks for toolbar action availability where
  practical
- add keyboard shortcuts only for actions whose enabled/disabled state is
  already clear

Completion criteria:

- toolbar actions remain limited to Setup Guide, profile import/export, and
  copy behavior without adding hidden side effects
- menu bar actions mirror existing behavior and do not add hidden side effects
- no endpoint auto-polling, launch-at-login, automatic restart, model library
  management, runtime install/update, menu-bar-only lifecycle change,
  multiple-profile management, or adapter expansion is introduced
- automation may complete v0.8 without another human prompt if each slice stays
  within these constraints

## v0.9 - llama-server Update Readiness

Purpose:

Prepare for a guarded `llama-server` update workflow by identifying the
selected runtime source and showing update risk before any mutation exists.

Candidate work:

- detect and display the selected runtime path source (path-only advice done),
  version, and option capability summary from v0.7
- fetch official latest-release metadata for the selected update-check target
  (`llama.cpp` only for now) without executing updates
- let the user record an install source such as Homebrew, source build, manual
  binary, or unknown
- document update implications for each source without executing updates
- add dry-run style checks that explain what Lantern would need before update
  execution is allowed (initial source plus capability-evidence guidance done)
- keep update checks timeout-bounded, local-first, and advisory

Completion criteria:

- Lantern can explain the selected runtime source and update readiness
- Lantern can show advisory `llama.cpp` update availability when latest release
  metadata and local build-number evidence are comparable
- no package manager, git checkout, download, file replacement, or install
  command is executed
- update work remains separate from GGUF acquisition and packaged app release
- automation may complete v0.9 without another human prompt if it remains
  non-mutating and advisory

## v1.0 - Guarded llama-server Update Workflow

Purpose:

Complete the `llama-server`-dedicated product shape with an opt-in,
user-confirmed update workflow. This is the point where Lantern can be called
reasonably complete as a `llama-server` companion, if packaging is still tracked
separately.

Candidate work:

- implement a source-scoped update workflow only for sources with a clear,
  reversible, user-approved path
- show the exact command or file operation before execution
- require explicit user confirmation for every real update
- stop a running Lantern-managed runtime before any update attempt
- verify the updated binary with `--version`, `--help`, and preset option
  compatibility checks after update
- record failure states without hiding the old selected runtime path
- test update planning and failure handling with fakes; do not run real package
  managers in tests

Completion criteria:

- updates are opt-in, visible, user-confirmed, and source-scoped
- unattended package-manager, git, or binary replacement mutation is still not
  allowed
- unsupported sources stay advisory instead of pretending to be updateable
- `llama-server` launch, presets, toolbar, capability checks, and update
  workflow form a coherent dedicated companion app

## v1.1 - Local Smoke Console

Purpose:

Make Lantern useful after a server starts by giving users a small, explicit
runtime usability check. This is a smoke/testing surface, not a chat product.

Candidate work:

- add a separate Smoke Console destination
- initial separate Smoke Console destination is implemented with prompt,
  run state, response display, copy response, and clear result
- use the selected adapter-owned endpoint/model contract already exposed by
  copied client snippets
- send a user-triggered, timeout-bounded non-streaming `/v1/chat/completions`
  request first
- show prompt input, request state, response text, copy response, clear result,
  current base URL, current model id, and clear error messages
- map connection failure, timeout, invalid endpoint, non-2xx response, and
  malformed response into focused tested core errors
- keep result state in memory only; do not persist conversation history
- keep streaming as a future enhancement unless it remains small and safe

Completion criteria:

- local endpoint smoke testing is available without saved conversations,
  multi-turn chat, prompt libraries, RAG/tools, attachments, cloud model
  support, endpoint auto-polling, or benchmark ranking
- request construction, timeout/error mapping, and response parsing have focused
  core tests where practical
- visible app-owned UI strings are localized
- docs frame the page as endpoint smoke testing and runtime usability
  verification, not as chat

## v1.2 - Runtime Smoke Metrics

Purpose:

Add honest last-run evidence around the Smoke Console so users can tell whether
the selected local runtime is usable and roughly how it behaved.

Candidate work:

- show started time, total elapsed time, output character count, request mode,
  and timeout used for the last smoke run
- successful Smoke Console results now show started time, elapsed time, output
  character count, request mode, and timeout used under the response
- prefer API-provided usage fields when present
- when usage is missing, show explicitly approximate output token count and
  approximate TPS only when enough data exists
- show first-response latency only if streaming is implemented safely
- keep metrics in memory or in a small bounded non-persistent recent-results
  list
- use careful wording such as "Last local test", "Smoke metric", "Approx
  output tokens", "Approx TPS", and "Usage reported by runtime"

Completion criteria:

- metrics do not claim benchmark, official performance, optimization, or
  tokenizer-accurate counts unless the implementation truly supports that
- no saved benchmark history, charts, cross-model leaderboard, automatic
  benchmark runs, or runtime optimizer is introduced
- docs keep packaged-release readiness separate

## v1.3 - Source-Stable Smoke Polish

Purpose:

Let v1.1/v1.2 settle through smoke-driven use, then prepare a source-stable
checkpoint when the console, metrics wording, docs, and manual smoke evidence
are quiet enough.

Candidate work:

- fix one smoke-observed rough edge at a time
- record manual desktop smoke evidence when available
- keep README, current status, roadmap, changelog, and automation guidance
  aligned on source-only versus packaged-release status
- avoid new feature breadth unless a later human handoff reopens scope

Status:

The useful v1.3 polish lane has been absorbed into the `v1.5.0` source-only
checkpoint after repeated Smoke Console and Setup Guide smoke passes. The
`v1.5.1` patch only aligns public license, contribution, and checkpoint
metadata. Treat v1.3 as historical planning context, not as the current target.

## v1.5 - Source-Only Release-Quality Checkpoint

Purpose:

Publish the smoke-driven source checkpoint after the Smoke Console metrics path,
Setup Guide inspector layout, localized Japanese UI evidence, and app cleanup
helpers are quiet enough for personal/local source use.

Completion criteria:

- app source checkpoint metadata says `v1.5.1`
- README, changelog, current status, roadmap, and external review guidance
  agree that v1.5 is source-only and not a packaged app release
- Smoke Console and Setup Guide have current real-device or automation-level
  smoke evidence recorded
- Start, Stop, Quit, and helper cleanup checks leave no managed app or
  `llama-server` process behind
- `swift test`, `swift build --disable-sandbox`, localization lint, and
  `git diff --check` pass

Status:

Completed by the `v1.5.1` source-only checkpoint. Later source checkpoints,
including `v1.7.0`, build on this evidence without changing the packaged
release boundary.

## v1.7 - GGUF Acquisition Source Checkpoint

Purpose:

Publish the bounded GGUF Acquisition source checkpoint after public API parsing,
safe local destination construction, resumable download behavior, localized
status copy, accessibility hints, and no-download public API smoke evidence are
quiet enough for personal/local source use.

Completion criteria:

- app source checkpoint metadata says `v1.7.0`
- README, changelog, current status, roadmap, and automation guidance agree
  that v1.7 is source-only and not a packaged app release
- GGUF Acquisition remains a user-triggered public `.gguf` file helper, not a
  model library, background downloader, ranking system, or gated-account flow
- `swift test`, `swift build --disable-sandbox`, and `git diff --check` pass

## v1.x - Second Runtime Design

After v1.0, revisit whether a second runtime is still the next smallest risk.
The first possible candidate remains one concrete MLX-based server shape, not
Ollama, a custom command profile, or a broad runtime catalog. A design note must
fix command, model reference, endpoint, health, lifecycle, and profile
boundaries before implementation.

## Packaging Track - Separate From Source Milestones

Packaging work should not block source-only roadmap progress unless a packaged
release is being prepared.

- P0: keep the local helper smoke passing when launch script or bundle layout
  changes
- P1: normal desktop/manual launch and clean-quit verification
- P2: bundle metadata, signing, launch-path, or Launch Services fix only if the
  helper smoke regresses or manual verification exposes a blocker
- P3: unsigned local app artifact
- P4: signed and notarized distribution

No `.app`, zip, dmg, signing, notarization, checksum, or binary distribution
claim should be published until the relevant packaging gate is satisfied.
Before a user-facing packaged release, also resolve the menu bar/toolbar/Setup
Guide UI blockers recorded in the v0 remaining-release list.

## Later, Separate Design Decisions

These may become useful, but they should not slip into earlier lanes casually:

- launch at login
- explicit auto-restart policy
- LAN exposure controls
- optional local authentication guidance
- metrics or benchmark display
- richer runtime setup assistant that remains documentation-first, except for
  the explicitly bounded GGUF acquisition page
- custom command profiles
- Ollama or other daemon-style adapters
- agent-facing integration notes

Treat each as a design decision with its own trade-offs, not incidental polish.

## Non-Goals

Do not use this project for:

- chat UI
- model library management, ranking, catalog ownership, or download history
- model conversion
- bundled inference engines
- runtime installer or updater
- automatic package-manager or source-build mutation
- OpenAI-compatible proxy implementation
- RAG or tool execution
- cloud runtime orchestration
- remote deployment management
- broad machine diagnostics
- model benchmark dashboard
- plugin marketplace

## Automation Guidance

Automated development should pick one small verified slice. The active lane is
`v1.1` Local Smoke Console, then `v1.2` Runtime Smoke Metrics, then
smoke-driven rough-edge fixes that culminated in the `v1.5.x` source-only
checkpoints. Prefer work that proves the selected local runtime is actually
usable after launch over work that merely advances a version label.

The open release-quality gates are the remaining menu bar copy verification,
one final Open Window regression check, reduced-toolbar copy menu verification,
successful profile export/import round-trip smoke when local file mutation is
in scope, Setup Guide inspector review against configuration flow,
packaged-artifact-specific launch/clean-quit smoke, and one final manual UI
smoke pass that covers the main window, Setup Guide, menu bar, toolbar, logs,
and quit behavior.

For pre-release rough-edge discovery that does not fit the smoke lane, use
`docs/automation_smoke_backlog.md`; it is the allowed source for one small
automatable UI, localization, menu bar, setup-flow, health/copy/log, profile,
packaging-prep, or non-mutating update-readiness polish slice.
The 2026-05-20 external improvement proposal has been folded into that backlog;
automation should not re-read it as permission for broad redesign, new tools,
runtime mutation, or release packaging.

Good next slices:

- harden one existing Smoke Console or Smoke Metrics behavior with careful
  approximate wording and no chat/history/benchmark claims
- harden one GGUF Acquisition behavior inside `docs/gguf_acquisition.md`,
  preferably with fake Hugging Face responses, downloader state tests,
  destination-path checks, no-download API shape smoke, or UI copy/accessibility
  polish
- after v1.7, use Smoke Console, GGUF Acquisition, or manual reports to fix one
  concrete rough edge at a time
- expose or fix one concrete rough edge from `docs/automation_smoke_backlog.md`
  when it can be verified without broad restyling, runtime mutation, packaging
  publication, or GitHub mutation
- verify one open release-quality gate and record the result in
  `docs/current_status.md` when it changes the next action
- classify public issues or external review notes using
  `docs/post_public_operations.md`, then update docs, tests, or small
  `llama-server` behavior only when the classification identifies a safe local
  slice
- refine `llama-server` presets, runtime capability checks, or update-readiness
  wording only when it reduces a concrete release-quality risk and remains
  visible, timeout-bounded, read-only, and non-mutating
- tighten adapter-owned lifecycle, error-mapping, or protocol boundaries with
  focused tests before adding runtime breadth; validation already has an
  initial explicit contract, and profile command preview already has a generic
  matching-adapter boundary test; invalid endpoint host/port fallibility and
  launch preflight ownership are covered, blank-host launch normalization is
  covered, missing-runtime-file preflight and runtime/model directory preflight
  are covered, process-run failure
  descriptions now flow through the adapter boundary, default adapter
  preflight/helper behavior is covered, profile-runtime-kind adapter id
  alignment is covered, URL-delimiter/stray-bracket host validation is covered,
  DNS-label host validation is covered, bracketed-IPv6 bind-all endpoint copy
  behavior is covered, default-adapter POSIX launch-failure display-name
  behavior is covered, adapter-scoped health-check timeout propagation is
  covered, adapter-scoped environment-snippet shell quoting is covered, and the
  first adapter contract documentation slice is covered
- tighten copied command, client smoke, or endpoint reuse flows only when a
  concrete copy-target ambiguity remains; the timeout-bounded health-check curl
  and fail-fast client smoke curl slices are covered
- improve common launch failure messages, file empty states beyond the
  blank-selection setup hint, health-check wording, profile warnings, or setup
  hints only when a specific `llama-server` ambiguity is visible, without
  adding installer behavior; numeric launch setup hints and malformed
  Additional Args setup hints are covered
- harden restart behavior only with a newly observed ambiguity and a testable
  state transition beyond the explicit pending-restart status
- document launch smoke expectations only when there is a fresh verification
  hypothesis or new evidence
- keep endpoint auto-polling deferred unless a later slice intentionally
  revisits adapter-owned health lifecycle and proves the polling policy can
  remain local, timeout-bounded, and non-surprising
- use `docs/public_opening_preflight.md` only for pre-open or release-handoff
  checks; use `docs/post_public_operations.md` for normal public operation
- update current status after implementation changes

Rules for automated work:

- do not add a new adapter without explicit human approval
- do not begin custom command profile implementation without explicit human
  approval; custom command profiles are not the next lane
- do not begin second-runtime design before v1.x, and do not begin second-runtime
  implementation until a design note is accepted and a human explicitly
  approves that work
- do not change the runtime profile schema version without explicit human
  approval
- do not add endpoint auto-polling before manual health and adapter health
  boundaries are intentionally revisited
- do not add multiple-profile management while the source-only checkpoint only
  promises active-profile import/export
- do not expand GGUF acquisition beyond the bounded page in
  `docs/gguf_acquisition.md`
- do not turn advisory runtime/version status into unattended update execution
- do not add automatic benchmarking or hidden optimal-setting discovery
- do not mutate GitHub settings, secrets, collaborators, branch protection,
  tags, releases, release assets, repository packages, or public issue state as
  part of the hourly loop
- do not publish packaged `.app`, zip, dmg, signing, notarization, checksum, or
  binary distribution claims
- do not mutate dependencies, lockfiles, package managers, or version-manager
  files unless a human explicitly hands off that work
- do not hide command construction
- do not change runtime ownership assumptions casually
- update tests and docs with each meaningful behavior change
- if no change is justified by current evidence, a verified no-op is acceptable
  only after checking open release-quality gates, concrete smoke-backlog
  candidates, current public-feedback/docs ambiguity, and any concrete
  `llama-server` reliability signal that is actually visible

## Issue Triage Checklist

Evaluate new ideas with these questions:

1. Does this make local runtime launch safer or clearer?
2. Does this make endpoint reuse easier?
3. Does this reduce surprise around process state, logs, or restart behavior?
4. Does this preserve the existing-runtime boundary?
5. If it touches GGUF acquisition, can search/download behavior be tested with
   fakes or fixtures before any real network download?
6. Can it be documented without turning Lantern into a runtime tutorial?
7. If it checks runtime versions or update availability, is that advisory and
   adapter-scoped?
8. If it suggests model settings, does it keep the final command visible and
   editable?
9. If it updates runtimes, is the operation user-confirmed, source-scoped, and
   testable with fakes before any real mutation?
10. Will it still make sense when runtimes evolve?

If most answers are no, defer the idea even if it is interesting.

## v1 Shape

A narrow successful Lantern v1 looks like this:

- Mac-first local app
- existing runtimes only
- explicit command preview
- predictable process lifecycle
- clear local endpoint reuse
- portable profiles
- bounded logs
- small, documented adapter set
- advisory runtime version and update awareness
- guarded, user-confirmed `llama-server` update workflow
- no hidden shell behavior
- no model marketplace
- no unattended runtime installation
- no cloud orchestration

The product should feel like a lantern on the desk: it makes the local runtime
visible, warm, and usable, while letting the engine underneath keep evolving.
