# Sortify 4.8.3 WebUI actions hotfix

This source follow-up to the current 4.8.2 stable channel fixes the WebUI action surface without changing the stable update channel by itself.

## Fixed surfaces

- Shared WebUI Core pin advances from `b08dba9da0b26f93808c5382445fa985997716ea` to `c5b47fb57e2b10d8b9f98448a7b692909ab956d8` while remaining Core `0.6.1`.
- Long action output stays in a bounded Actions result panel instead of expanding the global mobile notice.
- Safe read-only actions use `Run check` rather than mutation wording.
- Adapter semantic failures remain structured JSON (`ok=false`) so their detailed output reaches the browser instead of collapsing into a generic backend failure.
- Guard/action output reads the installed module version instead of carrying the stale `4.7.1-webui-cleanup-hotfix` string.

## Verification

The permanent vNext workflow runs the source contract suite, the dedicated WebUI actions hotfix regression, the canonical shared WebUI release audit, the real loopback HTTP integration test, and the deterministic package build. Exact installed-device acceptance remains a separate release gate.

The public stable channel remains 4.8.2 until a separately authorized and fully accepted release lane advances it.
