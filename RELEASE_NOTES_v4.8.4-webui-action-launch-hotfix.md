# Sortify Dispatch 4.8.4 – WebUI Action Launch Hotfix

- Fixes the module-manager Action-button launch race that could open the browser after the standalone loopback WebUI server had already stopped, causing `ERR_CONNECTION_REFUSED` on the one-time `127.0.0.1` bootstrap URL.
- Pins shared WebUI Core 0.6.2, which detaches the short-lived loopback server from the launcher shell's stdin/SIGHUP lifetime.
- Keeps the WebUI loopback-only, one-time-token authenticated, idle/session bounded, and explicitly user-triggered.
- Preserves existing Sortify settings, persistent configuration, Action behavior, and SSH Drop Dispatcher policy v4115.

This is a source candidate until the exact installed ZIP passes the device Action-button WebUI audit. Stable update metadata remains on 4.8.3 until that acceptance is complete.
