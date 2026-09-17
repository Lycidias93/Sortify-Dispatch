#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/bin" "$TMP/download" "$TMP/sort" "$TMP/module"
cp -a "$ROOT/module/." "$TMP/module/"
printf '0
' > "$TMP/find.count"
printf '0
' > "$TMP/wc.count"
cat > "$TMP/bin/find" <<'EOF'
#!/bin/sh
n=$(cat "$SORTIFY_FIND_COUNT_FILE"); printf '%s
' $((n + 1)) > "$SORTIFY_FIND_COUNT_FILE"
exec /usr/bin/find "$@"
EOF
cat > "$TMP/bin/wc" <<'EOF'
#!/bin/sh
n=$(cat "$SORTIFY_WC_COUNT_FILE"); printf '%s
' $((n + 1)) > "$SORTIFY_WC_COUNT_FILE"
exec /usr/bin/wc "$@"
EOF
chmod +x "$TMP/bin/find" "$TMP/bin/wc"
cat > "$TMP/module/sortify.conf" <<'EOF'
GUARD_LOG=1
SORTIFY_NORMAL_SORT=1
SORTIFY_SORT_MODE=manual
SORTIFY_HOLD_PROTECTED=1
SORTIFY_PROTECTED_RETENTION_DAYS=30
SORTIFY_DISPATCHER_INTEGRATION=off
SORTIFY_DUPLICATE_MODE=checksum_delete_identical
SORTIFY_GUARD_TEMP_CLEAN_ON_SORT=1
EOF
for i in $(seq 1 120); do printf 'hold-%s
' "$i" > "$TMP/download/pixel_local__fixture_$i.txt"; done
printf 'doc
' > "$TMP/download/normal.pdf"
printf 'image
' > "$TMP/download/normal.JPG"
SORTIFY_FIND_COUNT_FILE="$TMP/find.count" SORTIFY_WC_COUNT_FILE="$TMP/wc.count" PATH="$TMP/bin:$PATH" DOWNLOADS="$TMP/download" DEST_BASE="$TMP/sort" MODULE_DIR="$TMP/module" CONF_PATH="$TMP/module/sortify.conf" sh "$TMP/module/bin/sortify-domain" --sort > "$TMP/out"
[[ -f "$TMP/sort/Documents/normal.pdf" ]]
[[ -f "$TMP/sort/Images/normal.JPG" ]]
[[ -f "$TMP/download/pixel_local__fixture_1.txt" ]]
grep -Fq 'Manual sort completed' "$TMP/out"
find_count=$(cat "$TMP/find.count"); wc_count=$(cat "$TMP/wc.count")
(( find_count <= 3 ))
(( wc_count <= 2 ))
grep -Fq 'sort_downloads_single_pass' "$ROOT/module/bin/sortify-domain"
! sed -n '/^sort_now()/,/^}/p' "$ROOT/module/bin/sortify-domain" | grep -Fq 'move_files '
echo "single_pass_find_count=$find_count"
echo "guard_hotpath_wc_count=$wc_count"
echo 'RESULT: SORTIFY_SINGLE_PASS_PERFORMANCE_PASS'
