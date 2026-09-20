# Sortify Dispatch 4.8.10 - Action reliability, ntfy lifecycle notifications and remote retention options

## What changed

- Fixed the Magisk **Action** WebUI becoming unreachable when the root-manager shell ends.
- Fixed an Android PID identity check that could hang Action startup.
- Added secret-safe ntfy status/test controls and non-fatal notifications for sort start, success and failure by reusing the existing SSH Drop Dispatcher ntfy configuration.
- Added an optional `marker_or_age` mode for remote protected artifacts with its own mtime-based retention value; the default remains strict `marker_only`.
- Local protected retention remains independent, and existing Sortify settings and persistent configuration are preserved.

## Update

Install the module update with a Magisk/KernelSU-compatible module manager and reboot once.
