# Sortify Dispatch 4.8.6 protected retention

Candidate feature: configurable local protected-artifact retention.

- Default retention: 30 days.
- `0` means never auto-release local holds.
- Age source: file mtime.
- Applies to custom park, markdown/handover and Pixel-local hold classes.
- `target-*` and `targets-*` remain dispatcher-marker gated at every age.
- Stable update metadata is intentionally unchanged pending exact-device acceptance.
