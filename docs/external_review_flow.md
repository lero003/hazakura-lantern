# External Review Flow

Use this when asking someone outside the current coding loop for release or
directional feedback. The goal is to gather sharper judgment, not to outsource
the release decision.

## Review Tracks

Keep release readiness and future product direction separate.

1. Current release/readiness review
   - Is the source-only checkpoint honest, useful, and understandable?
   - Are the known release gates clear enough?
   - What should block a packaged app release?
2. Future direction review
   - Should Lantern stay a local runtime control surface?
   - Which adjacent ideas belong in this app, a later design note, or a
     separate project?
   - Which ideas would make the current product boundary confusing?

Do not ask a reviewer to approve tags, GitHub Releases, packaged artifacts,
signing, notarization, public issue mutation, or GitHub settings changes unless
there is a human handoff for that exact action.

## Evidence To Send

Before asking for current release feedback, gather:

- latest checkpoint: `v1.7.0`
- branch and working-tree state: `git status --short --branch`
- recent commits since the previous checkpoint: `git log --oneline v1.5.1..HEAD`
- verification results: `swift test`, `swift build --disable-sandbox`,
  localization lint if resources changed, and `git diff --check`
- current release gates from `docs/current_status.md` and `docs/roadmap.md`
- known packaged-release boundary: helper and normal desktop smoke evidence is
  current for source-only confidence, but no packaged `.app`, zip, dmg,
  signing, notarization, checksum, or release asset claim is included

For future-direction feedback, send the product boundary from
`docs/roadmap.md` and the non-goals from `README.md` instead of a feature wish
list alone.

## Paste-Ready Current Review Request

```markdown
I want an external release-readiness review for Hazakura Lantern.

Project state:
- macOS SwiftUI source-only checkpoint
- latest checkpoint: v1.7.0
- no packaged .app, zip, dmg, signing, notarization, checksum, or binary
  distribution claim
- current lane: source-only post-v1.7 polish and packaged-release readiness
  separation

Product boundary:
- Lantern supervises an existing local llama-server process.
- It shows selected paths, command preview, process status, bounded logs, local
  endpoint, profile import/export, and copyable client snippets.
- It does not provide chat, model library management, model conversion, proxy
  behavior, runtime installation, automatic runtime updates, LAN/auth, or
  bundled inference. The bounded GGUF Acquisition page may download one
  user-selected public `.gguf` file into a user-selected directory.

Known evidence:
- SwiftPM verification should be evaluated from the latest local/CI results.
- Helper launch verification, Setup Guide narrow-window checks, real local
  Smoke Console requests, toolbar profile panel presentation, menu-bar Stop,
  and cleanup checks have current local evidence.
- Packaged `.app`, zip, dmg, signing, notarization, checksum, and GitHub
  Release assets remain out of scope for this checkpoint.

Please review:
1. Are the source-only checkpoint claims honest and understandable?
2. What, if anything, must be fixed before another source checkpoint?
3. What must block a packaged app release?
4. Are any docs or UI claims stronger than the implementation evidence?
5. Are there small release-quality improvements that fit the current
   llama-server boundary?

Please avoid recommending chat, model library management, proxy behavior,
runtime installer/updater execution, public GitHub mutation, or packaged release
actions unless you classify them as future/human-decision work.
```

## Paste-Ready Future Direction Request

```markdown
I also want product-direction feedback for Hazakura Lantern.

Current thesis:
- Lantern is a calm Mac control surface for local model-serving runtimes that
  already exist on the user's machine.
- It should make command, model/server target, logs, health, and endpoint reuse
  visible without becoming the engine or a model platform.

New question:
- Should the broader Hazakura ecosystem also explore image or multimedia
  generation workflows, not only LLM server control?

Please review:
1. Should multimodal generation belong in Lantern, or should it be a separate
   sibling project?
2. If it belongs near Lantern, is the shared concept "local runtime control" or
   "creative generation workspace"?
3. What boundary would prevent image/video/audio generation from confusing the
   current source-only checkpoint?
4. Which first experiment would be smallest: supervising an existing local
   image-generation server, documenting a separate project thesis, or doing
   nothing until Lantern reaches packaged-release confidence?
5. What user story would justify crossing from LLM endpoint control into
   multimodal generation?

Default bias to challenge:
- Keep Lantern focused on local runtime supervision.
- Treat image/multimedia generation as a separate project or future design note
  unless it clearly reuses the same "existing local runtime, visible endpoint,
  bounded logs, no hidden install/update" contract.
```

## Intake Rule

After feedback arrives, classify each item before acting:

- release blocker
- source-quality polish
- docs clarity
- packaged-release blocker
- future design note
- separate-project idea
- out of scope for Lantern

Apply only one small, verifiable item per implementation run. Broad product
direction feedback should update docs or a design note first, not app behavior.
