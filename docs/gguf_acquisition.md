# GGUF Acquisition

This note defines the narrow model-download lane that may be added to
Hazakura Lantern without turning it into a model manager.

Lantern may provide a separate page that helps a user search Hugging Face for
GGUF files and download one selected file into a user-selected local directory.
This is acquisition, not library management.

## Allowed Scope

- user-triggered Hugging Face GGUF search
- listing GGUF files from a selected repository when the public API shape is
  still compatible enough for Lantern's simple parser
- choosing a local download directory, including an LM Studio-style shared
  models directory when the user wants that layout
- saving files under a predictable owner/repository/file path, such as
  `<models>/<owner>/<repo>/<file.gguf>`
- showing in-progress download state, progress when available, cancel/failure
  state, and completion state
- attempting resume when the local partial file and server behavior make that
  practical
- setting the completed GGUF path as the active Lantern model path when the
  user explicitly chooses that follow-up action

## Out Of Scope

- persistent model database
- download history
- model ratings, rankings, recommendations, or usage tracking
- model deletion, cleanup, or storage management
- automatic sync with Hugging Face or LM Studio
- model conversion, quantization, merging, or repair
- license judgment on behalf of the user
- storing Hugging Face access tokens in the first implementation
- gated-model workflows beyond clear failure wording
- LM Studio internal database or metadata mutation
- unattended background downloads

## Product Boundary

The downloader is allowed because it prepares a local `.gguf` file for the
existing `llama-server` control loop. It must not hide the selected file path or
make Lantern responsible for a user's model collection.

If Hugging Face changes its API, page shape, auth behavior, or file metadata
format, Lantern may fail clearly. The feature is a convenience path, not a
stable model marketplace contract.

LM Studio compatibility is best-effort and directory-layout based. Lantern may
write into a user-selected directory that also happens to be used by LM Studio,
but it should not require LM Studio, inspect private LM Studio state, or mutate
LM Studio-specific metadata.

## Current Implementation

The first implementation adds a separate sidebar page for public Hugging Face
GGUF acquisition. A user can search public GGUF repositories, pick a repository
file, choose a download directory, and save the file as
`<download-directory>/<owner>/<repo>/<file.gguf>`.

Repository tree parsing accepts ordinary nested `.gguf` paths but ignores unsafe
file paths with empty, current-directory, parent-directory, absolute, or
backslash-style components, or components with leading/trailing whitespace,
before a download candidate is shown.

Public repository search parsing accepts ordinary Boolean `gated` metadata and
compatible string forms such as `auto`, `manual`, or `false` without starting a
gated-account workflow.

Downloads are explicit foreground tasks with visible progress, cancellation,
failure display, and a best-effort `.part` resume when the local partial file
and server `Range` behavior line up. When the expected file size is known,
Lantern keeps an incomplete response as `.part` instead of promoting it to a
final `.gguf`; non-positive public API size values are treated as unknown
metadata. Resumed downloads also use a valid `Content-Range` total as a
completion check when repository tree metadata did not include a file size.
If a resumed request receives `416 Content-Range: bytes */N` and the local
`.part` file already matches that server byte count, Lantern promotes the
partial file instead of discarding the completed bytes.
Completion offers a follow-up action to set the downloaded file as Lantern's
active model path.

Lantern persists only the chosen default download directory. It does not persist
a model database, download history, token, Hugging Face account state, LM Studio
metadata, or background sync queue.

## First Slice

The first implementation intentionally avoids network breadth where possible:

1. Add a configurable default GGUF download directory.
2. Add the separate page shell and explicit download-directory state.
3. Add a focused search result model for public Hugging Face GGUF repository
   metadata.
4. Download one selected `.gguf` file with visible progress and cancel/failure
   handling.
5. Offer a post-download action to use the completed file as the active model
   path.

Do not add download history, model cleanup, account settings, or background
sync in the same slice.
