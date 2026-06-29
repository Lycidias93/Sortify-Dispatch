# Sortify Download Cleanup vNext - Review approved apply

This release note documents the next maintenance step after `archive-review-approved dry-run`.

## Added

- `archive-review-approved apply`
- `verify-review-archive`

## Gates

- exact `SORTIFY_CLEANUP_RUN_ID` or `SORTIFY_CLEANUP_RUN_DIR`
- `SORTIFY_CLEANUP_APPLY_REVIEW_ARCHIVE=yes`
- valid `planned_review_archive_manifest.tsv`
- A/C buckets only
- no duplicate destinations
- all sources must exist
- destinations must be inside the review archive items directory

## Outputs

- `archive_review_manifest.tsv`
- `rollback_review_archive_<run_id>.sh`

## Boundaries

No runtime install, no release creation, no host-run, no SDD marker write, no DNS/HA/VIP/route change and no SHA sidecar.
