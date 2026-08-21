#!/system/bin/sh
set -u

BASE=/sdcard/Sortify
STATE_DIR=/data/adb/sortify
RUNTIME_DIR=/data/local/tmp/sortify-webui
PID_FILE=$RUNTIME_DIR/server.pid
MODDIR=${0%/*}
SERVER=$MODDIR/bin/webui-server-arm64

mkdir -p "$BASE" 2>/dev/null || true
printf '[Uninstall] %s - Sortify module removal initiated; user data and persistent config are preserved.\n' "$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo now)" >> "$BASE/sortify.log" 2>/dev/null || true

if [ -f "$PID_FILE" ]; then
  pid=$(cat "$PID_FILE" 2>/dev/null || true)
  case "$pid" in
    ""|*[!0-9]*) ;;
    *)
      if [ -r "/proc/$pid/cmdline" ] && tr '\000' ' ' < "/proc/$pid/cmdline" 2>/dev/null | grep -Fq "$SERVER"; then
        kill "$pid" 2>/dev/null || true
      fi
      ;;
  esac
fi
rm -rf "$RUNTIME_DIR" 2>/dev/null || true
chmod 0700 "$STATE_DIR" 2>/dev/null || true
printf '[Uninstall] Sortify persistent config preserved at %s.\n' "$STATE_DIR" >> "$BASE/sortify.log" 2>/dev/null || true
exit 0
