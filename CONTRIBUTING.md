# Contributing

Thanks for considering a Hazakura Lantern contribution.

Hazakura Lantern is currently a macOS source-only checkpoint for supervising an
existing local `llama-server` runtime. Keep contributions inside that boundary
unless a maintainer explicitly opens a broader design discussion.

## Useful Contributions

- SwiftPM source-build or test fixes.
- Small `llama-server` launch, stop, restart, endpoint, log, or profile-flow
  fixes.
- Documentation fixes that make the source-only and packaged-release boundary
  clearer.
- Reproducible Smoke Console, Setup Guide, menu bar, toolbar, or cleanup
  evidence.

## Out Of Scope For Ordinary Issues

- Chat UI, RAG, tools, proxy behavior, or cloud orchestration.
- Model download, conversion, catalog, marketplace, or bundling.
- Runtime installers, package-manager mutation, or automatic runtime updates.
- LAN exposure, authentication, launch-at-login, or automatic restart policy.
- Packaged `.app`, zip, dmg, signing, notarization, checksum, or GitHub Release
  asset work without explicit maintainer handoff.

## Local Checks

Run the normal SwiftPM checks before proposing source changes:

```bash
swift test
swift build --disable-sandbox
git diff --check
```

`--disable-sandbox` is useful in some Codex or constrained local environments
where SwiftPM's manifest sandbox is rejected while normal compilation succeeds.

## Reporting Safely

Please redact private home-directory names, tokens, model filenames, and local
credential paths from command previews, logs, screenshots, and profile JSON.
Do not attach private model files or runtime binaries.

Security-sensitive reports should follow `SECURITY.md`.
