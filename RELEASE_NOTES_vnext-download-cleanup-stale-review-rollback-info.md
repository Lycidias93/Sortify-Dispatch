# vNext Download Cleanup stale-review and rollback-info

Adds planned follow-up improvements to the Pixel-local Download cleanup maintenance helper.

- Creates `stale_review_candidates.tsv` during scan.
- Lists selected old-looking `pixel_local__*` files as review-only metadata while keeping them protected/local-hold.
- Improves `rollback-info` for the latest run, manifest, rollback, archive and items path.
- Keeps archive-safe explicit/manual only.
- No runtime install, release creation, SDD marker writes, host-run, SSH or DNS/HA/VIP/route behavior changes.
- No SHA sidecar artifacts are used for this helper flow.
