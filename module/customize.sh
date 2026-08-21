#!/system/bin/sh

STATE_DIR=/data/adb/sortify
PERSISTENT_CONFIG=$STATE_DIR/sortify.conf
LEGACY_CONFIG=/data/adb/modules/sortify/sortify.conf
DEFAULT_CONFIG=$MODPATH/config/sortify.conf.default
LEGACY_MIRROR=$MODPATH/sortify.conf

ui_print "- Preparing persistent Sortify state..."
mkdir -p "$STATE_DIR" "$STATE_DIR/backups" || abort "Failed to create Sortify state directory"
chmod 0700 "$STATE_DIR" "$STATE_DIR/backups" 2>/dev/null || true

if [ ! -f "$PERSISTENT_CONFIG" ]; then
  if [ -f "$LEGACY_CONFIG" ] && [ "$LEGACY_CONFIG" != "$PERSISTENT_CONFIG" ]; then
    cp -f "$LEGACY_CONFIG" "$PERSISTENT_CONFIG" || abort "Failed to preserve existing Sortify config"
    ui_print "- Preserved existing Sortify config into persistent state"
  elif [ -f "$DEFAULT_CONFIG" ]; then
    cp -f "$DEFAULT_CONFIG" "$PERSISTENT_CONFIG" || abort "Failed to install default Sortify config"
    ui_print "- Installed default Sortify config"
  else
    abort "Sortify default config is missing"
  fi
fi
chmod 0600 "$PERSISTENT_CONFIG" 2>/dev/null || true

cp -f "$PERSISTENT_CONFIG" "$LEGACY_MIRROR" || abort "Failed to create rollback-compatible Sortify config mirror"
chmod 0600 "$LEGACY_MIRROR" 2>/dev/null || true

ui_print "- Setting module permissions..."
set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/action.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/bin/module-control" 0 0 0755
set_perm "$MODPATH/bin/module-control-base" 0 0 0755
set_perm "$MODPATH/bin/sortify-domain" 0 0 0755
[ -f "$MODPATH/uninstall.sh" ] && set_perm "$MODPATH/uninstall.sh" 0 0 0755
[ -f "$MODPATH/tools/sortify-download-cleanup.sh" ] && set_perm "$MODPATH/tools/sortify-download-cleanup.sh" 0 0 0755
[ -f "$MODPATH/config/sortify.conf.default" ] && set_perm "$MODPATH/config/sortify.conf.default" 0 0 0644
[ -f "$LEGACY_MIRROR" ] && set_perm "$LEGACY_MIRROR" 0 0 0600

ui_print "✔ Sortify persistent state and rollback-compatible mirror ready"
