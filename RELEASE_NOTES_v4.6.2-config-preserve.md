# Sortify Dispatch 4.6.2-config-preserve

Install/update config preservation hotfix.

## What changed

- Preserves existing `/data/adb/modules/sortify/sortify.conf` during Magisk upgrade.
- Keeps custom park prefixes across updates.
- Keeps duplicate handling mode across updates.
- Keeps guard bounds, log rotation, normal sorting, protected hold and dispatcher integration settings.
- Keeps v4.6 smart categories and checksum duplicate handling unchanged.
- Keeps update changelog as raw Markdown/plain text.

## Safety

- No SDD target management.
- No SSH key import/export.
- No DNS/HA/VIP/route or host drop path changes.
- `checksum_delete_identical` remains opt-in; default duplicate mode is `filename`.
