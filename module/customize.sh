#!/system/bin/sh

STATE_DIR=/data/adb/sortify
PERSISTENT_CONFIG=$STATE_DIR/sortify.conf
LEGACY_CONFIG=/data/adb/modules/sortify/sortify.conf
DEFAULT_CONFIG=$MODPATH/config/sortify.conf.default
LEGACY_MIRROR=$MODPATH/sortify.conf
CONTROL_BASE=$MODPATH/bin/module-control-base
MODULE_PROP=$MODPATH/module.prop

value_from_file() {
  key="$1"
  file="$2"
  sed -n "s/^${key}=//p" "$file" 2>/dev/null | sed -n '1p'
}

INSTALL_VERSION="$(value_from_file version "$MODULE_PROP")"
INSTALL_VERSION_CODE="$(value_from_file versionCode "$MODULE_PROP")"
DEFAULT_POLICY="$(value_from_file SORTIFY_DISPATCHER_REQUIRED_POLICY "$DEFAULT_CONFIG")"
[ -n "$INSTALL_VERSION" ] || INSTALL_VERSION=unknown
[ -n "$INSTALL_VERSION_CODE" ] || INSTALL_VERSION_CODE=unknown
[ -n "$DEFAULT_POLICY" ] || DEFAULT_POLICY=unknown

ui_print "- Sortify install identity: version=$INSTALL_VERSION versionCode=$INSTALL_VERSION_CODE"
ui_print "- Packaged dispatcher policy: $DEFAULT_POLICY"
ui_print "- Preparing persistent Sortify state..."
mkdir -p "$STATE_DIR" "$STATE_DIR/backups" || abort "Failed to create Sortify state directory"
chmod 0700 "$STATE_DIR" "$STATE_DIR/backups" 2>/dev/null || true

CONFIG_SOURCE=existing_persistent
if [ ! -f "$PERSISTENT_CONFIG" ]; then
  if [ -f "$LEGACY_CONFIG" ] && [ "$LEGACY_CONFIG" != "$PERSISTENT_CONFIG" ]; then
    cp -f "$LEGACY_CONFIG" "$PERSISTENT_CONFIG" || abort "Failed to preserve existing Sortify config"
    CONFIG_SOURCE=legacy_module
    ui_print "- Config migration: preserved previous module config"
  elif [ -f "$DEFAULT_CONFIG" ]; then
    cp -f "$DEFAULT_CONFIG" "$PERSISTENT_CONFIG" || abort "Failed to install default Sortify config"
    CONFIG_SOURCE=packaged_default
    ui_print "- Config migration: installed packaged defaults"
  else
    abort "Sortify default config is missing"
  fi
else
  ui_print "- Config migration: existing persistent config retained"
fi
chmod 0600 "$PERSISTENT_CONFIG" 2>/dev/null || true
ui_print "- Persistent config: source=$CONFIG_SOURCE path=$PERSISTENT_CONFIG mode=0600"

SCHEMA_BEFORE=legacy
if grep -Fxq "SORTIFY_DISPATCHER_REQUIRED_POLICY=$DEFAULT_POLICY" "$PERSISTENT_CONFIG" 2>/dev/null &&
   grep -Eq '^SORTIFY_PREVIEW_MAX_FILES=[0-9]+$' "$PERSISTENT_CONFIG" 2>/dev/null; then
  SCHEMA_BEFORE=vnext
fi
ui_print "- Config schema before normalization: $SCHEMA_BEFORE"

# Normalize legacy/stable configs immediately during install so the persistent
# state is complete before first WebUI/action use. module-control-base preserves
# known legacy values, fills vNext defaults and writes a rollback backup when it
# changes the file.
[ -f "$CONTROL_BASE" ] || abort "Sortify config normalizer is missing"
MODULE_STATE_DIR="$STATE_DIR" SORTIFY_CONFIG_FILE="$PERSISTENT_CONFIG" \
  sh "$CONTROL_BASE" config-get >/dev/null 2>&1 || abort "Failed to normalize persistent Sortify config"

SORT_MODE="$(value_from_file SORTIFY_SORT_MODE "$PERSISTENT_CONFIG")"
PREVIEW_MAX="$(value_from_file SORTIFY_PREVIEW_MAX_FILES "$PERSISTENT_CONFIG")"
PERSISTENT_POLICY="$(value_from_file SORTIFY_DISPATCHER_REQUIRED_POLICY "$PERSISTENT_CONFIG")"
[ -n "$SORT_MODE" ] || SORT_MODE=unknown
[ -n "$PREVIEW_MAX" ] || PREVIEW_MAX=unknown
[ -n "$PERSISTENT_POLICY" ] || PERSISTENT_POLICY=unknown
[ "$PERSISTENT_POLICY" = "$DEFAULT_POLICY" ] || abort "Normalized dispatcher policy does not match packaged policy"
case "$PREVIEW_MAX" in ""|*[!0-9]*) abort "Normalized preview limit is invalid";; esac
ui_print "- Config normalization: schema=vnext sort_mode=$SORT_MODE preview_max_files=$PREVIEW_MAX policy=$PERSISTENT_POLICY"
[ "$SCHEMA_BEFORE" = "vnext" ] || ui_print "- Config rollback: pre-normalization backup created under $STATE_DIR/backups when content changed"

cp -f "$PERSISTENT_CONFIG" "$LEGACY_MIRROR" || abort "Failed to create rollback-compatible Sortify config mirror"
chmod 0600 "$LEGACY_MIRROR" 2>/dev/null || true
cmp -s "$PERSISTENT_CONFIG" "$LEGACY_MIRROR" 2>/dev/null || abort "Sortify config mirror verification failed"
ui_print "- Config mirror: byte_equal=yes path=$LEGACY_MIRROR mode=0600"

ui_print "- Setting module permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/bin/module-control" 0 0 0755
set_perm "$MODPATH/bin/module-control-base" 0 0 0755
set_perm "$MODPATH/bin/sortify-domain" 0 0 0755
set_perm "$MODPATH/bin/webui-server-arm64" 0 0 0755
[ -f "$MODPATH/uninstall.sh" ] && set_perm "$MODPATH/uninstall.sh" 0 0 0755
[ -f "$MODPATH/tools/sortify-download-cleanup.sh" ] && set_perm "$MODPATH/tools/sortify-download-cleanup.sh" 0 0 0755
[ -f "$MODPATH/config/sortify.conf.default" ] && set_perm "$MODPATH/config/sortify.conf.default" 0 0 0644
[ -f "$LEGACY_MIRROR" ] && set_perm "$LEGACY_MIRROR" 0 0 0600

[ -x "$MODPATH/bin/webui-server-arm64" ] || abort "Sortify WebUI server is not executable after permission setup"
WEBUI_MODE="$(stat -c '%a' "$MODPATH/bin/webui-server-arm64" 2>/dev/null || true)"
[ -n "$WEBUI_MODE" ] || WEBUI_MODE=executable
ui_print "- WebUI server: executable=yes mode=$WEBUI_MODE"
ui_print "- Install summary: state=ready config=vnext mirror=verified webui=ready policy=$PERSISTENT_POLICY"
ui_print "✔ Sortify persistent state and rollback-compatible mirror ready"
