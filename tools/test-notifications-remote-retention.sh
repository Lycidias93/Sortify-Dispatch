#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/download" "$TMP/sort" "$TMP/sdd/integration/sortify-release" "$TMP/module/lib"
cp "$ROOT/module/module.prop" "$TMP/module/module.prop"
cp "$ROOT/.webui-core/module/lib/ntfy.sh" "$TMP/module/lib/ntfy.sh"
printf '%s\n' '#!/bin/sh' "printf '%s\\n' \"\$@\" >> '$TMP/curl.args'" 'exit 0' > "$TMP/fake-curl"; chmod +x "$TMP/fake-curl"
printf '%s\n' 'NTFY_ENABLED=1' 'NTFY_URL=http://127.0.0.1:9999/test' 'NTFY_PRIORITY=default' 'NTFY_TAGS=package' > "$TMP/sdd/config.env"
write_cfg() {
  mode=$1; ntfy=$2
  cat "$ROOT/module/config/sortify.conf.default" | sed "s/^SORTIFY_REMOTE_PROTECTED_RELEASE_MODE=.*/SORTIFY_REMOTE_PROTECTED_RELEASE_MODE=$mode/;s/^SORTIFY_NTFY_MODE=.*/SORTIFY_NTFY_MODE=$ntfy/" > "$TMP/sortify.conf"
}
old="$TMP/download/target-pi4__old-test.sh"
printf '%s\n' '#!/bin/sh' 'exit 0' > "$old"
touch -d '20 days ago' "$old"
write_cfg marker_only off
DOWNLOADS="$TMP/download" DEST_BASE="$TMP/sort" MODULE_DIR="$TMP/module" CONF_PATH="$TMP/sortify.conf" SORTIFY_DISPATCHER_RUNTIME_DIR="$TMP/sdd" sh "$ROOT/module/bin/sortify-domain" --sort >/dev/null
[[ -f "$old" ]]
write_cfg marker_or_age all
DOWNLOADS="$TMP/download" DEST_BASE="$TMP/sort" MODULE_DIR="$TMP/module" CONF_PATH="$TMP/sortify.conf" SORTIFY_DISPATCHER_RUNTIME_DIR="$TMP/sdd" SORTIFY_NTFY_FALLBACK_CONFIG="$TMP/sdd/config.env" CURL_BIN="$TMP/fake-curl" sh "$ROOT/module/bin/sortify-domain" --sort >/dev/null
[[ ! -e "$old" ]]
[[ -f "$TMP/sort/Code/target-pi4__old-test.sh" ]]
grep -Fq 'Sortify START' "$TMP/curl.args"
grep -Fq 'Sortify SUCCESS' "$TMP/curl.args"
grep -Fq 'release remote protected artifact file=target-pi4__old-test.sh reason=remote_retention_fallback retention_days=14 age_source=mtime' "$TMP/sort/guard.log"
grep -Fq 'sortify_notify fail' "$ROOT/module/bin/sortify-domain"
echo 'RESULT: SORTIFY_REMOTE_RETENTION_NTFY_PASS'
