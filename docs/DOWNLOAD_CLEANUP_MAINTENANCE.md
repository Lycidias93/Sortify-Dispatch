# Sortify Download Cleanup Maintenance vNext

This document defines the optional Pixel-local Download cleanup maintenance helper.

The helper is explicit/manual only. It is not called from service, boot, watcher, watchdog or queue processing.

Allowed commands: scan, guard, archive-safe, verify, rollback-info. No delete, purge, archive-all or automatic archive command is exposed.

Always protect `pixel_local__*`, `heimnetz__*`, `target-*__*`, `targets-*__*`, dot/runtime names, active app folders and Git worktrees. Archive-safe requires a guard pass for the same run. Each archive creates an `archive_manifest.tsv` and a rollback script.

`pixel_local__*` remains local-hold. Old Pixel-local files may be reviewed by future policy, but they are not automatically moved by this helper.

```text
host_run=no
sdd_marker_write=no
dns_ha_vip_route_change=no
```
