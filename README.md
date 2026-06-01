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
**Version:** 4.4-ssh-drop-dispatcher

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
