# Sortify Dispatch 4.5-webui-ux

Sortify-only WebUI UX release.

## Added

- Current WebUI header for `4.5-webui-ux`.
- Sortify mode presets:
  - Normal mode: normal sorting + protected hold.
  - Maintenance safe-hold: pause normal sorting while keeping protected hold.
  - Guard-only mode: no normal sorting, protected hold remains active.
  - Explicit unsafe mode: normal sorting without protected hold, with confirmation.
- Sortify-only config export ZIP through `action.sh --config-export`.
- Generic protected artifact examples for public use.

## Scope boundary

This release does not add SSH Drop Dispatcher target management, SDD config import/export, SSH key handling, private runtime migration or restore/import operations to Sortify WebUI. Those remain outside Sortify Dispatch.

## Compatibility

- Keeps SSH Drop Dispatcher marker contract read-only from Sortify.
- Keeps `policy=v4115` protected remote artifact behavior.
- Keeps Pixel-local/Termux/repo helper artifacts local protected hold.
