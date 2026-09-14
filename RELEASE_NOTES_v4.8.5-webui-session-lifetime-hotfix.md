# Sortify Dispatch 4.8.5 - WebUI Session Lifetime Hotfix

## What changed

- Fixed the WebUI session expiring while a long-running background **Sort now** job was still active.
- Long-running jobs can remain observable through their supported runtime instead of losing authentication after 15 minutes.
- Existing Sortify settings and persistent configuration are preserved across the update.

## Update

Install the module update with a Magisk/KernelSU-compatible module manager and reboot once.
