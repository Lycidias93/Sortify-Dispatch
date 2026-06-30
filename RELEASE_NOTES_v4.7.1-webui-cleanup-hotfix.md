# Sortify Dispatch v4.7.1-webui-cleanup-hotfix

## Release scope

This hotfix follows v4.7.0-download-cleanup-integration after successful Pixel after-reboot verification.

## Fixed

- Updates stale action/status metadata that still reported `4.6.5-sort-mode-control`.
- Adds WebUI controls for Download Cleanup maintenance.
- Adds action wrappers for cleanup status, scan, guard, archive-safe, verify, rollback-info, review dry-run, review apply and review verify.

## WebUI safety

- Scan/status can run without a run id.
- Guard, verify, rollback-info and review operations require an explicit run id.
- Review dry-run requires typed `APPROVE`.
- Archive-safe requires typed `ARCHIVE_SAFE`.
- Review apply requires typed `APPLY` and still maps to `SORTIFY_CLEANUP_APPLY_REVIEW_ARCHIVE=yes`.

## Verified base state

- Previous after-reboot marker: `RESULT: SORTIFY_V470_AFTER_REBOOT_VERIFY_ADJUSTED_DONE rc=0`.
- Previous real cleanup proof: `planned_items=233`, `moved_items=233`, `archive_items=233`, `source_still_present=0`, `dest_missing=0`, `top_level_delta=PASS`.

## Boundaries

- `runtime_install=no` in this release workflow.
- `new_real_file_move=no`.
- `host_run=no`.
- `sdd_marker_write=no`.
- `dns_ha_vip_route_change=no`.
- `sha_sidecar=no`.

## Result marker

`RESULT: SORTIFY_V471_WEBUI_CLEANUP_HOTFIX_RELEASED rc=0`
