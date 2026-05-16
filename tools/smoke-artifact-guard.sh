#!/usr/bin/env bash
set -euo pipefail

ROOT="$(mktemp -d "${TMPDIR:-/data/data/com.termux/files/usr/tmp}/sortify-dispatch-smoke.XXXXXX")"
trap 'rm -rf "$ROOT"' EXIT

export DOWNLOADS="$ROOT/Download"
export DEST_BASE="$ROOT/Sortify"
mkdir -p "$DOWNLOADS" "$DEST_BASE"

printf 'protected' > "$DOWNLOADS/target-pi3__guard_smoke.sh"
printf 'protected' > "$DOWNLOADS/pixel_local__guard_smoke.sh"
printf 'protected' > "$DOWNLOADS/termux-guard-smoke.zip"
printf 'protected' > "$DOWNLOADS/Sortify-Dispatch-v4.1-guard-tools.zip"
printf 'normal' > "$DOWNLOADS/normal_archive.zip"
printf 'normal' > "$DOWNLOADS/normal_note.txt"

smoke_log="$ROOT/sortify-dispatch-smoke-sort.log"
sh ./action.sh --sort >"$smoke_log" 2>&1 || { cat "$smoke_log"; exit 1; }

test -f "$DOWNLOADS/target-pi3__guard_smoke.sh"
test -f "$DOWNLOADS/pixel_local__guard_smoke.sh"
test -f "$DOWNLOADS/termux-guard-smoke.zip"
test -f "$DOWNLOADS/Sortify-Dispatch-v4.1-guard-tools.zip"
test -f "$DEST_BASE/Archives/normal_archive.zip"
test -f "$DEST_BASE/Documents/normal_note.txt"

status_out="$(sh ./action.sh --guard-status)"
printf '%s\n' "$status_out"
printf '%s\n' "$status_out" | grep -q 'guard_status=pass'

mkdir -p "$DEST_BASE/Archives"
printf 'misplaced' > "$DEST_BASE/Archives/target-pi4__misplaced.zip"
clean_out="$(sh ./action.sh --guard-clean)"
printf '%s\n' "$clean_out"
test -f "$DOWNLOADS/target-pi4__misplaced.zip"

dispatcher_out="$(sh ./action.sh --dispatcher-status)"
printf '%s\n' "$dispatcher_out" | grep -q 'dispatcher_runtime=' 

if grep -nE 'read[[:space:]].*-d' action.sh; then
  echo 'FAIL non_posix_read_d_present'
  exit 1
fi

echo 'sortify_smoke=pass'
