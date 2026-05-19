# Toolbar And Navigation

This document defines the v0.8 lane for making Hazakura Lantern easier to use
without changing runtime ownership. Toolbar work should make existing actions
discoverable, not add new runtime behavior by stealth.

## Purpose

The app should expose the main control-loop actions in a predictable Mac
surface:

- start, stop, and restart
- check endpoint health
- copy endpoint or client smoke command
- import and export the active profile
- reveal or focus the launch command preview
- clear logs
- open troubleshooting or post-public guidance when useful

Toolbar actions should mirror existing behavior. If a toolbar button requires a
new behavior contract, that contract belongs in its own focused slice.

## Rules

- Keep toolbar state derived from existing controller state.
- Disable actions when the same action is unavailable elsewhere.
- Do not add hidden side effects or background runtime work.
- Do not start endpoint auto-polling as part of toolbar work.
- Use native macOS SwiftUI toolbar patterns before custom controls.
- Keep labels and accessibility names clear enough for keyboard and VoiceOver
  users.
- Preserve the launch command preview as the audit surface for runtime changes.

## Suggested Slice Order

1. Add a toolbar shell with existing start, stop, restart, and health actions.
2. Add copy actions that reuse existing endpoint and smoke-command behavior.
3. Add profile import/export entry points without adding multiple-profile
   management.
4. Add log clear and command-preview focus affordances if they stay local.
5. Add keyboard shortcuts only for actions whose state is already well-defined.

## Non-Goals

- new runtime adapters
- endpoint auto-polling
- launch-at-login
- automatic restart policy
- model download or runtime install/update
- hidden command changes
- multiple-profile management
