#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

VERSION=$(sed -n 's/^version=//p' "$ROOT/module/module.prop" | head -n1)
[[ -n "$VERSION" ]]

mkdir -p "$TMP/state" "$TMP/runtime/requests" "$TMP/legacy" "$TMP/downloads" "$TMP/dest" "$TMP/fakebin"
ENV=(
  MODULE_DIR="$ROOT/module"
  MODULE_STATE_DIR="$TMP/state"
  WEBUI_RUNTIME_DIR="$TMP/runtime"
  SORTIFY_LEGACY_MIRROR="$TMP/legacy/sortify.conf"
  DOWNLOADS="$TMP/downloads"
  DEST_BASE="$TMP/dest"
)

cat > "$TMP/runtime/requests/preview.json" <<'JSON'
{"dry_run":true}
JSON

env "${ENV[@]}" sh "$ROOT/module/bin/module-control" action-file sort-now "$TMP/runtime/requests/preview.json" > "$TMP/preview.json"
python3 -m json.tool "$TMP/preview.json" >/dev/null
python3 - "$TMP/preview.json" "$VERSION" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1], encoding='utf-8'))
version = sys.argv[2]
assert payload['ok'] is True, payload
message = payload.get('message', '')
assert f'version={version}' in message, message
assert 'version=4.7.1-webui-cleanup-hotfix' not in message, message
PY
echo 'webui_action_version_identity=PASS'

cat > "$TMP/fakebin/timeout" <<'SH'
#!/bin/sh
exit 124
SH
chmod +x "$TMP/fakebin/timeout"
cat > "$TMP/runtime/requests/guard.json" <<'JSON'
{"dry_run":false}
JSON

PATH="$TMP/fakebin:$PATH" env "${ENV[@]}" sh "$ROOT/module/bin/module-control" action-file guard-status "$TMP/runtime/requests/guard.json" > "$TMP/guard.json"
python3 -m json.tool "$TMP/guard.json" >/dev/null
python3 - "$TMP/guard.json" <<'PY'
import json, sys
payload = json.load(open(sys.argv[1], encoding='utf-8'))
assert payload['action'] == 'guard-status', payload
assert payload['ok'] is False, payload
assert 'guard_status=timeout' in payload.get('message', ''), payload
PY
echo 'guard_status_timeout_transport=PASS'

grep -Fq 'guard-status' "$ROOT/module/bin/module-control"
grep -Fq 'generic "module backend failed" error' "$ROOT/module/bin/module-control"
echo 'RESULT: SORTIFY_WEBUI_ACTIONS_HOTFIX_SOURCE_VERIFY_DONE outcome=success workflow_exit_code=0'
