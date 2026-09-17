# Sortify Dispatch 4.8.9 notifications + retention options

Candidate release for exact-device acceptance.

- WebUI Core 0.7.0 standardized ntfy integration.
- Notifications tab exposes only configured/enabled state and a guarded test send; secrets remain in the SDD private runtime.
- Sort runs can notify on start/success/fail; notification delivery is advisory and never changes the sort result.
- Remote `target-/targets-` artifacts remain marker-only by default. Optional `marker_or_age` adds a separate mtime-based TTL fallback.
- Local protected retention remains independent.
