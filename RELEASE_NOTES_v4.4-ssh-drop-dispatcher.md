# Sortify Dispatch v4.4-ssh-drop-dispatcher

## Summary

- Switch visible defaults and status terminology to SSH Drop Dispatcher.
- Use `/data/adb/ssh-drop-dispatcher` as the dispatcher runtime default.
- Preserve v4115 marker contract for remote target artifacts.
- Keep Pixel-local Termux artifacts protected locally.
- `rc=0` is not an automatic release signal; explicit local-release marker is planned later.

## Verification plan

- Source static gates.
- Synthetic marker smoke.
- Pixel runtime stage with backup.
- Runtime readback before GitHub release.
