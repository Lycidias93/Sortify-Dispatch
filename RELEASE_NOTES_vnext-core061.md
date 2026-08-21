# Sortify Dispatch vNext

## What changes for users

- The WebUI moves to the shared standalone WebUI foundation. It can open in the default browser and in compatible KernelSU-style embedded WebUI hosts while using the same authenticated local session.
- Settings are presented through one typed configuration surface. Existing Sortify options remain available and the Preview file limit is now configurable as well.
- Sortify configuration moves to persistent state under `/data/adb/sortify`, so module updates no longer depend on keeping the active config inside the replaceable module directory.
- Filename testing, route explanation, marker status and guarded Download Cleanup workflows use typed WebUI operations instead of browser-built shell commands.
- Uninstall no longer uses a broad process-name kill. Sortify data and persistent configuration are preserved by default.

## Compatibility

SSH Drop Dispatcher integration remains compatible with the existing `v4115` release-marker contract. No SDD target, SSH-key or Return Channel administration is added to Sortify.

## Upgrade behavior

An existing Sortify configuration is preserved into the persistent state location on upgrade. Missing settings keep their existing safe defaults and become visible through the shared Settings UI.

This vNext source is not promoted to the public update channel until device install/reboot verification is complete.
