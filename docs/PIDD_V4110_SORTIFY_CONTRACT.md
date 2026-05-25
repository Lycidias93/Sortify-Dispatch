

<!-- SORTIFY_PIDD_V4110_CONTRACT_SPEC_20260525_START -->
# Sortify Dispatch vNext – PIDD v4.11 Contract

Date: `2026-05-25`

## Source of truth

Pixel Drop Dispatcher writes release markers under:

```text
/data/adb/pixel-drop-dispatch/integration/sortify-release/<sha256>.env
```

Sortify Dispatch only treats a protected dispatcher artifact as releasable when the marker is final and self-consistent:

```text
released=yes
authority=dispatcher
sha256=<local file sha256>
size=<local file size>
policy=v4115
pending_targets=''
```

## Hold cases

Sortify must hold protected artifacts in Download when:

- marker is missing
- marker has `released=no`
- marker has non-empty `pending_targets`
- marker policy is not `v4115`
- marker authority is not `dispatcher`
- marker SHA or size does not match the local artifact
- dispatcher integration is `on` but PIDD runtime/marker dir is unhealthy

## Compatibility

Older markers (`v4112`, `v4114`) are evidence only. They do not release artifacts through the final `v4115` gate.

`SORTIFY_DISPATCHER_INTEGRATION=off` preserves standalone Sortify behavior for users without PIDD.
<!-- SORTIFY_PIDD_V4110_CONTRACT_SPEC_20260525_END -->
