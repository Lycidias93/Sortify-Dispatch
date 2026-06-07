#!/system/bin/sh
# Sortify v4.0 by xCaptaiN09

BASE="/sdcard/Sortify"

# SORTIFY_CONFIG_PRESERVE_V1_START
preserve_existing_config() {
    active_conf="/data/adb/modules/sortify/sortify.conf"
    new_conf="$MODPATH/sortify.conf"

    [ -f "$new_conf" ] || return 0
    [ -f "$active_conf" ] || return 0
    [ "$active_conf" = "$new_conf" ] && return 0

    ui_print "- Preserving existing Sortify config..."

    for key in         INTERVAL         GUARD_LOG         SORTIFY_NORMAL_SORT         SORTIFY_HOLD_PROTECTED         SORTIFY_DISPATCHER_INTEGRATION         SORTIFY_CUSTOM_PARK_PREFIXES         SORTIFY_GUARD_MAX_FILES         SORTIFY_GUARD_STATUS_TIMEOUT         SORTIFY_DUPLICATE_MODE         SORTIFY_LOG_MAX_KB         SORTIFY_GUARD_TEMP_CLEAN_ON_SORT; do

        line="$(grep -E "^${key}=" "$active_conf" 2>/dev/null | tail -n 1 || true)"
        [ -n "$line" ] || continue

        tmp="$new_conf.tmp.$$"
        grep -v -E "^${key}=" "$new_conf" > "$tmp" 2>/dev/null || true
        printf '%s
' "$line" >> "$tmp"
        mv -f "$tmp" "$new_conf"
    done

    ui_print "✔ Existing Sortify config preserved"
}
# SORTIFY_CONFIG_PRESERVE_V1_END


# 1. Create User Directories
ui_print "- Creating folder structure..."
mkdir -p "$BASE/Documents"
mkdir -p "$BASE/Images"
mkdir -p "$BASE/Videos"
mkdir -p "$BASE/Audio"
mkdir -p "$BASE/Archives"
mkdir -p "$BASE/Apps"
mkdir -p "$BASE/Others"
mkdir -p "$BASE/Duplicates"   

ui_print "✔ Sortify folders ready at $BASE"

preserve_existing_config

# 2. Set Module Permissions
ui_print "- Setting permissions..."

# A. Default Rule: Set ALL folders to 755 and ALL files to 644
# This automatically handles 'webroot/index.html' correctly (0644)
set_perm_recursive "$MODPATH" 0 0 0755 0644

# B. Override Scripts: Make them executable (755)
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/action.sh" 0 0 0755
if [ -f "$MODPATH/uninstall.sh" ]; then
    if [ -f "$MODPATH/uninstall.sh" ]; then
    set_perm "$MODPATH/uninstall.sh" 0 0 0755
fi
fi

# C. Config File: Ensure writable
if [ -f "$MODPATH/sortify.conf" ]; then
    set_perm "$MODPATH/sortify.conf" 0 0 0644
fi

ui_print "✔ Permissions applied"
