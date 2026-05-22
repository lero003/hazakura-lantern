# llama-server Presets

This document defines the next source lanes for model-family guidance on the
existing `llama-server` adapter. Presets are advisory starting points for an
existing local runtime and model. They are not model downloads, runtime
installers, benchmarks, or automatic optimizers.

## Purpose

Lantern should help a user answer:

- Which settings should I try first for this local GGUF model?
- Which launch options are likely useful for this model family?
- Which options require a newer `llama-server` build?
- What did Lantern add to the launch command, and can I edit it before start?

The app should keep the command visible. A preset is successful when it reduces
configuration guesswork without hiding how `llama-server` is launched.

## Preset Intents

Start with a small vocabulary:

- `Standard`: calm local defaults that leave model-family assumptions out of
  the command.
- `Qwen Recommended`: a Qwen-family starting point with a longer context and
  visible KV-cache-oriented arguments.
- `Qwen 3.6 MTP M4 Max`: a hardware-specific starting point for
  Qwen3.6-27B MTP GGUF on an M4 Max Mac Studio with 128 GB unified memory.
  It favors full 262K context, full Metal offload for both the main model and
  MTP draft path, and f16 KV cache over the generic Qwen preset's memory-saving
  KV compression.
- `Gemma Recommended`: a Gemma-family starting point with moderate context and
  visible KV-cache-oriented arguments.

These are intents, not promises. Names should describe why a preset exists
rather than imply benchmarked superiority.

## Initial Option Families

The first preset work should stay on options Lantern already models or can
display safely:

- context size
- CPU threads
- GPU layers
- host and port
- additional `llama-server` arguments
- cache and batching arguments only when documented by the preset
- speculative decoding arguments such as `--spec-type draft-mtp` and
  `--spec-draft-n-max`

Do not add hidden option generation. If a preset inserts an argument, the launch
command preview must show it.

## External Configuration Candidate

`llama-server` supports router/model preset files through `--models-preset`.
Lantern should not jump to that mode for the current single-model control
surface, but it is the first candidate if preset arguments grow too large for a
single editable Additional Args field.

Before externalizing arguments, require a small design note that explains:

- whether Lantern is still supervising one selected local model or entering
  router mode
- where the preset file lives and whether Lantern writes it
- how the generated file remains visible and editable before launch
- how command-line precedence interacts with model-specific preset values

## Speculative Decoding Boundary

Speculative decoding should be treated as model-family and runtime capability
guidance, not as a global toggle.

Use speculative decoding only when all are true:

- the preset or user marks the model as MTP-capable
- the selected `llama-server` appears to support the required options
- the added options remain visible in the launch command preview
- the user can turn the preset off or edit the arguments before launch

If capability is unknown, prefer leaving speculative decoding off and showing a
clear note. A safe fallback is more useful than a surprising failed launch.

The `Qwen 3.6 MTP M4 Max` preset is intentionally not the generic Qwen default.
It assumes a user-selected MTP-capable Qwen3.6 GGUF and a current Homebrew
`llama-server` build with `--spec-type draft-mtp`. The launch command stays
visible and editable before start.

## Runtime Capability Checks

v0.7 work may add advisory checks for the selected `llama-server`
binary:

- `--version` or build info display (manual UI display exists)
- timeout-bounded `--help` parsing for supported options (core parser exists)
- warnings when a preset depends on options absent from the selected runtime
  (manual UI advisory exists)
- notes when a runtime is too old for a preset

These checks must be local, timeout-bounded, and read-only. Lantern must not run
installers, mutate package managers, download runtimes, or auto-upgrade a
selected binary.

## Model Guidance Source

Early guidance can be manual and conservative:

- model family, such as Llama, Qwen, Gemma, Mistral, or gpt-oss
- model size band, such as small, mid, or large
- quantization or memory note when visible in the file name or profile name
- explicit MTP-capable marker only when the user or docs provide it

Do not infer too much from filenames. Filename hints may prefill a suggestion,
but the user must be able to review and edit the resulting configuration.

## Non-Goals

- model search, download, conversion, or catalog behavior
- automatic benchmarking
- automatic optimal-setting discovery
- runtime installation or update
- package-manager mutation
- hidden prompt or chat behavior
- automatic endpoint polling
- new runtime adapter implementation
- profile schema changes without a concrete migration design

## Suggested Slice Order

1. Document the preset vocabulary and option compatibility rules. Done.
2. Add a core preset model that maps an intent to visible configuration values
   and additional arguments. Done.
3. Add UI to preview and apply presets to the active configuration. Done.
4. Add advisory runtime capability checks for `--version` and `--help`. Core
   probe done.
5. Add warnings when a selected preset appears incompatible with the selected
   runtime. Initial manual UI advisory done.

Each slice should keep the `llama-server` command visible and editable.
