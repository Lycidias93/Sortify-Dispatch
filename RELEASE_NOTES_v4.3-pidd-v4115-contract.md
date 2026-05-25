# Sortify Dispatch v4.3-pidd-v4115-contract

Date: 2026-05-25

## Summary

- Releases the PIDD v4.11.0 / policy v4115 Sortify marker contract.
- Protected Dispatcher target artifacts are released only when released=yes, authority=dispatcher, sha256 matches, size matches, policy=v4115, and pending_targets is empty.
- Missing markers, partial pending targets, legacy policies, SHA/size mismatches, and wrong authority keep artifacts held in Download.
- Normal unrelated downloads continue to sort automatically.
- Dispatcher integration modes remain off, auto, and on.
- SORTIFY_NORMAL_SORT=0 remains a no-op gate.

## Verification before release candidate package

- Static synthetic smoke: PASS.
- Runtime staged config smoke on Pixel: PASS.
- DNS/HA/VIP/Route: not changed.

## Install note

Install via Magisk/KernelSU-compatible module update path, then run post-install and post-reboot checks before Heimnetz final documentation.
