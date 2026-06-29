# Sortify Download Cleanup Maintenance vNext

This document defines the optional Pixel-local Download cleanup maintenance helper.

The helper is explicit/manual only. It is not called from service, boot, watcher, watchdog or queue processing.

Allowed commands: scan, guard, archive-safe, verify, rollback-info. No delete, purge, archive-all or automatic archive command is exposed.

Current vNext additions:

- `stale_review_candidates.tsv` is created during scan as review-only metadata for old-looking `pixel_local__*` helper artifacts.
- `pixel_local__*` remains local-hold/protected and is never moved by archive-safe.
- `rollback-info` prints the latest run, manifest, rollback, archive and items paths and validates rollback syntax when present.

Archive-safe still only uses `safe_candidates.tsv` after `guard.pass` for the same run. Review, stale-review and protected entries remain untouched.

```text
host_run=no
sdd_marker_write=no
dns_ha_vip_route_change=no
sha_sidecar=no
```
