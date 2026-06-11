# Sortify Dispatch v4.6.3-markdown-handover-hold

## Scope

This release adds an explicit Markdown/Handover local-hold category.

Held locally in `/sdcard/Download`:

- `*handover*.md`
- `README*.md`
- `RELEASE_NOTES*.md`

## Contract

- Markdown/Handover hold is local-only.
- It never creates SSH Drop Dispatcher targets.
- It never releases remote artifacts.
- `target-*__*` and `targets-*__*` remain the only remote target filename schemas.
- `heimnetz__*` remains a custom local-hold prefix.
- `checksum_delete_identical` remains opt-in and is not enabled by default.

## Verification targets

Expected filename tester results:

```text
sortify-dispatch-vnext-handover-20260611.md local_hold=yes reason=markdown_handover_hold
README_RELEASE.md local_hold=yes reason=markdown_handover_hold
RELEASE_NOTES_v4.6.3-markdown-handover-hold.md local_hold=yes reason=markdown_handover_hold
heimnetz__handover.md local_hold=yes reason=custom_prefix:heimnetz__
target-pi3__test.zip local_hold=yes reason=builtin_protected_pattern
targets-pi3-pi4__test.zip local_hold=yes reason=builtin_protected_pattern
normal-note.md local_hold=no reason=no_protected_pattern
```

## Non-goals

- No DNS/HA/VIP/route changes.
- No host-drop path changes.
- No SDD target registry changes.
- No SSH key changes.
