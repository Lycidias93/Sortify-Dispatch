<!-- SORTIFY_DOWNLOAD_CLEANUP_STALE_REVIEW_ROLLBACK_INFO_START -->
## vNext - Download cleanup stale review and rollback info

- Added scan output `stale_review_candidates.tsv` for old-looking `pixel_local__*` helper artifacts.
- Kept `pixel_local__*` protected/local-hold; stale-review is metadata only and is not archive-safe input.
- Improved `rollback-info` to report latest run, manifest, rollback, archive and items paths.
- Kept archive-safe explicit/manual only with no service, boot, watcher, watchdog or queue integration.
- Kept no-runtime/no-host/no-route/no-SDD-marker and no-SHA-sidecar boundaries.
<!-- SORTIFY_DOWNLOAD_CLEANUP_STALE_REVIEW_ROLLBACK_INFO_END -->

<!-- SORTIFY_DOWNLOAD_CLEANUP_MAINTENANCE_VNEXT_CHANGELOG_START -->
## vNext - Download cleanup maintenance

- Added a planned Pixel-local Download cleanup maintenance helper with scan, guard, archive-safe, verify and rollback-info commands.
- Kept archive-safe explicit/manual only; no service, boot, watcher, watchdog or queue integration.
- Protected `pixel_local__*`, `heimnetz__*`, target prefixes, dot/runtime names, active app folders and Git worktrees.
- Kept SDD marker writes, host-run, SSH and DNS/HA/VIP/route behavior unchanged.
<!-- SORTIFY_DOWNLOAD_CLEANUP_MAINTENANCE_VNEXT_CHANGELOG_END -->

<!-- CHANGELOG_SORTIFY_DISPATCH_V465_SORT_MODE_CONTROL_START -->
## 4.6.5-sort-mode-control - Sort Mode Control

- Added `SORTIFY_SORT_MODE=interval|manual|boot_once`.
- Added WebUI sort mode selector, Mode Status and bounded Preview Sort.
- Split automatic service execution into `--service-cycle` while keeping `--sort` as manual Sort Now.
- Kept Sortify/SDD policy contract at `v4115` and SDD marker root read-only.
- No SDD target management, SSH key handling, host-run, DNS/HA/VIP/route or host-drop changes.
<!-- CHANGELOG_SORTIFY_DISPATCH_V465_SORT_MODE_CONTROL_END -->

<!-- CHANGELOG_SORTIFY_DISPATCH_V464_STATE_CONTRACT_PREVIEW_START -->
## 4.6.4-state-contract-preview - State Contract Preview

- Added read-only `--explain-route <filename-or-path>`.
- Added read-only `--marker-status <filename-or-path>`.
- Added read-only `--contract-smoke`.
- Kept Sortify/SDD policy contract at `v4115`.
- Kept SDD marker root read-only from Sortify.
- No SDD target management, SSH key handling, host-run, DNS/HA/VIP/route or host-drop changes.
<!-- CHANGELOG_SORTIFY_DISPATCH_V464_STATE_CONTRACT_PREVIEW_END -->

## 4.6.1-install-ui-hotfix

- Fix update/install dialog changelog source to use raw Markdown instead of GitHub HTML release page.
- Guard optional `uninstall.sh` permission handling during install.
- No runtime behavior change to smart categories, checksum duplicate handling, SDD marker contract, DNS/HA/VIP/route, or host drop paths.

<!-- SORTIFY_DISPATCH_V451_CUSTOM_PARK_PREFIXES_CHANGELOG_START -->
## 2026-06-01 - Sortify Dispatch 4.5.1-custom-park-prefixes

- Add configurable custom park prefixes for local hold-only artifacts.
- Add WebUI editor for custom prefixes, guard bounds and filename testing.
- Bound `--guard-status` with configurable max-file and timeout settings.
- Keep SDD link status read-only; no SDD target/config/SSH-key handling.
- Keep config export Sortify-only while including custom prefix and guard-bound keys.
<!-- SORTIFY_DISPATCH_V451_CUSTOM_PARK_PREFIXES_CHANGELOG_END -->

<!-- SORTIFY_DISPATCH_V45_WEBUI_UX_START -->
## 4.5-webui-ux

- Add Sortify-only WebUI UX refresh with current v4.5 header and explicit scope boundary.
- Add safe WebUI mode presets: normal mode, maintenance safe-hold, guard-only and explicit unsafe sorting without protected hold.
- Add `action.sh --config-export` for Sortify-only config export ZIPs.
- Keep SDD target creation, SDD config import/export, SSH key handling and private runtime migration out of Sortify WebUI.
- Keep dispatcher link status read-only and generic public artifact examples.

<!-- SORTIFY_DISPATCH_V45_WEBUI_UX_END -->

<!-- SORTIFY_SDD_CROSS_REPO_LINK_CHANGELOG_20260601_START -->
## 2026-06-01 - README cross-link to SSH Drop Dispatcher

- Added a top-of-file README link from Sortify Dispatch to SSH Drop Dispatcher.
- Updated operative README text to the `v4.4-ssh-drop-dispatcher` release and SSH Drop Dispatcher terminology.

<!-- SORTIFY_SDD_CROSS_REPO_LINK_CHANGELOG_20260601_END -->

<!-- SORTIFY_DISPATCH_V44_SDD_CHANGELOG_START -->
## v4.4-ssh-drop-dispatcher

- Align Sortify Dispatch source, status output, WebUI labels, and defaults with SSH Drop Dispatcher runtime `/data/adb/ssh-drop-dispatcher`.
- Keep v4115 remote marker contract for `target-*__` and `targets-*__` artifacts.
- Keep Pixel-local/Termux/repo artifacts protected locally and do not auto-release them from `rc=0`.
- Add generic dispatcher status keys and keep legacy pidd compatibility aliases.

<!-- SORTIFY_DISPATCH_V44_SDD_CHANGELOG_END -->

## 2026-05-25 - v4.3-pidd-v4115-contract

- Released the PIDD v4.11.0 / policy v4115 Sortify marker contract.
- Dispatcher release markers are accepted only with released=yes, authority=dispatcher, matching sha256, matching size, policy=v4115, and empty pending_targets.
- Missing marker, partial delivery, legacy policy, SHA/size mismatch, or non-dispatcher authority keeps protected artifacts held in Download.
- Normal unrelated downloads continue to sort automatically.
- Static synthetic smoke and staged runtime config smoke were green before release packaging.

<!-- SORTIFY_PIDD_V4110_CONTRACT_20260525_START -->
## 2026-05-25 - PIDD v4.11 Sortify marker contract candidate

- Added final `policy=v4115` release gate for Pixel Drop Dispatcher markers.
- Added SHA/size/authority/pending target validation before protected artifacts are released from Download.
- Kept `off` mode independent from Pixel Drop Dispatcher.
- Kept `auto` mode active only when PIDD runtime and marker directory are healthy.
- Treated older RC marker policies as evidence, not final release.
<!-- SORTIFY_PIDD_V4110_CONTRACT_20260525_END -->

# Changelog

## 2026-05-17 - v4.2-optional-dispatcher

- Released optional dispatcher integration controls.
- Added config flags: `SORTIFY_DISPATCHER_INTEGRATION=off|auto|on`, `SORTIFY_HOLD_PROTECTED=0|1`, `SORTIFY_NORMAL_SORT=0|1`.
- Added WebUI controls for normal sort, protected hold, and dispatcher integration mode.
- Added `--config-status` output and verified active Pixel runtime smoke.
- Default remains safe for users without Pixel Drop Dispatcher: `auto`, protected hold enabled, normal sorting enabled.

## Unreleased

- Documented the Artifact Hold / Release Contract for Dispatcher, Termux, and Sortify interaction.
- Clarified that normal downloads continue to sort automatically and only operational workflow artifacts are held.
- Added public Dispatcher release gate: public release follows private/proven Dispatcher release verification.


## v4.1-guard-tools - 2026-05-16

- Added `--guard-status` to audit protected artifacts in Download and misplaced protected artifacts in Sortify folders.
- Added safe `--guard-clean` to restore misplaced Dispatcher, Pixel, Termux, release, and repo helper artifacts to Download.
- Guard clean never overwrites existing Download files; collisions move to `/sdcard/Sortify/GuardConflicts/<timestamp>/`.
- Added read-only `--dispatcher-status` link check for Pixel Drop Dispatcher runtime metadata.
- Improved KernelSU WebUI with interval config, guard logging toggle, guard status, safe guard clean, dispatcher link status, and manual sort.
- Updated online update metadata to `Lycidias93/Sortify-Dispatch` release `v4.1-guard-tools`.
- Added repo build and smoke gates.

## v4.0-artifact-guard - 2026-05-16

- Forked Sortify v4.0 as Sortify Dispatch.
- Added Artifact Guard for Dispatcher, Pixel-local, Termux, Magisk/KernelSU release, and repo helper artifacts.
- Published `Sortify-Dispatch-v4.0-artifact-guard.zip` with SHA256.

<!-- SORTIFY_VNEXT_OPTIONAL_DISPATCHER_INTEGRATION_20260517_START -->
## 2026-05-17 - vNext optional dispatcher integration design

- Documented that Sortify must remain usable without Pixel Drop Dispatcher.
- Planned config flag: `SORTIFY_DISPATCHER_INTEGRATION=off|auto|on`.
- Planned default: `auto`, with safe fallback when dispatcher runtime is missing.
- Documented that unrelated downloads continue to sort and must not be held.
<!-- SORTIFY_VNEXT_OPTIONAL_DISPATCHER_INTEGRATION_20260517_END -->

<!-- SORTIFY_OPTIONAL_DISPATCHER_IMPLEMENTED_20260517_START -->
## 2026-05-17 - Optional dispatcher integration source implementation

- Added config flags for dispatcher integration, protected-artifact hold, and normal sorting.
- Added `--config-status` action output.
- Added WebUI controls for normal sorting, hold protected artifacts, and dispatcher integration mode.
- Kept default dispatcher integration as `auto` to avoid breaking users without Pixel Drop Dispatcher.
- Replaced WebUI config write heredoc with a quoted `printf` write path.
<!-- SORTIFY_OPTIONAL_DISPATCHER_IMPLEMENTED_20260517_END -->

## 4.6-smart-dedupe - 2026-06-05

- Added smart categories for ebooks, code, config, data, fonts, certificates, backups and torrents.
- Added optional checksum duplicate handling with safe deletion only on matching SHA-256.
- Added WebUI controls for duplicate mode, guard temp cleanup and log rotation.
- Kept SDD target/SSH management read-only/out-of-scope.

<!-- SORTIFY_V462_CONFIG_PRESERVE_20260606_START -->
## 4.6.2-config-preserve - 2026-06-06

- Preserves existing Sortify config during Magisk upgrades.
- Keeps custom park prefixes, duplicate handling mode, guard bounds, log rotation and dispatcher integration settings.
- Keeps v4.6 smart categories and checksum duplicate handling behavior unchanged.
- Keeps update changelog raw Markdown/plain text.

Risk: low for release metadata/config preservation; no SDD, SSH, DNS, HA, VIP, route or host drop path changes.
<!-- SORTIFY_V462_CONFIG_PRESERVE_20260606_END -->
