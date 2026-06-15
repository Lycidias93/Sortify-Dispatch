# Sortify Dispatch 4.6.4-state-contract-preview

## Summary

`4.6.4-state-contract-preview` adds read-only state/contract inspection for the existing SSH Drop Dispatcher integration.

## New commands

```text
--explain-route <filename-or-path>
--marker-status <filename-or-path>
--contract-smoke
```

## What changed

- Route preview for local-hold, Markdown/Handover, Pixel-local, dispatcher release, Sortify release and remote target artifacts.
- Marker status view for existing dispatcher marker files in `/data/adb/ssh-drop-dispatcher/integration/sortify-release`.
- Contract smoke for Sortify-side expectations:
  - `policy=v4115`
  - `heimnetz__` custom local-hold
  - Markdown/Handover hold
  - Pixel-local hold
  - remote target hold without valid marker
  - normal Markdown still sortable
- Version bumped to `4.6.4-state-contract-preview` / `versionCode=22`.

## Boundaries

- Read-only against SDD markers.
- No SDD target management.
- No SSH key handling.
- No ntfy token/topic handling.
- No DNS, HA, VIP, route or host-drop changes.
- No change to `checksum_delete_identical` default.
