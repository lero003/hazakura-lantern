# Menu Bar, Toolbar, And Navigation

This document defines the v0.8 lane for making Hazakura Lantern easier to use
without changing runtime ownership. Toolbar and menu bar work should make
existing actions discoverable, not add new runtime behavior by stealth.

## Purpose

The app should expose the control loop in predictable Mac surfaces while keeping
the main-window toolbar intentionally quiet. The menu bar and page content own
the repeated server lifecycle actions; the toolbar stays as a small utility
strip for:

- Setup Guide visibility
- profile import and export
- copy endpoint, command, environment, health-check, and client smoke snippets

Toolbar and menu bar actions should mirror existing behavior. If a button
requires a new behavior contract, that contract belongs in its own focused
slice.

## Rules

- Keep toolbar state narrow: Setup Guide, profile import/export, and copy
  actions only unless a later human decision reopens it.
- Keep menu bar state derived from the same controller state as the window.
- Disable actions when the same action is unavailable elsewhere.
- Manual health checks are available only while the server is running.
- Do not add hidden side effects or background runtime work.
- Do not start endpoint auto-polling as part of control-surface work.
- Use native macOS SwiftUI toolbar patterns before custom controls.
- Prefer `MenuBarExtra` for the lightweight resident control surface before
  considering a menu-bar-only app lifecycle.
- Keep labels and accessibility names clear enough for keyboard and VoiceOver
  users.
- Preserve the launch command preview as the audit surface for runtime changes.

## Suggested Slice Order

1. Add a toolbar shell with existing start, stop, restart, and health actions.
   Superseded by the reduced-toolbar decision; lifecycle and health remain in
   the main UI and menu bar.
2. Add copy actions that reuse existing endpoint and smoke-command behavior.
   Done.
3. Add profile import/export entry points without adding multiple-profile
   management. Done.
4. Add a log clear toolbar action that reuses the existing clear-log behavior.
   Superseded by the reduced-toolbar decision; log clearing stays in Logs and
   the menu bar.
5. Add command-preview focus affordances if they stay local. Superseded by the
   reduced-toolbar decision; the Dashboard remains the command preview surface.
6. Add a menu bar control surface for existing lifecycle, health, copy, profile,
   log, open-window, and quit actions while keeping the normal window intact.
   Done.
7. Add a sidebar dashboard that keeps existing lifecycle, endpoint, and command
   preview actions reachable without changing runtime behavior. Done.
8. Move Setup Guide out of the primary sidebar when it can stay available as a
   toolbar-toggled inspector and first-run setup aid. Done.
9. Add keyboard shortcuts only for actions whose state is already well-defined.

## Pre-Release UI Blockers

Before a user-facing packaged release, do not treat v0.8 UI work as release
ready until these are checked or explicitly deferred:

- menu bar daily-use behavior works on a normal macOS desktop, including status
  visibility, lifecycle actions, copy actions, and opening the main window from
  hidden or backgrounded states
- the reduced toolbar is verified on a normal desktop: Setup Guide,
  import/export, and copy remain reachable without making the title bar feel
  crowded
- Setup Guide inspector onboarding is reviewed against the main configuration
  flow so it helps first-run setup without crowding normal daily use
- a manual UI smoke pass covers main-window launch, Setup Guide inspector
  toggling, menu bar commands, toolbar commands, sidebar navigation, Dashboard
  controls, and clean quit behavior

## Non-Goals

- new runtime adapters
- endpoint auto-polling
- launch-at-login
- menu-bar-only lifecycle changes
- automatic restart policy
- model download or runtime install/update
- hidden command changes
- multiple-profile management
