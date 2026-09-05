# Sortify 4.8.3 WebUI Core mobile-input sync — 2026-09-05

## Trigger

The Pixel accepted the originally built 4.8.3 candidate after reboot, including the
real loopback WebUI bootstrap, status and `guard-status` action path. Before public
release, the shared WebUI Core main advanced from
`c5b47fb57e2b10d8b9f98448a7b692909ab956d8` to
`e7aa23ebb36be9b9075c66693d045a19413af8b1`.

The current shared Core remains version `0.6.1` but adds the generic
`mobile-input-viewport.js` behavior that keeps focused form controls visible above
the Android software keyboard.

## Release-gate consequence

The shared WebUI sync policy requires a consumer candidate to rebuild and reverify
after a Core pin change. The earlier accepted 4.8.3 package therefore remains valid
historical device evidence for its exact bytes, but it is no longer the publishable
candidate.

Public stable remains `4.8.2-webui-functional-hotfix`.

## Sync

The first sync attempt exposed a shared-Core release blocker: the new page referenced `mobile-input-viewport.js`, but the loopback server allowlist did not serve it. Shared Core PR #19 repaired that generic route and bound it into server, verify and loopback integration coverage.

Sortify 4.8.3 is rebound to:

- WebUI Core commit `efd19b1e892a8ce9bd97490ef3ea9c2f2eeed7f7`;
- Core version `0.6.1`;
- Core manifest SHA-256
  `94600c81b15571571e175f8a16e92177a77269541165f19886c86c0c332e1119`.

The gitlink, `webui.lock`, build/test commit constants, current-main README text,
4.8.3 release notes and user-facing CHANGELOG are kept consistent.

## Required next acceptance

The repository build must regenerate the exact installable candidate with the new
Core pin and pass the shared release audit plus real loopback integration test.
Because the package bytes change, that new exact ZIP must then be installed and
reboot/runtime audited on Pixel before any public 4.8.3 release.
