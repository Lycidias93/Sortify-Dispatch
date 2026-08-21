#!/system/bin/sh
set -u

MODDIR=${0%/*}
STATE_DIR=/data/adb/sortify
CONFIG_FILE=$STATE_DIR/sortify.conf
DEFAULT_CONFIG=$MODDIR/config/sortify.conf.default
DOMAIN=$MODDIR/bin/sortify-domain

mkdir -p "$STATE_DIR" >/dev/null 2>&1 || exit 1
chmod 0700 "$STATE_DIR" >/dev/null 2>&1 || true
if [ ! -f "$CONFIG_FILE" ] && [ -f "$DEFAULT_CONFIG" ]; then
  tmp="$CONFIG_FILE.tmp.$$"
  cp -f "$DEFAULT_CONFIG" "$tmp" || exit 1
  chmod 0600 "$tmp" >/dev/null 2>&1 || true
  mv -f "$tmp" "$CONFIG_FILE" || exit 1
fi

wait_boot() {
  count=0
  while [ "$count" -lt 120 ]; do
    [ "$(getprop sys.boot_completed 2>/dev/null)" = "1" ] && return 0
    count=$((count + 1))
    sleep 2
  done
  return 0
}

interval_seconds() {
  value=$(sed -n 's/^INTERVAL=//p' "$CONFIG_FILE" 2>/dev/null | tail -n 1)
  case "$value" in ""|*[!0-9]*) value=300 ;; esac
  [ "$value" -ge 30 ] 2>/dev/null || value=300
  [ "$value" -le 86400 ] 2>/dev/null || value=86400
  printf '%s' "$value"
}

wait_boot
while true; do
  if [ -x "$DOMAIN" ]; then
    MODULE_DIR="$MODDIR" CONF_PATH="$CONFIG_FILE" sh "$DOMAIN" --service-cycle >/dev/null 2>&1 || true
  fi
  sleep "$(interval_seconds)"
done
