# Sortify Dispatch 4.6-smart-dedupe

## Highlights

- Adds extended file categories: Ebooks, Code, Config, Data, Fonts, Certificates, Backups and Torrents.
- Adds optional checksum-based duplicate handling:
  - same filename + same SHA-256: delete the source duplicate and log it;
  - same filename + different SHA-256: move source to `Duplicates` using a collision-safe name;
  - checksum unavailable: never delete, move to `Duplicates`.
- Adds WebUI controls for duplicate mode, log rotation and stale guard-temp cleanup.
- Keeps Custom Park Prefixes as local-hold-only; they never release files to SDD.
- Keeps SDD target/SSH management out of scope and read-only.

## Safety

- Default duplicate mode is `filename`; checksum deletion must be enabled explicitly.
- `target-*__*` and `targets-*__*` remain governed only by the SDD marker contract (`policy=v4115`).
- No DNS/HA/VIP/route or host drop path changes.
