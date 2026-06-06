# Sortify Dispatch 4.6.1-install-ui-hotfix

Install-UI hotfix for v4.6 smart dedupe.

## Fixed

- `update.json` now points `changelog` to a plain raw Markdown file instead of a GitHub HTML release page.
- Magisk/KernelSU update/install dialogs should no longer show raw GitHub HTML attributes such as `data-color-mode`.
- `customize.sh` now sets `uninstall.sh` permissions only when the file exists, avoiding the harmless but noisy missing-file warning during install.

## Kept from v4.6

- Smart categories and extended file-type routing.
- Optional checksum duplicate handling.
- Identical checksum source deletion only when explicitly enabled.
- Different checksum duplicates move to `Duplicates`.
- Guard temp cleanup and log rotation.
- Sortify-only WebUI scope.

## Not changed

- No SSH Drop Dispatcher target or SSH key management.
- No SDD marker contract change.
- No DNS/HA/VIP/route or host drop path change.
