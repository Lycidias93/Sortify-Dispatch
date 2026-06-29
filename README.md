<!-- SORTIFY_ARCHIVE_REVIEW_APPROVED_DRY_RUN_README_START -->
## vNext: archive-review-approved dry-run

Sortify Download cleanup now has a planning-only `archive-review-approved dry-run` command. It requires an explicit run id and `SORTIFY_CLEANUP_APPROVED_FOR_ARCHIVE=yes`, reads the approval preview, accepts only A/C review candidates, blocks B/D/E, and writes only `planned_review_archive_manifest.tsv`. It does not move files.
<!-- SORTIFY_ARCHIVE_REVIEW_APPROVED_DRY_RUN_README_END -->

<!-- SORTIFY_DOWNLOAD_CLEANUP_STALE_REVIEW_ROLLBACK_INFO_START -->
## vNext: Download cleanup stale review and rollback info

Sortify Download cleanup maintenance now plans `stale_review_candidates.tsv` for old-looking `pixel_local__*` helper artifacts while preserving the local-hold contract. `archive-safe` still moves only guarded safe candidates. `rollback-info` reports the latest run, manifest, rollback, archive and items paths. No service, boot, watcher, watchdog or queue integration is added.
<!-- SORTIFY_DOWNLOAD_CLEANUP_STALE_REVIEW_ROLLBACK_INFO_END -->

<!-- SORTIFY_DOWNLOAD_CLEANUP_MAINTENANCE_VNEXT_README_START -->
## vNext: Download cleanup maintenance

Sortify Dispatch has a planned Pixel-local Download cleanup maintenance helper with `scan`, `guard`, `archive-safe`, `verify` and `rollback-info` commands. The helper is explicit/manual only and does not run from service, boot, watcher, watchdog or queue processing. It protects `pixel_local__*`, `heimnetz__*`, `target-*__*`, `targets-*__*`, active app folders, dot/runtime names and Git worktrees.
<!-- SORTIFY_DOWNLOAD_CLEANUP_MAINTENANCE_VNEXT_README_END -->

<!-- SORTIFY_DISPATCH_V465_SORT_MODE_CONTROL_START -->
## Sortify Dispatch v4.6.5 - Sort Mode Control

Release: `4.6.5-sort-mode-control` / `versionCode=23`.

This release adds explicit automatic sort mode control:

- `interval`: service sorts every configured interval.
- `manual`: disables automatic timed sorting while keeping Sort Now available.
- `boot_once`: sorts once after reboot, then skips further service cycles until the next reboot.

New CLI/WebUI actions:

```sh
su -c sh /data/adb/modules/sortify/action.sh --mode-status
su -c sh /data/adb/modules/sortify/action.sh --preview-sort
su -c sh /data/adb/modules/sortify/action.sh --sort
```

Scope remains unchanged for infrastructure safety: no SDD marker writes, no SDD target management, no SSH key handling, no host-run, no DNS/HA/VIP/route changes.
<!-- SORTIFY_DISPATCH_V465_SORT_MODE_CONTROL_END -->

<!-- SORTIFY_DISPATCH_V464_STATE_CONTRACT_PREVIEW_START -->
## Sortify Dispatch v4.6.4 - State Contract Preview

Release: `4.6.4-state-contract-preview` / `versionCode=22`.

This release adds read-only operator inspection for the existing SSH Drop Dispatcher contract.

New CLI actions:

```sh
su -c sh /data/adb/modules/sortify/action.sh --explain-route <filename-or-path>
su -c sh /data/adb/modules/sortify/action.sh --marker-status <filename-or-path>
su -c sh /data/adb/modules/sortify/action.sh --contract-smoke
```

Scope:

- `--explain-route` classifies local-hold, Markdown/Handover, Pixel-local and remote target artifacts.
- `--marker-status` reads the existing dispatcher marker root and reports `released`, `authority`, `policy`, target fields and final gate.
- `--contract-smoke` verifies Sortify-side expectations for `policy=v4115`, local holds, remote target holds and normal sortable files.
- SDD marker root remains read-only from Sortify.
- No SDD target management, no SSH key handling, no ntfy secret handling, no host run, no DNS/HA/VIP/route changes.
<!-- SORTIFY_DISPATCH_V464_STATE_CONTRACT_PREVIEW_END -->

<!-- SORTIFY_DISPATCH_V463_MARKDOWN_HANDOVER_HOLD_START -->
## Sortify Dispatch v4.6.3 - Markdown/Handover local-hold

Release: `4.6.3-markdown-handover-hold` / `versionCode=21`.

What changed:
- Markdown/Handover operational files stay in `/sdcard/Download`:
  - `*handover*.md`
  - `README*.md`
  - `RELEASE_NOTES*.md`
- The rule is local-hold-only and never creates an SSH Drop Dispatcher release.
- Custom prefix `heimnetz__` remains supported for explicit Heimnetz local-hold files.
- `target-*__*` and `targets-*__*` remain the only dispatcher remote-target schemas.
- `action.sh --test-filename <name>` reports `reason=markdown_handover_hold` for these files.

Out of scope:
- No SDD target management.
- No SSH key handling.
- No DNS/HA/VIP/route or host-drop changes.
- No default change to `checksum_delete_identical`.
<!-- SORTIFY_DISPATCH_V463_MARKDOWN_HANDOVER_HOLD_END -->

<!-- SORTIFY_DISPATCH_V451_CUSTOM_PARK_PREFIXES_START -->
### 4.6.1-install-ui-hotfix install UI hotfix

- Update metadata changelog uses plain raw Markdown so Magisk/KernelSU dialogs do not display GitHub HTML.
- `customize.sh` ignores missing optional `uninstall.sh` during permission setup.
- No change to SDD targets, SSH keys, DNS/HA/VIP/route, or host drop paths.


## Sortify Dispatch 4.5.1-custom-park-prefixes

Sortify Dispatch `4.5.1-custom-park-prefixes` adds configurable **custom park prefixes** for local hold-only files.

Highlights:
- WebUI field for custom park prefixes such as `mypark__`, `hold__`, `nosort__` or `skoda__`.
- Custom prefixes are local hold only; they never create SSH targets and never release files through the SSH Drop Dispatcher.
- `action.sh --test-filename <name>` shows whether a filename is held by a custom prefix or built-in rule.
- `action.sh --guard-status` is bounded by `SORTIFY_GUARD_MAX_FILES` and `SORTIFY_GUARD_STATUS_TIMEOUT`.
- Config export remains Sortify-only and includes custom park prefixes plus guard bounds.

Out of scope:
- No SDD target creation/editing.
- No SDD config import/export.
- No SSH key handling.
- No private runtime migration.
<!-- SORTIFY_DISPATCH_V451_CUSTOM_PARK_PREFIXES_END -->

<!-- SORTIFY_DISPATCH_V45_WEBUI_UX_START -->
## Sortify Dispatch v4.5 - WebUI UX

Planned release: `4.5-webui-ux` / `versionCode=16`.

- WebUI is Sortify-only: no SSH target management, no SDD config import/export, no SSH key handling.
- Adds mode presets for normal operation, maintenance safe-hold, guard-only and explicit unsafe sorting without protected hold.
- Adds Sortify-only config export ZIP via `action.sh --config-export`.
- Dispatcher link remains read-only status against the SSH Drop Dispatcher marker contract.
- Public examples stay generic (`target-alpha__*`, `targets-alpha-beta__*`, `pixel_local__*`, `termux-*`, `repo_*`).

<!-- SORTIFY_DISPATCH_V45_WEBUI_UX_END -->

<!-- SORTIFY_SDD_CROSS_REPO_LINK_20260601_START -->
## Companion: SSH Drop Dispatcher

Sortify Dispatch is the local sorter/protection companion for [SSH Drop Dispatcher](https://github.com/Lycidias93/ssh-drop-dispatcher).

- SSH Drop Dispatcher owns target delivery and writes authoritative `policy=v4115` release markers.
- Sortify Dispatch keeps `target-*__*` and `targets-*__*` artifacts in `/sdcard/Download` until that marker is valid.
- Pixel-local, Termux and repo helper artifacts stay local protected hold; `rc=0` is not an automatic release signal.

<!-- SORTIFY_SDD_CROSS_REPO_LINK_20260601_END -->

<!-- SORTIFY_DISPATCH_V44_SDD_START -->
## Sortify Dispatch v4.4 - SSH Drop Dispatcher alignment

Current release: `v4.4-ssh-drop-dispatcher` / `versionCode=15`.

- Default dispatcher runtime is `/data/adb/ssh-drop-dispatcher`.
- Remote protected artifacts still require the v4115 dispatcher release marker contract.
- Pixel-local Termux artifacts stay local protected hold only.
- `rc=0` never globally releases Pixel-local artifacts; explicit local-release marker is deferred to a later feature.
- Visible status uses generic dispatcher keys while legacy pidd keys remain compatibility aliases.

<!-- SORTIFY_DISPATCH_V44_SDD_END -->

<p align="center">
  <img src="banner.png" alt="Sortify Banner" width="100%" />
</p>

# Sortify Dispatch

**Original author:** [xCaptaiN09](https://github.com/xCaptaiN09)
**Fork maintainer:** [Lycidias93](https://github.com/Lycidias93)
**Version:** 4.6.5-sort-mode-control

Sortify Dispatch is a Magisk / KernelSU module based on Sortify v4.0. It keeps normal download sorting, but adds an Artifact Guard for SSH Drop Dispatcher, Pixel-local scripts, Termux helper scripts, Magisk/KernelSU release ZIPs, and repo helper artifacts.

## What stays in Download

The Artifact Guard keeps these operational artifacts in `/sdcard/Download`:

- `target-pi3__*`, `target-pi4__*`, `target-zeropi2__*`, `target-berylax__*`
- `targets-*__*`
- legacy host-prefixed artifacts: `pi3_*`, `pi4_*`, `zeropi2_*`, `berylax_*`
- Pixel-local scripts: `pixel_local__*`
- Termux helper artifacts: `termux-*`, `termux_*`, `pixel-termux*`, `pixel_termux*`
- dispatcher release artifacts: `pixel-drop-dispatch*`, `pixel_drop_dispatch*`, `ssh-drop-dispatcher*`, `ssh_drop_dispatcher*`, `*drop-dispatch*`, `*drop_dispatch*`
- Sortify Dispatch release artifacts: `sortify-dispatch*`, `sortify_dispatch*`
- Markdown/Handover files: `*handover*.md`, `README*.md`, `RELEASE_NOTES*.md`
- repo helper scripts: `repo_*.py`, `*_repo_*.py`, `repo_*.sh`, `*_repo_*.sh`

Normal documents, images, videos, audio files, archives, APKs, and other files are still sorted into `/sdcard/Sortify`.

## Guard tools

```sh
su -c sh /data/adb/modules/sortify/action.sh --guard-status
su -c sh /data/adb/modules/sortify/action.sh --guard-clean
su -c sh /data/adb/modules/sortify/action.sh --dispatcher-status
```

`--guard-clean` is safe by design: it restores misplaced protected artifacts to `/sdcard/Download` and moves same-name collisions to `/sdcard/Sortify/GuardConflicts/<timestamp>/` instead of overwriting or deleting.

## Dispatcher link

Sortify Dispatch does not control SSH Drop Dispatcher. It only provides read-only dispatcher link status and protects dispatcher-related artifacts from being sorted away.


## Hold / release contract

Sortify Dispatch holds only operational artifacts. Normal downloads are sorted automatically. Dispatcher target artifacts require Dispatcher release after successful delivery to every target; Pixel-local and Termux artifacts require explicit Termux/operator release. See `docs/HOLD_RELEASE_CONTRACT.md`.

## Installation

1. Download `Sortify-Dispatch-v4.4-ssh-drop-dispatcher.zip` from Releases.
2. Flash through Magisk or KernelSU.
3. Reboot if your module manager requires it.
4. Run Sortify manually or wait for the service interval.

## Manual trigger

```sh
su -c sh /data/adb/modules/sortify/action.sh
```

## WebUI

KernelSU WebUI can configure the interval, toggle guard logging, run guard status, run safe guard clean, show dispatcher link status, and trigger a manual sort.

## Online updates

`module.prop` and `update.json` point to this fork:

```text
https://raw.githubusercontent.com/Lycidias93/Sortify-Dispatch/main/update.json
```

## Module ID and path safety

The visible module name is `Sortify Dispatch`, but the module ID remains `sortify`. The active module path therefore stays stable at `/data/adb/modules/sortify`, so updates replace the existing Sortify module instead of installing a second parallel module.

## Release integrity

Each release ZIP is published with a SHA256 checksum.

## Changelog

See `CHANGELOG.md`.

## Credits

- Original Sortify module by [xCaptaiN09](https://github.com/xCaptaiN09)
- Artifact Guard fork maintained by [Lycidias93](https://github.com/Lycidias93)

<!-- SORTIFY_OPTIONAL_DISPATCHER_INTEGRATION_20260517_START -->
## Optional Dispatcher Integration

Sortify remains usable without Pixel Drop Dispatcher.

vNext design target:
- `SORTIFY_DISPATCHER_INTEGRATION=off|auto|on`
- default: `auto`
- `off`: normal Sortify behavior, no dispatcher runtime dependency
- `auto`: use dispatcher hold/release contract only when runtime is present and healthy
- `on`: require dispatcher contract and fail clearly if unavailable
- normal downloads must continue to sort even when dispatcher integration is disabled
<!-- SORTIFY_OPTIONAL_DISPATCHER_INTEGRATION_20260517_END -->

<!-- SORTIFY_OPTIONAL_DISPATCHER_IMPLEMENTED_20260517_START -->
## Optional integration controls

Source implementation date: `2026-05-17`.

Config file: `/data/adb/modules/sortify/sortify.conf`

Available flags:

```text
SORTIFY_DISPATCHER_INTEGRATION=off|auto|on
SORTIFY_HOLD_PROTECTED=0|1
SORTIFY_NORMAL_SORT=0|1
```

Default behavior stays safe for users without Pixel Drop Dispatcher:

- `SORTIFY_DISPATCHER_INTEGRATION=auto`
- `SORTIFY_HOLD_PROTECTED=1`
- `SORTIFY_NORMAL_SORT=1`

`auto` uses dispatcher-aware protected artifact holding only when Pixel Drop Dispatcher runtime is present and healthy. If dispatcher is absent, normal downloads keep sorting and protected artifacts are not hard-blocked by a missing dispatcher runtime.
<!-- SORTIFY_OPTIONAL_DISPATCHER_IMPLEMENTED_20260517_END -->

## Release 4.2-optional-dispatcher

This release promotes optional dispatcher integration controls from verified source/runtime smoke to public release:

- `SORTIFY_DISPATCHER_INTEGRATION=off|auto|on`
- `SORTIFY_HOLD_PROTECTED=0|1`
- `SORTIFY_NORMAL_SORT=0|1`
- WebUI controls for normal sorting, protected hold, and dispatcher integration mode
- `--config-status` action output

Users without Pixel Drop Dispatcher can use `off` or the default `auto` mode safely.

<!-- SORTIFY_PIDD_V4110_CONTRACT_20260525_START -->
## PIDD v4.11 Sortify contract

Stand: `2026-05-25`.

Sortify Dispatch can use Pixel Drop Dispatcher release markers when `SORTIFY_DISPATCHER_INTEGRATION=auto` or `on` and the PIDD runtime is healthy.

Required final marker contract:

- `released=yes`
- `authority=dispatcher`
- `sha256` matches the local Download artifact
- `size` matches the local Download artifact
- `policy=v4115`
- `pending_targets` is empty

Protected dispatcher artifacts stay in Download when no valid final marker exists. `released=no`, non-empty `pending_targets`, missing markers, SHA/size mismatches, non-`dispatcher` authority, or older RC policies such as `v4112`/`v4114` are treated as held evidence, not final release.

Modes:

- `off`: ignore dispatcher runtime and marker contract.
- `auto`: use the contract only when PIDD runtime and marker directory are healthy.
- `on`: require a healthy PIDD runtime and marker directory; otherwise sorting fails clearly.
<!-- SORTIFY_PIDD_V4110_CONTRACT_20260525_END -->

<!-- SORTIFY_V46_SMART_DEDUPE_START -->
## 4.6-smart-dedupe

Sortify Dispatch 4.6-smart-dedupe adds extended categories and optional SHA-256 duplicate handling. With `SORTIFY_DUPLICATE_MODE=checksum_delete_identical`, identical same-name duplicates are deleted after matching SHA-256; same-name files with different checksums are kept in `Duplicates` with collision-safe names. Custom Park Prefixes remain local-hold-only and SDD target/SSH management remains out of scope.
<!-- SORTIFY_V46_SMART_DEDUPE_END -->

<!-- SORTIFY_V462_CONFIG_PRESERVE_20260606_START -->
## v4.6.2 config preserve

`4.6.2-config-preserve` preserves existing Sortify settings during Magisk upgrades, including custom park prefixes, duplicate handling mode, guard bounds, log rotation and dispatcher mode.

Default duplicate mode remains `filename`; checksum-based deletion of identical source duplicates remains opt-in.
<!-- SORTIFY_V462_CONFIG_PRESERVE_20260606_END -->

## License

This project is licensed under the MIT License. See [LICENSE](./LICENSE).
