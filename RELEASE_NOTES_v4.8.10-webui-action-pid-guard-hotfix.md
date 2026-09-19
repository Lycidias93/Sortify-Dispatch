# Sortify Dispatch 4.8.10 WebUI Action PID guard hotfix

Candidate release for exact-device acceptance.

- Pins shared WebUI Core 0.7.1.
- Replaces the Android-hanging Action PID identity NUL-translation pipeline with direct procfs fixed-string matching.
- Keeps Core 0.7.0 standardized ntfy status/test and Sortify start/success/fail lifecycle behavior.
- Keeps remote protected `marker_only|marker_or_age` policy and separate retention days unchanged.
- Stable `update.json` is intentionally not promoted by this candidate.
