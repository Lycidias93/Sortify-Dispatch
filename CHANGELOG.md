# Changelog

## Unreleased

- Documented the Artifact Hold / Release Contract for Dispatcher, Termux, and Sortify interaction.
- Clarified that normal downloads continue to sort automatically and only operational workflow artifacts are held.
- Added public Dispatcher release gate: public release follows private/proven Dispatcher release verification.


## v4.1-guard-tools - 2026-05-16

- Added `--guard-status` to audit protected artifacts in Download and misplaced protected artifacts in Sortify folders.
- Added safe `--guard-clean` to restore misplaced Dispatcher, Pixel, Termux, release, and repo helper artifacts to Download.
- Guard clean never overwrites existing Download files; collisions move to `/sdcard/Sortify/GuardConflicts/<timestamp>/`.
- Added read-only `--dispatcher-status` link check for Pixel Drop Dispatcher runtime metadata.
- Improved KernelSU WebUI with interval config, guard logging toggle, guard status, safe guard clean, dispatcher link status, and manual sort.
- Updated online update metadata to `Lycidias93/Sortify-Dispatch` release `v4.1-guard-tools`.
- Added repo build and smoke gates.

## v4.0-artifact-guard - 2026-05-16

- Forked Sortify v4.0 as Sortify Dispatch.
- Added Artifact Guard for Dispatcher, Pixel-local, Termux, Magisk/KernelSU release, and repo helper artifacts.
- Published `Sortify-Dispatch-v4.0-artifact-guard.zip` with SHA256.

<!-- SORTIFY_VNEXT_OPTIONAL_DISPATCHER_INTEGRATION_20260517_START -->
## 2026-05-17 - vNext optional dispatcher integration design

- Documented that Sortify must remain usable without Pixel Drop Dispatcher.
- Planned config flag: `SORTIFY_DISPATCHER_INTEGRATION=off|auto|on`.
- Planned default: `auto`, with safe fallback when dispatcher runtime is missing.
- Documented that unrelated downloads continue to sort and must not be held.
<!-- SORTIFY_VNEXT_OPTIONAL_DISPATCHER_INTEGRATION_20260517_END -->
