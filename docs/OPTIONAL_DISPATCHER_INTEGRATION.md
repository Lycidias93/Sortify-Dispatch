# Optional Dispatcher Integration

Date: 2026-05-17

## Goal

Sortify must work for users who do not use Pixel Drop Dispatcher.

Dispatcher integration is an optional hold/release contract, not a hard runtime dependency.

## Config

SORTIFY_DISPATCHER_INTEGRATION=auto
SORTIFY_HOLD_PROTECTED=1
SORTIFY_NORMAL_SORT=1

Allowed values for `SORTIFY_DISPATCHER_INTEGRATION`:

- `off`: never use dispatcher runtime or release markers
- `auto`: use dispatcher runtime only when present and healthy
- `on`: require dispatcher runtime and fail clearly if missing

## User without dispatcher

Expected behavior:

- no dispatcher runtime lookup is required
- no Magisk dispatcher module is required
- normal downloads are sorted
- dispatcher-specific protected artifact hold is inactive
- status reports `dispatcher_integration=disabled` or `auto-inactive`

## User with dispatcher

Expected behavior:

- dispatcher runtime is checked
- protected artifacts remain in Download until released
- release only happens after successful dispatcher delivery
- partial delivery failures keep artifacts held
- status reports `dispatcher_integration=active`

## WebUI

The WebUI may expose these config values, but the config file remains the source of truth.

Suggested controls:

- Sortify enabled
- Dispatcher integration: off / auto / on
- Hold protected artifacts
- Sort normal downloads
- Show integration health/status

## Release rule

Any future release that changes dispatcher integration must include:

- config migration
- CLI status output
- WebUI status if WebUI exists
- regression check for users without dispatcher
