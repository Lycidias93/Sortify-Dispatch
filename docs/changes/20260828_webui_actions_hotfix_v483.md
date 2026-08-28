# 2026-08-28 — Sortify 4.8.3 WebUI actions hotfix

## Problem

The 4.8.2 WebUI could still present poor or misleading action UX on mobile: long action output could dominate the screen, safe read-only actions used mutation wording, semantic adapter failures could collapse into a generic backend error, and some action/guard output still exposed a stale 4.7.1 version string.

## Root cause

The frontend is sourced from the pinned shared WebUI Core during packaging, while Sortify owns the module-specific adapter/domain behavior. Fixing the complete path therefore requires both the shared Core follow-up and the Sortify adapter transport/version fixes.

## Change

- Pin shared WebUI Core commit `c5b47fb57e2b10d8b9f98448a7b692909ab956d8` (Core 0.6.1).
- Preserve bounded action output and correct read-only action labels from that Core.
- Keep domain action failure details in structured JSON while treating successful JSON serialization as a successful transport operation.
- Derive displayed action/guard version information from the installed `module.prop`.
- Add a dedicated 4.8.3 regression test and wire it into the permanent vNext verification workflow.
- Build/upload the 4.8.3 candidate in CI; installed-device WebUI acceptance remains mandatory before any public release.

README checked: updated with the unreleased source-hardening state. Public stable channel remains 4.8.2.
