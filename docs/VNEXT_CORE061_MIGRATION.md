# Sortify Dispatch vNext / WebUI Core 0.6.1

## Scope

This document defines the repository-side vNext migration from public stable `4.7.1-webui-cleanup-hotfix` to the next Sortify Dispatch candidate. It does not promote a public release or claim installed Pixel acceptance.

## Shared WebUI source

- repository: `Lycidias93/android-root-module-webui-template`
- Core: `0.6.1`
- pinned commit: `6fbd1b018a45fe5b1bebba7aeb9142423eab47fb`
- lock: `webui.lock`
- consumption: pinned Git submodule `.webui-core`; the build copies only the pinned shared module WebUI/launcher into the staging tree and compiles the pinned loopback server.

The Gitlink is the source pin. The optional `branch = main` entry in `.gitmodules` is discovery metadata only; `git submodule update --init --checkout` checks out the superproject Gitlink and the build rejects any Core HEAD other than the pinned commit.

## Domain boundary

Sortify-owned behavior remains in `module/bin/sortify-domain`. The current v4115 release-marker implementation is retained unchanged for this migration.

Shared Core owns:

- Action/embedded-host bootstrap;
- loopback HTTP session and one-time bootstrap token;
- generic Settings/Actions/Jobs/Inventory UX;
- typed request staging and validation boundaries;
- race/stale-response and observability UI behavior.

Sortify owns:

- sorting and guard behavior;
- duplicate policy;
- local-hold classification;
- Download Cleanup semantics;
- SDD marker interpretation and policy `v4115`;
- persistent configuration validation and atomic apply.

## Persistent configuration

Target: `/data/adb/sortify/sortify.conf`.

Upgrade behavior:

1. `customize.sh` creates `/data/adb/sortify` with private permissions.
2. If no persistent config exists, the previous active `/data/adb/modules/sortify/sortify.conf` is copied unchanged; otherwise packaged defaults are used.
3. `module-control` completes missing legacy keys using the existing safe defaults and writes a pre-normalization backup before the first normalization write.
4. Every WebUI config apply validates the complete typed object, creates a timestamped backup, writes a temporary file, then atomically renames it into place.
5. SDD runtime path, marker directory and policy remain fixed backend values rather than editable WebUI fields.

Managed settings:

- `INTERVAL`
- `GUARD_LOG`
- `SORTIFY_NORMAL_SORT`
- `SORTIFY_SORT_MODE`
- `SORTIFY_HOLD_PROTECTED`
- `SORTIFY_DISPATCHER_INTEGRATION`
- `SORTIFY_CUSTOM_PARK_PREFIXES`
- `SORTIFY_GUARD_MAX_FILES`
- `SORTIFY_GUARD_STATUS_TIMEOUT`
- `SORTIFY_DUPLICATE_MODE`
- `SORTIFY_LOG_MAX_KB`
- `SORTIFY_GUARD_TEMP_CLEAN_ON_SORT`
- `SORTIFY_PREVIEW_MAX_FILES`

## Typed WebUI operations

Base actions cover manual sort/preview, guard status/clean, temp cleanup, read-only dispatcher status, contract smoke and log rotation.

Bounded jobs cover cleanup scan and configuration export. Core v0.4 typed jobs cover filename testing, route explanation, marker status and run-id-bound cleanup operations. Archive/review operations retain exact confirmation values (`ARCHIVE_SAFE`, `APPROVE`, `APPLY`) as validated typed fields. Filename operations accept names only, never arbitrary filesystem paths.

## Build contract

`tools/build-release.sh` is now the candidate builder despite its legacy filename. It:

1. initializes the exact Gitlink when needed;
2. rejects Core commit/version drift;
3. runs `tools/test-vnext.sh`;
4. stages the module-owned source;
5. overlays the pinned Core Action/WebUI and standard installer metadata;
6. cross-compiles the pinned ARM64 loopback server;
7. copies the Sortify cleanup helper;
8. compares staged Core files to the pin;
9. writes a deterministic ZIP plus `dist/build-manifest.json`.

No `.sha256` sidecar is produced.

## Repository verification

The source verifier checks shell/Python syntax, capabilities/status/config JSON, the full Settings surface, atomic config apply/backup, reserved `target-*` prefix rejection, `SORTIFY_PREVIEW_MAX_FILES`, and fixed SDD policy `v4115`.

Fresh installed-runtime acceptance remains mandatory before public promotion.

## Device acceptance gate before public release

Verify on the Pixel test device:

- battery/install readiness;
- exact candidate ZIP identity from `build-manifest.json`;
- upgrade from installed stable with the old config present;
- persistent config migration and byte/value preservation for all previously configured keys;
- normal boot and Sortify service behavior for `interval`, `manual`, and `boot_once`;
- browser Action launch and clean final URL;
- compatible embedded WebUI launch into the same loopback session;
- loopback-only listener and absence of arbitrary browser shell/path transport;
- typed settings round trip including Preview file limit;
- manual sort preview and apply;
- guard actions/inventories;
- typed filename/route/marker operations;
- cleanup scan/guard/preview/apply/verify gates on a controlled fixture;
- SDD `v4115` marker smoke against the installed current SDD;
- config preservation after reboot/module update;
- rollback to stable source/package plus preserved legacy/persistent config if acceptance fails.

## Rollback

Repository rollback is a Git revert of the vNext merge. No stable `update.json` or public release is changed by this source migration.

Device rollback uses the last accepted stable module package. The old active config is not deleted during install migration, persistent config backups are retained, and uninstall preserves `/data/adb/sortify` plus `/sdcard/Sortify` by default.
