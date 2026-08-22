#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CORE="$ROOT/.webui-core"
CORE_COMMIT=6fbd1b018a45fe5b1bebba7aeb9142423eab47fb
CORE_VERSION=0.6.1
MODE=${1:-all}

required=(
  module/module.prop
  module/bin/module-control
  module/bin/module-control-base
  module/bin/sortify-domain
  module/service.sh
  module/customize.sh
  module/uninstall.sh
  module/config/sortify.conf.default
  tools/package-vnext.py
)
for path in "${required[@]}"; do
  [[ -s "$ROOT/$path" ]] || { echo "missing=$path"; exit 1; }
done

sh -n "$ROOT/module/bin/module-control"
sh -n "$ROOT/module/bin/module-control-base"
sh -n "$ROOT/module/bin/sortify-domain"
sh -n "$ROOT/module/service.sh"
sh -n "$ROOT/module/customize.sh"
sh -n "$ROOT/module/uninstall.sh"
python3 -m py_compile "$ROOT/tools/package-vnext.py"

grep -Fxq 'SORTIFY_DISPATCHER_REQUIRED_POLICY=v4115' "$ROOT/module/config/sortify.conf.default"
grep -Fq 'SORTIFY_PREVIEW_MAX_FILES=50' "$ROOT/module/config/sortify.conf.default"
grep -Fq 'SORTIFY_DISPATCHER_REQUIRED_POLICY=v4115' "$ROOT/module/bin/module-control-base"
grep -Fq 'sh "$CONTROL_BASE" config-get' "$ROOT/module/customize.sh"
grep -Fq 'set_perm "$MODPATH/bin/webui-server-arm64" 0 0 0755' "$ROOT/module/customize.sh"

if [[ -d "$CORE/.git" || -f "$CORE/.git" ]]; then
  [[ "$(git -C "$CORE" rev-parse HEAD)" == "$CORE_COMMIT" ]]
  [[ "$(tr -d '\r\n' < "$CORE/CORE_VERSION")" == "$CORE_VERSION" ]]
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/runtime/requests" "$TMP/legacy"
ENV=(MODULE_DIR="$ROOT/module" MODULE_STATE_DIR="$TMP/state" WEBUI_RUNTIME_DIR="$TMP/runtime" SORTIFY_LEGACY_MIRROR="$TMP/legacy/sortify.conf")
env "${ENV[@]}" sh "$ROOT/module/bin/module-control" capabilities > "$TMP/capabilities.json"
env "${ENV[@]}" sh "$ROOT/module/bin/module-control" capabilities-v04 > "$TMP/capabilities-v04.json"
env "${ENV[@]}" sh "$ROOT/module/bin/module-control" config-get > "$TMP/config.json"
env "${ENV[@]}" sh "$ROOT/module/bin/module-control" status > "$TMP/status.json"
python3 -m json.tool "$TMP/capabilities.json" >/dev/null
python3 -m json.tool "$TMP/capabilities-v04.json" >/dev/null
python3 -m json.tool "$TMP/config.json" >/dev/null
python3 -m json.tool "$TMP/status.json" >/dev/null
python3 - "$TMP/capabilities.json" "$TMP/capabilities-v04.json" "$TMP/config.json" "$TMP/status.json" <<'PY'
import json,sys
caps=json.load(open(sys.argv[1])); v04=json.load(open(sys.argv[2])); cfg=json.load(open(sys.argv[3])); status=json.load(open(sys.argv[4]))
assert caps['schema']=='root-module-webui.capabilities.v1'
assert caps['module']['id']=='sortify'
assert any(x['key']=='preview_max_files' for x in caps['config_fields'])
assert v04['schema']=='root-module-webui.extensions.v2'
assert any(x['name']=='cleanup-review-apply' for x in v04['jobs'])
assert cfg['preview_max_files']==50
assert status['safety']['sdd_policy_v4115'] is True
PY
cmp -s "$TMP/state/sortify.conf" "$TMP/legacy/sortify.conf"

# Representative stable/legacy config: preserve existing values while adding
# every vNext-owned field during normalization.
mkdir -p "$TMP/legacy-migration-state" "$TMP/legacy-migration-runtime" "$TMP/legacy-migration-mirror"
cat > "$TMP/legacy-migration-state/sortify.conf" <<'EOF'
INTERVAL=600
GUARD_LOG=1
SORTIFY_NORMAL_SORT=1
SORTIFY_SORT_MODE=manual
SORTIFY_HOLD_PROTECTED=1
SORTIFY_DISPATCHER_INTEGRATION=auto
SORTIFY_CUSTOM_PARK_PREFIXES=heimnetz__
SORTIFY_GUARD_MAX_FILES=450
SORTIFY_GUARD_STATUS_TIMEOUT=10
SORTIFY_DUPLICATE_MODE=filename
SORTIFY_LOG_MAX_KB=2048
SORTIFY_GUARD_TEMP_CLEAN_ON_SORT=1
EOF
LEGACY_ENV=(MODULE_DIR="$ROOT/module" MODULE_STATE_DIR="$TMP/legacy-migration-state" WEBUI_RUNTIME_DIR="$TMP/legacy-migration-runtime" SORTIFY_LEGACY_MIRROR="$TMP/legacy-migration-mirror/sortify.conf")
env "${LEGACY_ENV[@]}" sh "$ROOT/module/bin/module-control" config-get > "$TMP/legacy-migration.json"
grep -Fxq 'INTERVAL=600' "$TMP/legacy-migration-state/sortify.conf"
grep -Fxq 'SORTIFY_SORT_MODE=manual' "$TMP/legacy-migration-state/sortify.conf"
grep -Fxq 'SORTIFY_CUSTOM_PARK_PREFIXES=heimnetz__' "$TMP/legacy-migration-state/sortify.conf"
grep -Fxq 'SORTIFY_PREVIEW_MAX_FILES=50' "$TMP/legacy-migration-state/sortify.conf"
grep -Fxq 'SORTIFY_DISPATCHER_REQUIRED_POLICY=v4115' "$TMP/legacy-migration-state/sortify.conf"
cmp -s "$TMP/legacy-migration-state/sortify.conf" "$TMP/legacy-migration-mirror/sortify.conf"
ls "$TMP/legacy-migration-state/backups"/sortify.conf.pre-normalize.* >/dev/null

cat > "$TMP/runtime/requests/apply.json" <<'JSON'
{"interval":600,"guard_log":true,"normal_sort":true,"sort_mode":"manual","hold_protected":true,"dispatcher_integration":"auto","duplicate_mode":"filename","custom_park_prefixes":"mypark__,heimnetz__","guard_max_files":450,"guard_timeout":10,"log_max_kb":2048,"guard_temp_clean":true,"preview_max_files":75}
JSON
env "${ENV[@]}" sh "$ROOT/module/bin/module-control" config-apply "$TMP/runtime/requests/apply.json" > "$TMP/applied.json"
python3 -m json.tool "$TMP/applied.json" >/dev/null
grep -Fxq 'SORTIFY_SORT_MODE=manual' "$TMP/state/sortify.conf"
grep -Fxq 'SORTIFY_PREVIEW_MAX_FILES=75' "$TMP/state/sortify.conf"
grep -Fxq 'SORTIFY_DISPATCHER_REQUIRED_POLICY=v4115' "$TMP/state/sortify.conf"
cmp -s "$TMP/state/sortify.conf" "$TMP/legacy/sortify.conf"
ls "$TMP/state/backups"/sortify.conf.* >/dev/null

cat > "$TMP/runtime/requests/reject.json" <<'JSON'
{"interval":600,"guard_log":true,"normal_sort":true,"sort_mode":"manual","hold_protected":true,"dispatcher_integration":"auto","duplicate_mode":"filename","custom_park_prefixes":"target-pi3__","guard_max_files":450,"guard_timeout":10,"log_max_kb":2048,"guard_temp_clean":true,"preview_max_files":75}
JSON
if env "${ENV[@]}" sh "$ROOT/module/bin/module-control" config-apply "$TMP/runtime/requests/reject.json" >/dev/null 2>&1; then
  echo 'reserved_prefix_reject=FAIL'
  exit 1
fi

echo 'adapter_json_contract=PASS'
echo 'settings_apply_atomic=PASS'
echo 'settings_backup=PASS'
echo 'rollback_config_mirror=PASS'
echo 'legacy_config_normalization=PASS'
echo 'installer_webui_server_mode=PASS'
echo 'reserved_prefix_reject=PASS'
echo 'sdd_policy_v4115=PASS'
echo 'preview_max_files_surface=PASS'
[[ "$MODE" == --source-only || "$MODE" == all ]] || { echo "invalid_mode=$MODE"; exit 2; }
echo 'RESULT: SORTIFY_VNEXT_SOURCE_VERIFY_DONE outcome=success workflow_exit_code=0'
