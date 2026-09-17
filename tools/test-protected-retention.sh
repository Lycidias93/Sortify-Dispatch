#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/download" "$TMP/dest" "$TMP/module"
cp "$ROOT/module/module.prop" "$TMP/module/module.prop"
cat > "$TMP/sortify.conf" <<'CFG'
GUARD_LOG=0
SORTIFY_NORMAL_SORT=1
SORTIFY_SORT_MODE=manual
SORTIFY_HOLD_PROTECTED=1
SORTIFY_PROTECTED_RETENTION_DAYS=30
SORTIFY_DISPATCHER_INTEGRATION=off
SORTIFY_CUSTOM_PARK_PREFIXES=park__
CFG
printf old > "$TMP/download/pixel_local__old.txt"
printf fresh > "$TMP/download/pixel_local__fresh.txt"
printf target > "$TMP/download/target-pi4__old.txt"
printf handover > "$TMP/download/HANDOVER_old.md"
printf park > "$TMP/download/park__old.zip"
touch -d '31 days ago' "$TMP/download/pixel_local__old.txt" "$TMP/download/target-pi4__old.txt" "$TMP/download/HANDOVER_old.md" "$TMP/download/park__old.zip"
DOWNLOADS="$TMP/download" DEST_BASE="$TMP/dest" MODULE_DIR="$TMP/module" CONF_PATH="$TMP/sortify.conf" sh "$ROOT/module/bin/sortify-domain" --sort >/dev/null
test -f "$TMP/dest/Documents/pixel_local__old.txt"
test -f "$TMP/download/pixel_local__fresh.txt"
test -f "$TMP/download/target-pi4__old.txt"
test -f "$TMP/dest/Documents/HANDOVER_old.md"
test -f "$TMP/dest/Archives/park__old.zip"
cat > "$TMP/sortify.conf" <<'CFG'
GUARD_LOG=0
SORTIFY_NORMAL_SORT=1
SORTIFY_SORT_MODE=manual
SORTIFY_HOLD_PROTECTED=1
SORTIFY_PROTECTED_RETENTION_DAYS=0
SORTIFY_DISPATCHER_INTEGRATION=off
SORTIFY_CUSTOM_PARK_PREFIXES=
CFG
printf never > "$TMP/download/pixel_local__never.txt"
touch -d '365 days ago' "$TMP/download/pixel_local__never.txt"
DOWNLOADS="$TMP/download" DEST_BASE="$TMP/dest" MODULE_DIR="$TMP/module" CONF_PATH="$TMP/sortify.conf" sh "$ROOT/module/bin/sortify-domain" --sort >/dev/null
test -f "$TMP/download/pixel_local__never.txt"
echo 'protected_retention_old_local_release=PASS'
echo 'protected_retention_fresh_local_hold=PASS'
echo 'protected_retention_remote_target_marker_gate=PASS'
echo 'protected_retention_zero_never=PASS'
