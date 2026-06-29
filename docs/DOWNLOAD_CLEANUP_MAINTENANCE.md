<!-- SORTIFY_ARCHIVE_REVIEW_APPROVED_DRY_RUN_DOCS_START -->
### vNext: archive-review-approved dry-run

`archive-review-approved dry-run` plans a future manual archive for explicitly reviewed stale-review candidates, but moves nothing.

Hard gates:
- Requires an exact `SORTIFY_CLEANUP_RUN_ID` or `SORTIFY_CLEANUP_RUN_DIR`.
- Requires `SORTIFY_CLEANUP_APPROVED_FOR_ARCHIVE=yes`.
- Reads `stale_review_approval_preview/approval_preview.tsv` or `SORTIFY_CLEANUP_APPROVAL_PREVIEW`.
- Accepts only `candidate_for_manual_archive_review` rows from buckets `A_temp_helper_scripts` and `C_logs_boot_watch_thermal_txt`.
- Blocks B/D/E buckets, missing source files and duplicate archive destinations.
- Writes `planned_review_archive_manifest.tsv` only.
- Safety: runtime_install=no, release_create=no, archive_safe=no, file_move=no, host_run=no, sdd_marker_write=no, dns_ha_vip_route_change=no, sha_sidecar=no.
<!-- SORTIFY_ARCHIVE_REVIEW_APPROVED_DRY_RUN_DOCS_END -->

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
