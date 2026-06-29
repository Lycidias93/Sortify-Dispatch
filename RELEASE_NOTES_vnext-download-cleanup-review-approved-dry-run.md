# vNext - Archive-review-approved dry-run

Adds a planning-only dry-run command for approved stale-review candidates.

- Command: `sortify-download-cleanup.sh archive-review-approved dry-run`.
- Requires exact `SORTIFY_CLEANUP_RUN_ID` or `SORTIFY_CLEANUP_RUN_DIR`.
- Requires `SORTIFY_CLEANUP_APPROVED_FOR_ARCHIVE=yes`.
- Reads `approval_preview.tsv`.
- Accepts only A/C candidates.
- Blocks B/D/E, missing source files and duplicate destinations.
- Writes `planned_review_archive_manifest.tsv`.
- Moves no files.
- No runtime install, release creation, host-run, SDD marker write, DNS/HA/VIP/route change or SHA sidecar.
