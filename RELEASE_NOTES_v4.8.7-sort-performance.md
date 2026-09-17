# Sortify Dispatch 4.8.7 - Protected retention and faster sorting

## What changed

- Fixed WebUI sessions expiring while a supported long-running background **Sort now** job is active.
- Added configurable local protected-artifact retention with a 30-day default; `0` keeps local holds indefinitely.
- Kept `target-*` and `targets-*` artifacts strictly dispatcher-marker gated regardless of age.
- Reworked productive sorting to use one Download pass with cached guard and retention context, substantially reducing runtime on large protected Download trees.
- Existing Sortify settings and persistent configuration are preserved across the update.

## Update

Install the module update with a Magisk/KernelSU-compatible module manager and reboot once.
