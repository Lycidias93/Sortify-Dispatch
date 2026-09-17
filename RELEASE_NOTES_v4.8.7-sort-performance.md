# Sortify Dispatch 4.8.7 sort performance

Candidate repair for the exact-device long-job acceptance failure.

- One productive Download scan instead of repeated per-extension scans.
- Guard-log rotation is prepared once per productive pass.
- Filename normalization, custom-prefix parsing and retention cutoff are cached for the pass.
- Protected retention remains 30 days by default; `0` still means indefinite local hold.
- `target-*` and `targets-*` remain dispatcher-marker gated.
- Stable update metadata is intentionally unchanged pending exact-device acceptance.
