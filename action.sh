#!/system/bin/sh
# Sortify Dispatch v4.1-guard-tools - Manual Action / Guard Tools

ui_print() {
    echo "$1"
}

DOWNLOADS="${DOWNLOADS:-/sdcard/Download}"
DEST_BASE="${DEST_BASE:-/sdcard/Sortify}"
MODULE_DIR="${MODULE_DIR:-/data/adb/modules/sortify}"
CONF_PATH="${CONF_PATH:-$MODULE_DIR/sortify.conf}"
GUARD_LOG="${GUARD_LOG:-1}"
SORTIFY_DISPATCHER_INTEGRATION="${SORTIFY_DISPATCHER_INTEGRATION:-auto}"
SORTIFY_HOLD_PROTECTED="${SORTIFY_HOLD_PROTECTED:-1}"
SORTIFY_NORMAL_SORT="${SORTIFY_NORMAL_SORT:-1}"
PIDD_RUNTIME_DIR="${PIDD_RUNTIME_DIR:-/data/adb/pixel-drop-dispatch}"
PIDD_SORTIFY_REQUIRED_POLICY="${PIDD_SORTIFY_REQUIRED_POLICY:-v4115}"
PIDD_SORTIFY_RELEASE_DIR="${PIDD_SORTIFY_RELEASE_DIR:-$PIDD_RUNTIME_DIR/integration/sortify-release}"

if [ -f "$CONF_PATH" ]; then
    # shellcheck disable=SC1090
    . "$CONF_PATH" 2>/dev/null || true
fi

# SORTIFY_OPTIONAL_DISPATCHER_CONFIG_V1_START
normalize_config() {
    case "${SORTIFY_DISPATCHER_INTEGRATION:-auto}" in
        off|auto|on) ;;
        *) SORTIFY_DISPATCHER_INTEGRATION="auto" ;;
    esac

    case "${SORTIFY_HOLD_PROTECTED:-1}" in
        0|1) ;;
        *) SORTIFY_HOLD_PROTECTED="1" ;;
    esac

    case "${SORTIFY_NORMAL_SORT:-1}" in
        0|1) ;;
        *) SORTIFY_NORMAL_SORT="1" ;;
    esac

    PIDD_RUNTIME_DIR="${PIDD_RUNTIME_DIR:-/data/adb/pixel-drop-dispatch}"
    PIDD_SORTIFY_REQUIRED_POLICY="${PIDD_SORTIFY_REQUIRED_POLICY:-v4115}"
    PIDD_SORTIFY_RELEASE_DIR="${PIDD_SORTIFY_RELEASE_DIR:-$PIDD_RUNTIME_DIR/integration/sortify-release}"
}


normalize_config
# SORTIFY_OPTIONAL_DISPATCHER_CONFIG_V1_END

ensure_dirs() {
    mkdir -p "$DEST_BASE/Documents" \
             "$DEST_BASE/Images" \
             "$DEST_BASE/Videos" \
             "$DEST_BASE/Audio" \
             "$DEST_BASE/Archives" \
             "$DEST_BASE/Apps" \
             "$DEST_BASE/Others" \
             "$DEST_BASE/Duplicates" \
             "$DEST_BASE/GuardConflicts"
}

log_guard() {
    [ "${GUARD_LOG:-1}" = "1" ] || return 0
    ensure_dirs
    echo "[Guard] $(date '+%Y-%m-%d %H:%M:%S') $*" >> "$DEST_BASE/guard.log"
}


# SORTIFY_PIDD_V4110_CONTRACT_V1_START
dispatcher_health_ok() {
    runtime="${PIDD_RUNTIME_DIR:-/data/adb/pixel-drop-dispatch}"
    health="$runtime/health.env"
    [ -d "$runtime" ] || return 1
    [ -f "$health" ] || return 1
    (
        . "$health" 2>/dev/null || exit 1
        [ "${status:-}" = "OK" ] || exit 1
        [ "${inflight_bytes:-0}" = "0" ] || exit 1
    ) >/dev/null 2>&1
}

dispatcher_marker_dir_ok() {
    normalize_config
    [ -d "$PIDD_SORTIFY_RELEASE_DIR" ] || return 1
    [ -r "$PIDD_SORTIFY_RELEASE_DIR" ] || return 1
}

dispatcher_contract_ok() {
    dispatcher_health_ok || return 1
    dispatcher_marker_dir_ok || return 1
}

dispatcher_integration_state() {
    normalize_config
    case "$SORTIFY_DISPATCHER_INTEGRATION" in
        off)
            echo "disabled"
            ;;
        on)
            if dispatcher_contract_ok; then
                echo "active"
            else
                echo "required_missing"
            fi
            ;;
        auto|*)
            if dispatcher_contract_ok; then
                echo "active"
            else
                echo "auto_inactive"
            fi
            ;;
    esac
}

dispatcher_integration_active() {
    [ "$(dispatcher_integration_state)" = "active" ]
}

require_dispatcher_if_needed() {
    normalize_config
    if [ "$SORTIFY_DISPATCHER_INTEGRATION" = "on" ] && ! dispatcher_contract_ok; then
        ui_print "ERROR: dispatcher integration required but Pixel Drop Dispatcher runtime/marker directory is not healthy"
        log_guard "dispatcher required but missing_or_unhealthy runtime=${PIDD_RUNTIME_DIR:-/data/adb/pixel-drop-dispatch} release_dir=${PIDD_SORTIFY_RELEASE_DIR:-}"
        return 3
    fi
    return 0
}

file_sha256() {
    file="$1"
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$file" 2>/dev/null | while read -r h rest; do printf '%s' "$h"; done
        return 0
    fi
    if command -v toybox >/dev/null 2>&1 && toybox --list 2>/dev/null | grep -qx sha256sum; then
        toybox sha256sum "$file" 2>/dev/null | while read -r h rest; do printf '%s' "$h"; done
        return 0
    fi
    return 1
}

file_size_bytes() {
    wc -c < "$1" 2>/dev/null | tr -d ' ' 2>/dev/null
}

marker_field() {
    marker="$1"
    key="$2"
    sed -n "s/^${key}=//p" "$marker" 2>/dev/null | sed -n '1p'
}

marker_unquote() {
    v="$1"
    case "$v" in
        "''") v="" ;;
        \'*\') v=${v#\'}; v=${v%\'} ;;
    esac
    printf '%s' "$v"
}

marker_pending_empty() {
    pending="$(marker_unquote "$1")"
    [ -z "$pending" ]
}

pidd_sortify_marker_path() {
    file="$1"
    sha="$(file_sha256 "$file" 2>/dev/null || true)"
    [ -n "$sha" ] || return 1
    printf '%s/%s.env' "$PIDD_SORTIFY_RELEASE_DIR" "$sha"
}

pidd_sortify_contract_released() {
    normalize_config
    file="$1"
    [ -f "$file" ] || return 1
    sha="$(file_sha256 "$file" 2>/dev/null || true)"
    size="$(file_size_bytes "$file" 2>/dev/null || true)"
    [ -n "$sha" ] || return 1
    [ -n "$size" ] || return 1
    marker="$PIDD_SORTIFY_RELEASE_DIR/$sha.env"
    [ -f "$marker" ] || return 1

    released="$(marker_field "$marker" released)"
    authority="$(marker_field "$marker" authority)"
    marker_sha="$(marker_field "$marker" sha256)"
    marker_size="$(marker_field "$marker" size)"
    policy="$(marker_field "$marker" policy)"
    pending="$(marker_field "$marker" pending_targets)"

    [ "$released" = "yes" ] || return 1
    [ "$authority" = "dispatcher" ] || return 1
    [ "$marker_sha" = "$sha" ] || return 1
    [ "$marker_size" = "$size" ] || return 1
    [ "$policy" = "$PIDD_SORTIFY_REQUIRED_POLICY" ] || return 1
    marker_pending_empty "$pending" || return 1
    return 0
}

pidd_sortify_contract_status() {
    normalize_config
    file="$1"
    [ -f "$file" ] || { echo "missing_local_file"; return 0; }
    sha="$(file_sha256 "$file" 2>/dev/null || true)"
    size="$(file_size_bytes "$file" 2>/dev/null || true)"
    if [ -z "$sha" ]; then
        echo "held:no_sha"
        return 0
    fi
    marker="$PIDD_SORTIFY_RELEASE_DIR/$sha.env"
    if [ ! -f "$marker" ]; then
        echo "held:marker_missing"
        return 0
    fi
    released="$(marker_field "$marker" released)"
    authority="$(marker_field "$marker" authority)"
    marker_sha="$(marker_field "$marker" sha256)"
    marker_size="$(marker_field "$marker" size)"
    policy="$(marker_field "$marker" policy)"
    pending="$(marker_unquote "$(marker_field "$marker" pending_targets)")"
    reason="$(marker_unquote "$(marker_field "$marker" reason)")"

    if pidd_sortify_contract_released "$file"; then
        echo "released:policy=$policy reason=$reason"
        return 0
    fi
    if [ "$released" = "no" ]; then
        echo "held:released_no policy=$policy pending=$pending reason=$reason"
    elif [ "$policy" != "$PIDD_SORTIFY_REQUIRED_POLICY" ]; then
        echo "held:policy_mismatch got=$policy required=$PIDD_SORTIFY_REQUIRED_POLICY"
    elif [ "$authority" != "dispatcher" ]; then
        echo "held:authority_mismatch got=$authority"
    elif [ "$marker_sha" != "$sha" ] || [ "$marker_size" != "$size" ]; then
        echo "held:sha_or_size_mismatch"
    elif [ -n "$pending" ]; then
        echo "held:pending_targets=$pending"
    else
        echo "held:not_released released=$released policy=$policy"
    fi
}

should_hold_protected_artifact() {
    name="$1"
    [ "${SORTIFY_HOLD_PROTECTED:-1}" = "1" ] || return 1
    is_protected_artifact "$name" || return 1

    state="$(dispatcher_integration_state)"
    case "$state" in
        disabled|auto_inactive)
            return 1
            ;;
        required_missing)
            return 0
            ;;
        active)
            ;;
        *)
            return 0
            ;;
    esac

    file="${DOWNLOADS:-/storage/emulated/0/Download}/$name"
    if pidd_sortify_contract_released "$file"; then
        log_guard "release protected artifact file=$name contract=$(pidd_sortify_contract_status "$file")"
        return 1
    fi

    log_guard "hold protected artifact file=$name integration=$state contract=$(pidd_sortify_contract_status "$file")"
    return 0
}
# SORTIFY_PIDD_V4110_CONTRACT_V1_END

DOC_EXT="pdf doc docx txt xls xlsx ppt pptx csv md log json yaml yml xml"
IMG_EXT="jpg jpeg png gif bmp webp heic heif svg"
VID_EXT="mp4 mkv avi mov webm flv mpeg mpg 3gp"
AUD_EXT="mp3 m4a flac wav ogg opus aac wma"
ARC_EXT="zip rar 7z tar gz bz2 xz tgz txz tbz tbz2 iso"
APP_EXT="apk exe apks apkm xapk"

is_protected_artifact() {
    name="$1"
    lower="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"

    case "$lower" in
        target-pi3__*|target-pi4__*|target-zeropi2__*|target-berylax__*|targets-*__*)
            return 0
            ;;
        pi3_*|pi4_*|zeropi2_*|berylax_*)
            return 0
            ;;
        pixel_local__*|pixel-termux*|pixel_termux*|termux-*|termux_*)
            return 0
            ;;
        pixel-drop-dispatch*|pixel_drop_dispatch*|ssh-drop-dispatcher*|ssh_drop_dispatcher*)
            return 0
            ;;
        sortify-dispatch*|sortify_dispatch*)
            return 0
            ;;
        *drop-dispatch*|*drop_dispatch*)
            return 0
            ;;
        repo_*.py|*_repo_*.py|repo_*.sh|*_repo_*.sh)
            return 0
            ;;
    esac

    return 1
}

is_skip_candidate() {
    name="$1"
    case "$name" in
        .*|*.crdownload|*.partial|*.tmp)
            return 0
            ;;
    esac
    return 1
}

move_one() {
    dest="$1"
    file="$2"
    filename="$(basename "$file")"

    if is_skip_candidate "$filename"; then
        return 0
    fi

    if should_hold_protected_artifact "$filename"; then
        ui_print "KEEP artifact: $filename"
        log_guard "keep download=$DOWNLOADS file=$filename integration=$(dispatcher_integration_state)"
        return 0
    fi

    if is_protected_artifact "$filename"; then
        log_guard "protected artifact eligible to sort file=$filename hold=${SORTIFY_HOLD_PROTECTED:-1} integration=$(dispatcher_integration_state)"
    fi

    if [ -e "$dest/$filename" ]; then
        mv -f "$file" "$DEST_BASE/Duplicates/"
    else
        mv -f "$file" "$dest/"
    fi
}

move_files() {
    dest="$1"
    shift
    for ext in "$@"; do
        find "$DOWNLOADS" -maxdepth 1 -type f \
            ! -name ".*" \
            ! -name "*.crdownload" \
            ! -name "*.partial" \
            ! -name "*.tmp" \
            -iname "*.$ext" -print | while IFS= read -r file; do
                move_one "$dest" "$file"
            done
    done
}

find_protected_under() {
    dir="$1"
    [ -d "$dir" ] || return 0
    find "$dir" -maxdepth 1 -type f -print | while IFS= read -r file; do
        name="$(basename "$file")"
        if is_protected_artifact "$name"; then
            printf '%s\n' "$file"
        fi
    done
}

find_misplaced_protected() {
    for dir in \
        "$DEST_BASE/Documents" \
        "$DEST_BASE/Images" \
        "$DEST_BASE/Videos" \
        "$DEST_BASE/Audio" \
        "$DEST_BASE/Archives" \
        "$DEST_BASE/Apps" \
        "$DEST_BASE/Others" \
        "$DEST_BASE/Duplicates"; do
        find_protected_under "$dir"
    done
}

count_lines() {
    wc -l | tr -d ' '
}

guard_status() {
    ensure_dirs
    tmp_misplaced="$DEST_BASE/.guard_misplaced.$$"
    tmp_download="$DEST_BASE/.guard_download.$$"
    tmp_conflicts="$DEST_BASE/.guard_conflicts.$$"
    : > "$tmp_misplaced"
    : > "$tmp_download"
    : > "$tmp_conflicts"

    find_protected_under "$DOWNLOADS" > "$tmp_download" || true
    find_misplaced_protected > "$tmp_misplaced" || true
    find_protected_under "$DEST_BASE/GuardConflicts" > "$tmp_conflicts" || true

    download_count="$(count_lines < "$tmp_download")"
    misplaced_count="$(count_lines < "$tmp_misplaced")"
    conflict_count="$(count_lines < "$tmp_conflicts")"

    echo "== Sortify Dispatch Guard Status =="
    echo "version=4.1-guard-tools"
    echo "download=$DOWNLOADS"
    echo "dest_base=$DEST_BASE"
    echo "protected_in_download=$download_count"
    echo "protected_misplaced=$misplaced_count"
    echo "protected_conflicts=$conflict_count"

    if [ "$misplaced_count" = "0" ]; then
        echo "guard_status=pass"
    else
        echo "guard_status=needs_clean"
        echo "-- misplaced --"
        cat "$tmp_misplaced"
    fi

    rm -f "$tmp_misplaced" "$tmp_download" "$tmp_conflicts"
}

guard_clean() {
    ensure_dirs
    stamp="$(date '+%Y%m%d_%H%M%S')"
    conflict_dir="$DEST_BASE/GuardConflicts/$stamp"
    tmp_misplaced="$DEST_BASE/.guard_clean.$$"
    : > "$tmp_misplaced"
    find_misplaced_protected > "$tmp_misplaced" || true

    total=0
    restored=0
    conflicts=0

    while IFS= read -r file; do
        [ -n "$file" ] || continue
        [ -f "$file" ] || continue
        total=$((total + 1))
        name="$(basename "$file")"
        target="$DOWNLOADS/$name"
        if [ -e "$target" ]; then
            mkdir -p "$conflict_dir"
            mv -f "$file" "$conflict_dir/$name"
            conflicts=$((conflicts + 1))
            log_guard "clean conflict source=$file target=$target conflict_dir=$conflict_dir"
        else
            mv -f "$file" "$target"
            restored=$((restored + 1))
            log_guard "clean restored source=$file target=$target"
        fi
    done < "$tmp_misplaced"

    rm -f "$tmp_misplaced"

    echo "== Sortify Dispatch Guard Clean =="
    echo "total_misplaced=$total"
    echo "restored_to_download=$restored"
    echo "moved_to_guard_conflicts=$conflicts"
    if [ "$conflicts" -gt 0 ]; then
        echo "conflict_dir=$conflict_dir"
    fi
    echo "guard_clean=done"
}

sortify_config_status() {
    normalize_config
    echo "== Sortify Dispatch Config =="
    echo "download=$DOWNLOADS"
    echo "dest_base=$DEST_BASE"
    echo "conf_path=$CONF_PATH"
    echo "guard_log=${GUARD_LOG:-1}"
    echo "sortify_normal_sort=$SORTIFY_NORMAL_SORT"
    echo "sortify_hold_protected=$SORTIFY_HOLD_PROTECTED"
    echo "sortify_dispatcher_integration=$SORTIFY_DISPATCHER_INTEGRATION"
    echo "pidd_runtime_dir=$PIDD_RUNTIME_DIR"
    echo "pidd_sortify_release_dir=$PIDD_SORTIFY_RELEASE_DIR"
    echo "pidd_sortify_required_policy=$PIDD_SORTIFY_REQUIRED_POLICY"
    echo "sortify_contract=policy_v4115_sha_size_authority_pending"
    echo "dispatcher_integration_state=$(dispatcher_integration_state)"
    echo "pidd_sortify_release_dir=$PIDD_SORTIFY_RELEASE_DIR"
    echo "pidd_sortify_required_policy=$PIDD_SORTIFY_REQUIRED_POLICY"
}

dispatcher_status() {
    normalize_config
    runtime="${PIDD_RUNTIME_DIR:-/data/adb/pixel-drop-dispatch}"
    config="$runtime/config.env"
    echo "== Pixel Drop Dispatcher Link =="
    echo "sortify_dispatcher_integration=$SORTIFY_DISPATCHER_INTEGRATION"
    echo "sortify_hold_protected=$SORTIFY_HOLD_PROTECTED"
    echo "sortify_normal_sort=$SORTIFY_NORMAL_SORT"
    echo "dispatcher_integration_state=$(dispatcher_integration_state)"
    if [ -d "$runtime" ]; then
        echo "dispatcher_runtime_present=yes"
        echo "dispatcher_runtime=$runtime"
    else
        echo "dispatcher_runtime_present=no"
        echo "dispatcher_runtime=$runtime"
    fi

    if [ -f "$config" ]; then
        echo "dispatcher_config_present=yes"
        grep -E '^(DROP_SCAN_ROOT|SCAN_ROOT|PIDD_POLICY_VERSION|TARGETS)=' "$config" 2>/dev/null | sed 's/^/dispatcher_/' || true
    else
        echo "dispatcher_config_present=no"
    fi

    if [ "$DOWNLOADS" = "/sdcard/Download" ] || [ "$DOWNLOADS" = "/storage/emulated/0/Download" ]; then
        echo "sortify_download_matches_default_dispatcher_scan_root=yes"
    else
        echo "sortify_download_matches_default_dispatcher_scan_root=unknown"
        echo "sortify_download=$DOWNLOADS"
    fi
}

sort_now() {
    normalize_config
    ensure_dirs

    if [ "${SORTIFY_NORMAL_SORT:-1}" != "1" ]; then
        ui_print "Sortify normal sorting disabled by config"
        log_guard "SORTIFY_NORMAL_SORT disabled; skipping sort"
        return 0
    fi

    require_dispatcher_if_needed || return $?

    ui_print "▶ Sortify Dispatch: Manual sort started"

    move_files "$DEST_BASE/Documents" $DOC_EXT
    move_files "$DEST_BASE/Images" $IMG_EXT
    move_files "$DEST_BASE/Videos" $VID_EXT
    move_files "$DEST_BASE/Audio" $AUD_EXT
    move_files "$DEST_BASE/Archives" $ARC_EXT
    move_files "$DEST_BASE/Apps" $APP_EXT

    find "$DOWNLOADS" -maxdepth 1 -type f \
        ! -name ".*" \
        ! -name "*.crdownload" \
        ! -name "*.partial" \
        ! -name "*.tmp" -print | while IFS= read -r file; do
            move_one "$DEST_BASE/Others" "$file"
        done

    date "+[%Y-%m-%d %H:%M:%S] Manual sort triggered" >> "$DEST_BASE/sortify.log"

    ui_print "✔ Sortify Dispatch: Manual sort completed"
}

case "${1:-sort}" in
    --guard-status|--guard-verify|guard-status|guard-verify)
        guard_status
        ;;
    --guard-clean|guard-clean)
        guard_clean
        ;;
    --dispatcher-status|dispatcher-status)
        dispatcher_status
        ;;
    --config-status|config-status)
        sortify_config_status
        ;;
    --sort|sort|"")
        sort_now
        ;;
    *)
        echo "Usage: action.sh [--sort|--guard-status|--guard-clean|--dispatcher-status|--config-status]"
        exit 2
        ;;
esac
