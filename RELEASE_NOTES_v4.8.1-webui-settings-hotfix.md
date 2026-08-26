# Sortify Dispatch 4.8.1

## What changed

- Fixed Settings saves that could fail with `module backend failed` after an interrupted or timed-out configuration apply. Sortify now recovers the stale local apply lock and keeps subsequent saves serialized.
- Fixed the mobile WebUI unsaved-changes bar so it no longer covers Settings and other action buttons on small screens.

## Compatibility

SSH Drop Dispatcher integration continues to use the existing `v4115` release-marker contract. Existing Sortify settings and persistent configuration are preserved during the update.

## Update

Install the release ZIP with your Magisk/KernelSU-compatible module manager and reboot once.
