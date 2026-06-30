# Sortify Dispatch v4.7.0-download-cleanup-integration

## Release scope

This release bundles the Download Cleanup maintenance integration into the public Sortify Dispatch release line.

## Included integration flow

- `scan`, `guard`, `archive-safe`, `verify`, and `rollback-info` for explicit Pixel-local Download cleanup maintenance.
- `stale_review_candidates.tsv` planning for old-looking `pixel_local__*` helper artifacts while preserving the local-hold contract.
- `archive-review-approved dry-run` for planning-only review archive manifests.
- `archive-review-approved apply` for gated manual archive movement from a verified planned manifest.
- `verify-review-archive` for post-apply validation.

## Verified real workflow before release

- Run id: `20260629_161212_stale_readonly`.
- Preview: `bucketed_count=706`, `candidate_for_manual_archive_review=233`, `hold=473`.
- Dry-run: `planned_items=233`.
- Real apply: `moved_items=233`, `archive_items=233`, `source_still_present=0`, `dest_missing=0`, `top_level_delta=PASS`.
- Rollback anchor: `rollback_review_archive_20260629_161212_stale_readonly.sh`.

## Boundaries

- No runtime install in this release workflow.
- No service, boot, watcher, watchdog, or queue integration for cleanup.
- No SSH/host-run.
- No SSH Drop Dispatcher marker writes.
- No DNS/HA/VIP/default-route/static-route/MagicDNS/subnet-route changes.
- No `.sha256` sidecar artifact.

## Result marker

`RESULT: SORTIFY_V470_DOWNLOAD_CLEANUP_INTEGRATION_RELEASED rc=0`

## Machine-readable release boundary markers

- `sha_sidecar=no`
- `host_run=no`
- `sdd_marker_write=no`
- `dns_ha_vip_route_change=no`
