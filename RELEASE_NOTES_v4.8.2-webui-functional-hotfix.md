# Sortify Dispatch 4.8.2 – WebUI Functional Hotfix

## What changed

- Fixed WebUI Settings saves on Android builds whose system `sed` does not support GNU-style regular-expression alternation.
- Fixed the embedded-host bootstrap JavaScript returning HTTP 404 from the authenticated loopback WebUI server.
- Kept existing Sortify settings and persistent configuration across the update.

## Compatibility

This remains a Magisk/KernelSU-compatible Sortify Dispatch update using shared WebUI Core 0.6.1 and SSH Drop Dispatcher policy `v4115`.

## Update

Install the new ZIP over the existing Sortify module and reboot when required by your module manager.
