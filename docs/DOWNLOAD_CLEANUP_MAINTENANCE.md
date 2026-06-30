<!-- SORTIFY_DISPATCH_V470_DOWNLOAD_CLEANUP_INTEGRATION_DOC_START -->
## Release integration: v4.7.0-download-cleanup-integration

The Download Cleanup maintenance flow is released in Sortify Dispatch `v4.7.0-download-cleanup-integration` / `versionCode=24`. The public integration includes manual maintenance, stale-review planning, dry-run planning, gated apply, post-apply verify and rollback anchor generation.

The real proof used for release integration was `run_20260629_161212_stale_readonly` with `planned_items=233`, `moved_items=233`, `archive_items=233`, `source_still_present=0`, `dest_missing=0`, and `top_level_delta=PASS`.

This does not add service, boot, watcher, watchdog or queue automation. Real apply remains operator-triggered and gated.
<!-- SORTIFY_DISPATCH_V470_DOWNLOAD_CLEANUP_INTEGRATION_DOC_END -->

<!-- SORTIFY_ARCHIVE_REVIEW_APPROVED_APPLY_DOCS_START -->
### vNext: archive-review-approved apply and verify-review-archive

`archive-review-approved apply` performs the manual archive action for an already generated review plan. It is intentionally separate from dry-run.

Hard gates:
- Requires an exact `SORTIFY_CLEANUP_RUN_ID` or `SORTIFY_CLEANUP_RUN_DIR`.
- Requires `SORTIFY_CLEANUP_APPLY_REVIEW_ARCHIVE=yes`.
- Reads `planned_review_archive_manifest.tsv` or `SORTIFY_CLEANUP_PLANNED_MANIFEST`.
- Accepts only planned rows from buckets `A_temp_helper_scripts` and `C_logs_boot_watch_thermal_txt`.
- Blocks B/D/E buckets, invalid decisions, missing source files, duplicate destinations and destination scope drift.
- Writes `archive_review_manifest.tsv`.
- Writes `rollback_review_archive_<run_id>.sh`.
- `verify-review-archive` checks planned count, manifest count, archive item count, rollback syntax, bucket validity, missing destinations and source absence.
- Safety boundary for this feature: runtime_install=no, release_create=no, archive_safe=no, host_run=no, sdd_marker_write=no, dns_ha_vip_route_change=no, sha_sidecar=no.
<!-- SORTIFY_ARCHIVE_REVIEW_APPROVED_APPLY_DOCS_END -->

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
