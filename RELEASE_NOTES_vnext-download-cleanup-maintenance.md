# vNext Download Cleanup Maintenance

Adds a planned Pixel-local Download cleanup maintenance helper.

- Commands: scan, guard, archive-safe, verify, rollback-info.
- Manual-only: no service, boot, watcher, watchdog or queue integration.
- Protects `pixel_local__*`, `heimnetz__*`, target prefixes, dot/runtime names, active app folders and Git worktrees.
- Archive-safe creates a manifest and rollback script.
- No SDD marker writes, host-run, SSH or DNS/HA/VIP/route behavior changes.
