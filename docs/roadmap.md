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

- model search or downloads
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

### Lantern may pass through

- user-provided runtime flags
- adapter-declared server commands
- runtime-specific endpoints when documented
- runtime-specific health URLs when adapter-scoped
- one explicitly designed second runtime lane after `llama-server` is quiet

Pass-through is not ownership. If a runtime changes, Lantern should fail clearly,
not silently invent behavior.

### Lantern may observe

- selected runtime executable version when it can be checked safely
- user-declared install source, such as Homebrew, source build, or manual binary
- latest available version metadata from an official source when network access
  is explicit and adapter-scoped
- advisory "update available" status for registered runtimes
- setup guidance that points users toward official runtime installation docs

Observation is not management. Lantern may tell users that a runtime appears
old, missing, or installed in an unusual way. It should not run installers,
upgrade runtimes, mutate package managers, or hide where a runtime came from.

## Current Source Lane: v0.3 Close-Out, Then v0.4 `llama-server` Reliability

The project has reached a source-only `v0.3.0-alpha.1` checkpoint for adapter
boundary clarity and public opening, while the app-bundle launch smoke remains
a packaged-release blocker.

Use v0 and v0.1 notes below as foundation and backlog context, not as a reason
to reopen closed work without a concrete ambiguity. The next useful source
work should either close a named v0.3 adapter-boundary ambiguity or move into
v0.4 `llama-server` reliability and daily-use polish.

Do not retry the known `kLSNoExecutableErr` app-bundle helper path unless there
is a fresh Launch Services hypothesis. Carry it as a release risk and continue
with source work that can be verified through SwiftPM.

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
- local endpoint and OpenAI-style environment snippet
- blank runtime or model selections show a setup hint before start
- copied endpoint/client URLs keep local defaults copyable while reflecting a
  configured reachable host
- local endpoint health-check URL and timeout-bounded copyable curl smoke
  command
- manual endpoint health status check
- health status reset on start, stop, and termination so stale health does not
  survive process state changes
- endpoint health status presentation contract for title, detail, icon, and
  tone covered by focused tests
- `UserDefaults` configuration persistence
- recent executable/model path menus stored outside exported runtime
  configuration
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

Remaining before a packaged app release:

- fix or externally verify the app-bundle launch smoke path
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
- `kLSNoExecutableErr` remains classified as a packaged-release blocker rather
  than a v0.3 source-work blocker

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
- no new adapter, custom command profile, endpoint auto-polling, model download,
  runtime install/update, multiple-profile management, LAN/auth, chat, proxy,
  or packaged artifact work starts in this lane

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
  packaged app blockers, runtime-breadth requests, out-of-scope requests, and
  security-sensitive reports
- automation can propose labels, docs fixes, and focused tests without
  promising feature support or mutating GitHub issue state
- roadmap and current status stay aligned with public feedback

## v0.6 - MLX Server Adapter Design Note

Purpose:

Choose one concrete MLX server shape before implementation. This is a
design-only lane unless explicitly approved.

Candidate work:

- create `docs/mlx_adapter_design.md`
- identify the exact MLX server command shape
- decide whether Lantern supervises it as a child process
- define adapter-specific model reference wording, such as local model
  directory or declared model id instead of assuming every runtime uses
  `modelPath`
- document endpoint and OpenAI compatibility assumptions
- document health check behavior
- document launch validation and preflight checks
- document what Lantern will not install, download, convert, or catalog
- define how tests can run without a real model
- identify profile schema impact, if any

Completion criteria:

- the design names exactly one MLX server shape
- command, lifecycle, endpoint, health, validation, tests, and profile impact
  are explicit
- implementation remains blocked on human approval

## v0.7 - MLX Server Adapter Minimal Alpha

Purpose:

Add one concrete MLX server adapter after v0.6 design and explicit human
approval. This is not an MLX ecosystem or runtime marketplace.

Candidate work:

- command preview
- start, stop, and restart when the chosen MLX server is child-process based
- bounded logs
- endpoint display
- health check when available
- copied client snippet when OpenAI-compatible
- profile import/export support
- focused tests without real model download

Completion criteria:

- `llama-server` behavior remains unchanged
- MLX support stays adapter-specific
- no MLX package installation, Hugging Face download, model conversion, model
  catalog, benchmark UI, multimodal UI, runtime marketplace, or generic custom
  command profile is introduced

## Packaging Track - Separate From Source Milestones

Packaging work should not block source-only roadmap progress unless a packaged
release is being prepared.

- P0: Codex-environment reproduction and diagnostics for `kLSNoExecutableErr`
- P1: normal macOS verification outside the restricted Codex environment
- P2: bundle metadata, signing, launch-path, or Launch Services fix
- P3: unsigned local app artifact
- P4: signed and notarized distribution

No `.app`, zip, dmg, signing, notarization, checksum, or binary distribution
claim should be published until the relevant packaging gate is satisfied.

## Later, Separate Design Decisions

These may become useful, but they should not slip into earlier lanes casually:

- launch at login
- explicit auto-restart policy
- LAN exposure controls
- optional local authentication guidance
- metrics or benchmark display
- richer runtime setup assistant that remains documentation-first
- opt-in runtime update notifications for registered runtimes
- custom command profiles
- Ollama or other daemon-style adapters
- agent-facing integration notes

Treat each as a design decision with its own trade-offs, not incidental polish.

## Non-Goals

Do not use this project for:

- chat UI
- model search or downloads
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

Automated development should pick one small slice from the current lane. After
`v0.3.0-alpha.1`, the default lane is v0.3 close-out when a concrete adapter
ambiguity exists, otherwise v0.4 `llama-server` reliability and daily-use
polish.

Near-term automation is allowed to continue through v0.5. If v0.4 has no
concrete, testable reliability or daily-use slice, automation may advance to
v0.5 issue triage and automation discipline instead of stopping. Do not treat
v0.4 as a required checklist that must be exhausted before v0.5 docs can move.

Good next slices:

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
  slice is covered
- improve common launch failure messages, file empty states beyond the
  blank-selection setup hint, health-check wording, profile warnings, or setup
  hints only when a specific `llama-server` ambiguity is visible, without
  adding installer behavior
- harden restart behavior only with a newly observed ambiguity and a testable
  state transition beyond the explicit pending-restart status
- document launch smoke expectations only when there is a fresh verification
  hypothesis or new evidence
- classify public issues or external review notes using
  `docs/post_public_operations.md`, then update docs, tests, or small
  `llama-server` behavior only when the classification identifies a safe local
  slice
- tighten post-public issue categories, label proposals, or draft-response
  guidance only when a concrete public-feedback case is not covered by the
  current operations guide
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
- do not begin MLX implementation before the v0.6 design note is accepted and a
  human explicitly approves v0.7 work
- do not change the runtime profile schema version without explicit human
  approval
- do not add endpoint auto-polling before manual health and adapter health
  boundaries are intentionally revisited
- do not add multiple-profile management while the source-only checkpoint only
  promises active-profile import/export
- do not add model download or install flows
- do not turn advisory runtime update status into automatic update execution
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
  only after checking both v0.4 reliability and v0.5 triage/docs candidates

## Issue Triage Checklist

Evaluate new ideas with these questions:

1. Does this make local runtime launch safer or clearer?
2. Does this make endpoint reuse easier?
3. Does this reduce surprise around process state, logs, or restart behavior?
4. Does this preserve the existing-runtime boundary?
5. Can it be tested without requiring a real model download?
6. Can it be documented without turning Lantern into a runtime tutorial?
7. If it checks runtime versions or update availability, is that advisory and
   adapter-scoped?
8. Will it still make sense when runtimes evolve?

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
- no hidden shell behavior
- no model marketplace
- no runtime installation
- no cloud orchestration

The product should feel like a lantern on the desk: it makes the local runtime
visible, warm, and usable, while letting the engine underneath keep evolving.
