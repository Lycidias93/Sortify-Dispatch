# Changelog

## v4.0-artifact-guard - 2026-05-16

- Add Artifact Guard for Pixel Drop Dispatcher target artifacts.
- Keep Pixel-local and Termux helper scripts in `/sdcard/Download`.
- Keep dispatcher, Sortify Dispatch, and Magisk/KernelSU release ZIPs in `/sdcard/Download`.
- Keep repo helper scripts in `/sdcard/Download`.
- Keep normal Sortify categories and duplicate handling.
- Replace non-portable `read -d` loops with POSIX-compatible `find -print | read -r` loops for Android shell compatibility.

## v4.0 upstream baseline

- Native KernelSU WebUI support.
- Background sorting service.
- Manual action trigger.
- Documents, Images, Videos, Audio, Archives, Apps, Others, and Duplicates categories.
