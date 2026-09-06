# Sortify Dispatch 4.8.4 – WebUI Action Launch Hotfix

- Fixes the module-manager Action-button launch race that could open the browser after the standalone loopback WebUI server had already stopped, causing `ERR_CONNECTION_REFUSED` on the one-time `127.0.0.1` bootstrap URL.
- Fixes productive **Sort now** timing out as a synchronous browser Action request on large Download trees. Preview stays synchronous; productive sorting starts in the bounded Jobs lifecycle and remains observable there until completion.
- Pins shared WebUI Core 0.6.3 for the SIGHUP-safe launcher and action-to-job apply handoff.
- Keeps the WebUI loopback-only, one-time-token authenticated, idle/session/job bounded, and explicitly user-triggered.
- Preserves existing Sortify settings, persistent configuration, and SSH Drop Dispatcher policy v4115.

This is a source candidate until the exact installed ZIP passes both the device Action-button bootstrap audit and productive Sort-now background-job acceptance. Stable update metadata remains on 4.8.3 until that acceptance is complete.
