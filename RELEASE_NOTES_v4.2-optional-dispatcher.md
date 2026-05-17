
# Sortify Dispatch v4.2-optional-dispatcher

Date: 2026-05-17

## Summary

Public release for optional Pixel Drop Dispatcher integration controls.

## Highlights

- `SORTIFY_DISPATCHER_INTEGRATION=off|auto|on`
- `SORTIFY_HOLD_PROTECTED=0|1`
- `SORTIFY_NORMAL_SORT=0|1`
- WebUI controls for all three flags
- `--config-status` command
- Runtime smoke verified on Pixel against active module path `/data/adb/modules/sortify`

## Compatibility

Sortify remains usable without Pixel Drop Dispatcher. Default `auto` mode only uses dispatcher-aware handling when the dispatcher runtime is present and healthy. Normal sorting remains enabled by default.

## Verification evidence

- Active runtime smoke: `SORTIFY_OPTIONAL_DISPATCHER_RUNTIME_SMOKE_DONE`
- Runtime backup: `/data/adb/sortify-dispatch-backup/pre-optional-dispatcher-smoke-20260517-020539`
- Smoke ZIP SHA256: `a29f7d7a62779e1bc0e6b822e7fe3a815ea303cdc984e2b1a61ea3a9fa679674`
