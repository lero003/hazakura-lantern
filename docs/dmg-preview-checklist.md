# DMG Preview Checklist

Status: Planned
Scope: Future warning-expected DMG preview distribution
Authority: Medium
Last reviewed: 2026-05-28

This checklist is for a warning-expected binary DMG preview lane only. It does
not change the current `v1.7.0` source-only checkpoint boundary.

Do not attach the DMG to the source-only GitHub Release. Do not create tags,
push commits, publish a GitHub Release, or attach assets without explicit
approval.

## Boundary

There are two different DMG lanes:

- Warning-expected DMG preview: a downloadable `.dmg` that packages the locally
  built app, with clear release notes that it is only ad-hoc signed and is not
  Developer ID signed or notarized.
- Developer ID / notarized DMG: a distribution-grade lane that requires
  Developer ID signing, hardened runtime review, notarization, stapling, and
  Gatekeeper verification.

Do not mix these lanes in release notes.

## Warning-Expected DMG Preview

Use this only if the user explicitly approves moving from source-only release
to DMG preview.

The current preview artifact is for the current Mac architecture. Apple Silicon
artifacts are named `aarch64`; Intel artifacts are named `x64`. Do not describe
one architecture artifact as universal.

Required work:

- Keep the release marked as prerelease or developer preview.
- Use the repo-local warning-expected DMG preview script.
- Run the normal source checkpoint checks: `git diff --check`, `swift test`,
  and `swift build --disable-sandbox`.
- Build the app bundle with `script/build_and_run.sh --bundle-only`.
- Verify the generated `.app` launches from the built bundle with
  `script/build_and_run.sh --verify`.
- Build the warning-expected DMG with `script/build-warning-dmg-preview.sh`.
- Verify the generated `.dmg` with `hdiutil verify`.
- Mount the `.dmg`, open the contained app as a user would, and run a minimal
  built-app smoke.
- Generate a SHA-256 checksum for the `.dmg`.
- Record the DMG filename, checksum, app checkpoint, and smoke result in
  `docs/current_status.md`.
- Update release notes to say the DMG is ad-hoc signed only, not Developer ID
  signed, not notarized, and may show macOS security warnings.

Suggested commands, adjusted to the actual generated paths:

```bash
git diff --check
swift test
swift build --disable-sandbox
script/build_and_run.sh --verify
script/build-warning-dmg-preview.sh
(cd dist/dmg && shasum -c hazakura-lantern_1.7.0_aarch64-warning-expected.dmg.sha256)
```

`script/build-warning-dmg-preview.sh` deliberately uses `hdiutil create` with a
plain app-plus-Applications-link layout. Treat this as acceptable only for the
warning-expected preview lane.

Do not claim this path is safe, trusted, signed for public distribution, or
notarized.

## Developer ID / Notarized DMG

Treat this as a later distribution-readiness project, not a small source
checkpoint follow-up.

Required decisions before implementation:

- Apple Developer Program account and Developer ID certificate ownership.
- Signing identity and secret handling policy.
- Hardened runtime and entitlement review.
- Notarization workflow with `notarytool`.
- Stapling and offline Gatekeeper verification.
- Release asset naming, checksum, and rollback policy.

Reference Apple docs before starting this lane:

- https://developer.apple.com/developer-id/
- https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution
- https://support.apple.com/guide/mac-help/open-a-mac-app-from-an-unknown-developer-mh40616/mac

## Stop Conditions

Stop and do not attach a DMG to a release if:

- The release is still described as source-only.
- The `.dmg` cannot be verified or mounted.
- The app cannot launch from the packaged DMG.
- The release notes imply Developer ID signing or notarization when neither was
  performed.
- The checksum is missing.
- The user has not explicitly approved binary asset publication.
