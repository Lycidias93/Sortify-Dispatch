<p align="center">
  <img src="banner.png" alt="Sortify Banner" width="100%" />
</p>

# Sortify Dispatch

**Original author:** [xCaptaiN09](https://github.com/xCaptaiN09)
**Fork maintainer:** [Lycidias93](https://github.com/Lycidias93)
**Version:** 4.1-guard-tools

Sortify Dispatch is a Magisk / KernelSU module based on Sortify v4.0. It keeps normal download sorting, but adds an Artifact Guard for Pixel Drop Dispatcher, Pixel-local scripts, Termux helper scripts, Magisk/KernelSU release ZIPs, and repo helper artifacts.

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

Sortify Dispatch does not control Pixel Drop Dispatcher. It only provides read-only dispatcher link status and protects dispatcher-related artifacts from being sorted away.

## Installation

1. Download `Sortify-Dispatch-v4.1-guard-tools.zip` from Releases.
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
