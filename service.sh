#!/system/bin/sh
# Sortify v4.0 Service (Native WebUI Version)

MODDIR=${0%/*}
CONF="$MODDIR/sortify.conf"
LOG="$MODDIR/sortify.log"

# 1. Load Defaults if config missing
if [ ! -f "$CONF" ]; then
    {
        echo "INTERVAL=300"
        echo "GUARD_LOG=1"
        echo "SORTIFY_DISPATCHER_INTEGRATION=auto"
        echo "SORTIFY_HOLD_PROTECTED=1"
        echo "SORTIFY_NORMAL_SORT=1"
        echo "SORTIFY_DISPATCHER_RUNTIME_DIR=/data/adb/ssh-drop-dispatcher"
        echo "SORTIFY_DISPATCHER_REQUIRED_POLICY=v4115"
        echo "SORTIFY_DISPATCHER_RELEASE_DIR=/data/adb/ssh-drop-dispatcher/integration/sortify-release"
    } > "$CONF"
fi

# (WebUI is now handled natively by KernelSU via 'webroot' folder. No httpd needed.)

# 2. Wait for Storage
wait_until_storage() {
    until [ -d "/sdcard/Download" ]; do
        sleep 10
    done
}
wait_until_storage

# 3. Main Loop (Backgrounded)
(
    while true; do
        # Re-read config every cycle to get new INTERVAL
        if [ -f "$CONF" ]; then
            . "$CONF"
        fi

        # SORTIFY_SERVICE_CONFIG_SANITIZE_V1_START
        case "${INTERVAL:-300}" in
            ''|*[!0-9]*) INTERVAL=300 ;;
        esac
        [ "$INTERVAL" -lt 30 ] 2>/dev/null && INTERVAL=30
        case "${GUARD_LOG:-1}" in 0|1) ;; *) GUARD_LOG=1 ;; esac
        case "${SORTIFY_DISPATCHER_INTEGRATION:-auto}" in off|auto|on) ;; *) SORTIFY_DISPATCHER_INTEGRATION=auto ;; esac
        case "${SORTIFY_HOLD_PROTECTED:-1}" in 0|1) ;; *) SORTIFY_HOLD_PROTECTED=1 ;; esac
        case "${SORTIFY_NORMAL_SORT:-1}" in 0|1) ;; *) SORTIFY_NORMAL_SORT=1 ;; esac
        SORTIFY_DISPATCHER_RUNTIME_DIR="${SORTIFY_DISPATCHER_RUNTIME_DIR:-/data/adb/ssh-drop-dispatcher}"
        SORTIFY_DISPATCHER_REQUIRED_POLICY="${SORTIFY_DISPATCHER_REQUIRED_POLICY:-v4115}"
        SORTIFY_DISPATCHER_RELEASE_DIR="${SORTIFY_DISPATCHER_RELEASE_DIR:-$SORTIFY_DISPATCHER_RUNTIME_DIR/integration/sortify-release}"
        export INTERVAL GUARD_LOG SORTIFY_DISPATCHER_INTEGRATION SORTIFY_HOLD_PROTECTED SORTIFY_NORMAL_SORT SORTIFY_DISPATCHER_RUNTIME_DIR SORTIFY_DISPATCHER_REQUIRED_POLICY SORTIFY_DISPATCHER_RELEASE_DIR
        # SORTIFY_SERVICE_CONFIG_SANITIZE_V1_END

        # Run the action script
        # We redirect stdout/stderr to log to capture any 'echo' from action.sh
        sh "$MODDIR/action.sh" >> "$LOG" 2>&1
        
        # Log the service heartbeat
        echo "[Service] $(date '+%Y-%m-%d %H:%M:%S') - Cycle complete. Sleeping ${INTERVAL}s" >> "$LOG"
        
        # Prune log (Keep last 200 lines)
        tail -n 200 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
        
        sleep "${INTERVAL:-300}"
    done
) &  # <--- CRITICAL: Run entire loop in background
