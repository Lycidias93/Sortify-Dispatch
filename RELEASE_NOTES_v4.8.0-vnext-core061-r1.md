# Sortify Dispatch 4.8.0

## What changed

- Moved the WebUI to shared WebUI Core 0.6.1. Sortify can open in the default browser or through compatible KsuWebUI-style embedded hosts while using the same authenticated local loopback session.
- Consolidated settings into a typed WebUI surface and added the configurable Preview file limit while keeping existing Sortify options, including custom park prefixes.
- Moved active configuration to persistent state under `/data/adb/sortify` so settings survive module replacement. Existing configuration is preserved and completed with safe defaults during upgrade.
- Fixed upgrade/install handling so the WebUI server remains executable after installation and the migrated configuration is normalized before the module starts.
- Exposed filename testing, route explanation, marker status and guarded Download Cleanup operations through typed WebUI actions instead of browser-built shell commands.
- Made uninstall behavior safer by avoiding broad process-name termination and preserving Sortify data and persistent configuration by default.

## Compatibility

SSH Drop Dispatcher integration continues to use the existing `v4115` release-marker contract. Sortify does not add SDD target administration, SSH-key handling or Return Channel administration. Custom park prefixes remain local-hold only; `target-` and `targets-` remain reserved for dispatcher routing.

## Update

Install the release ZIP with your Magisk/KernelSU-compatible module manager and reboot once. Existing Sortify settings are migrated automatically.
