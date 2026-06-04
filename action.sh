#!/system/bin/sh
# Sortify Dispatch v4.5.1-custom-park-prefixes - Manual Action / Guard Tools

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
SORTIFY_CUSTOM_PARK_PREFIXES="${SORTIFY_CUSTOM_PARK_PREFIXES:-}"
SORTIFY_GUARD_MAX_FILES="${SORTIFY_GUARD_MAX_FILES:-300}"
SORTIFY_GUARD_STATUS_TIMEOUT="${SORTIFY_GUARD_STATUS_TIMEOUT:-8}"
SORTIFY_DISPATCHER_RUNTIME_DIR="${SORTIFY_DISPATCHER_RUNTIME_DIR:-${PIDD_RUNTIME_DIR:-/data/adb/ssh-drop-dispatcher}}"
SORTIFY_DISPATCHER_REQUIRED_POLICY="${SORTIFY_DISPATCHER_REQUIRED_POLICY:-${PIDD_SORTIFY_REQUIRED_POLICY:-v4115}}"
SORTIFY_DISPATCHER_RELEASE_DIR="${SORTIFY_DISPATCHER_RELEASE_DIR:-${PIDD_SORTIFY_RELEASE_DIR:-$SORTIFY_DISPATCHER_RUNTIME_DIR/integration/sortify-release}}"
PIDD_RUNTIME_DIR="$SORTIFY_DISPATCHER_RUNTIME_DIR"
PIDD_SORTIFY_REQUIRED_POLICY="$SORTIFY_DISPATCHER_REQUIRED_POLICY"
PIDD_SORTIFY_RELEASE_DIR="$SORTIFY_DISPATCHER_RELEASE_DIR"

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

    case "${SORTIFY_GUARD_MAX_FILES:-300}" in
        ""|*[!0-9]*) SORTIFY_GUARD_MAX_FILES="300" ;;
    esac
    [ "$SORTIFY_GUARD_MAX_FILES" -lt 1 ] 2>/dev/null && SORTIFY_GUARD_MAX_FILES="300"
    [ "$SORTIFY_GUARD_MAX_FILES" -gt 2000 ] 2>/dev/null && SORTIFY_GUARD_MAX_FILES="2000"

    case "${SORTIFY_GUARD_STATUS_TIMEOUT:-8}" in
        ""|*[!0-9]*) SORTIFY_GUARD_STATUS_TIMEOUT="8" ;;
    esac
    [ "$SORTIFY_GUARD_STATUS_TIMEOUT" -lt 2 ] 2>/dev/null && SORTIFY_GUARD_STATUS_TIMEOUT="8"
    [ "$SORTIFY_GUARD_STATUS_TIMEOUT" -gt 60 ] 2>/dev/null && SORTIFY_GUARD_STATUS_TIMEOUT="60"

    PIDD_RUNTIME_DIR="${PIDD_RUNTIME_DIR:-/data/adb/ssh-drop-dispatcher}"
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



# SORTIFY_CUSTOM_PARK_PREFIXES_V1_START
custom_prefix_sanitize_one() {
    raw="$1"
    clean="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    case "$clean" in
        ""|target-*|targets-*|*[!a-z0-9_.-]*) return 1 ;;
    esac
    case "$clean" in ???*) ;; *) return 1 ;; esac
    printf '%s' "$clean"
}

custom_prefixes_csv() {
    old_ifs="$IFS"
    IFS=","
    first=1
    seen=""
    for raw in ${SORTIFY_CUSTOM_PARK_PREFIXES:-}; do
        clean="$(custom_prefix_sanitize_one "$raw" 2>/dev/null || true)"
        [ -n "$clean" ] || continue
        case ",$seen," in *",$clean,"*) continue ;; esac
        seen="${seen:+$seen,}$clean"
        if [ "$first" = "1" ]; then printf '%s' "$clean"; first=0; else printf ',%s' "$clean"; fi
    done
    IFS="$old_ifs"
}

custom_park_match_prefix() {
    name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    prefixes="$(custom_prefixes_csv)"
    old_ifs="$IFS"
    IFS=","
    for prefix in $prefixes; do
        [ -n "$prefix" ] || continue
        case "$name" in "$prefix"*) IFS="$old_ifs"; printf '%s' "$prefix"; return 0 ;; esac
    done
    IFS="$old_ifs"
    return 1
}

is_custom_park_artifact() {
    [ -n "$(custom_park_match_prefix "$1" 2>/dev/null || true)" ]
}

custom_prefixes_status() {
    normalize_config
    echo "== Sortify Dispatch Custom Park Prefixes =="
    echo "custom_park_prefixes=$(custom_prefixes_csv)"
    echo "guard_max_files=$SORTIFY_GUARD_MAX_FILES"
    echo "guard_status_timeout=$SORTIFY_GUARD_STATUS_TIMEOUT"
    echo "custom_prefix_scope=local_hold_only"
    echo "dispatcher_marker_required=no"
    echo "sdd_targets_managed=no"
}

test_filename_status() {
    normalize_config
    name="$(basename "${1:-}")"
    if [ -z "$name" ]; then echo "test_filename=missing"; return 2; fi
    prefix="$(custom_park_match_prefix "$name" 2>/dev/null || true)"
    echo "== Sortify Dispatch Filename Test =="
    echo "filename=$name"
    if [ -n "$prefix" ]; then
        echo "local_hold=yes"
        echo "reason=custom_prefix:$prefix"
        echo "dispatcher_marker_required=no"
        echo "would_sort=no"
        return 0
    fi
    if is_protected_artifact "$name"; then
        echo "local_hold=yes"
        echo "reason=builtin_protected_pattern"
        echo "dispatcher_marker_required=maybe_for_remote_target"
        echo "would_sort=no_without_valid_marker"
        return 0
    fi
    echo "local_hold=no"
    echo "reason=no_protected_pattern"
    echo "dispatcher_marker_required=no"
    echo "would_sort=yes_if_normal_sort_enabled"
}
# SORTIFY_CUSTOM_PARK_PREFIXES_V1_END

# SORTIFY_SDD_V4115_CONTRACT_V1_START
dispatcher_health_ok() {
    runtime="${PIDD_RUNTIME_DIR:-/data/adb/ssh-drop-dispatcher}"
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
        log_guard "dispatcher required but missing_or_unhealthy runtime=${PIDD_RUNTIME_DIR:-/data/adb/ssh-drop-dispatcher} release_dir=${PIDD_SORTIFY_RELEASE_DIR:-}"
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

dispatcher_sortify_marker_path() {
    file="$1"
    normalize_config
    sha="$(file_sha256 "$file" 2>/dev/null || true)"
    [ -n "$sha" ] || return 1
    printf '%s/%s.env' "$PIDD_SORTIFY_RELEASE_DIR" "$sha"
}

pidd_sortify_marker_path() {
    dispatcher_sortify_marker_path "$@"
}

marker_clean_value() {
    printf '%s' "$1" | tr -d '
' | sed "s/^[\"']//;s/[\"']$//"
}

dispatcher_sortify_contract_released() {
    file="$1"
    normalize_config

    [ -f "$file" ] || return 1
    sha="$(file_sha256 "$file" 2>/dev/null || true)"
    size="$(file_size_bytes "$file" 2>/dev/null || true)"
    [ -n "$sha" ] || return 1
    [ -n "$size" ] || return 1

    marker="$PIDD_SORTIFY_RELEASE_DIR/$sha.env"
    [ -f "$marker" ] || return 1

    released="$(marker_clean_value "$(marker_field "$marker" released)")"
    authority="$(marker_clean_value "$(marker_field "$marker" authority)")"
    marker_sha="$(marker_clean_value "$(marker_field "$marker" sha256)")"
    marker_size="$(marker_clean_value "$(marker_field "$marker" size)")"
    policy="$(marker_clean_value "$(marker_field "$marker" policy)")"
    pending="$(marker_clean_value "$(marker_field "$marker" pending_targets)")"

    [ "$released" = "yes" ] || return 1
    [ "$authority" = "dispatcher" ] || return 1
    [ "$marker_sha" = "$sha" ] || return 1
    [ "$marker_size" = "$size" ] || return 1
    [ "$policy" = "$PIDD_SORTIFY_REQUIRED_POLICY" ] || return 1
    [ -z "$pending" ] || return 1

    return 0
}

pidd_sortify_contract_released() {
    dispatcher_sortify_contract_released "$@"
}

dispatcher_sortify_contract_status() {
    file="$1"
    normalize_config

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

    released="$(marker_clean_value "$(marker_field "$marker" released)")"
    authority="$(marker_clean_value "$(marker_field "$marker" authority)")"
    marker_sha="$(marker_clean_value "$(marker_field "$marker" sha256)")"
    marker_size="$(marker_clean_value "$(marker_field "$marker" size)")"
    policy="$(marker_clean_value "$(marker_field "$marker" policy)")"
    pending="$(marker_clean_value "$(marker_field "$marker" pending_targets)")"
    reason="$(marker_clean_value "$(marker_field "$marker" reason)")"

    if dispatcher_sortify_contract_released "$file"; then
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

pidd_sortify_contract_status() {
    dispatcher_sortify_contract_status "$@"
}

should_hold_protected_artifact() {
    file="$1"
    name="$(basename "$file")"
    normalize_config

    [ "${SORTIFY_HOLD_PROTECTED:-1}" = "1" ] || return 1
    if is_custom_park_artifact "$name"; then
        prefix="$(custom_park_match_prefix "$name" 2>/dev/null || true)"
        log_guard "hold custom parked artifact file=$name prefix=$prefix dispatcher_marker_required=no reason=custom_park_prefix"
        return 0
    fi
    is_protected_artifact "$name" || return 1

    case "$name" in
        target-pi3__*|target-pi4__*|target-zeropi2__*|target-berylax__*|targets-*__*)
            if dispatcher_sortify_contract_released "$file" 2>/dev/null || pidd_sortify_contract_released "$file" 2>/dev/null; then
                log_guard "release remote protected artifact file=$name contract=$(dispatcher_sortify_contract_status "$file" 2>/dev/null || pidd_sortify_contract_status "$file" 2>/dev/null || echo unavailable)"
                return 1
            fi
            state="$(dispatcher_integration_state)"
            log_guard "hold remote protected artifact file=$name integration=$state contract=$(dispatcher_sortify_contract_status "$file" 2>/dev/null || pidd_sortify_contract_status "$file" 2>/dev/null || echo unavailable)"
            return 0
            ;;
        pixel_local__*|pixel-termux*|pixel_termux*|termux-*|termux_*|repo_*)
            log_guard "hold local protected artifact file=$name dispatcher_marker_required=no reason=pixel_local_hold_only"
            return 0
            ;;
    esac

    if dispatcher_sortify_contract_released "$file" 2>/dev/null || pidd_sortify_contract_released "$file" 2>/dev/null; then
        log_guard "release protected artifact file=$name contract=$(dispatcher_sortify_contract_status "$file" 2>/dev/null || pidd_sortify_contract_status "$file" 2>/dev/null || echo unavailable)"
        return 1
    fi

    state="$(dispatcher_integration_state)"
    log_guard "hold protected artifact file=$name integration=$state contract=$(dispatcher_sortify_contract_status "$file" 2>/dev/null || pidd_sortify_contract_status "$file" 2>/dev/null || echo unavailable)"
    return 0
}
# SORTIFY_SDD_V4115_CONTRACT_V1_END

DOC_EXT="pdf doc docx txt xls xlsx ppt pptx csv md log json yaml yml xml"
IMG_EXT="jpg jpeg png gif bmp webp heic heif svg"
VID_EXT="mp4 mkv avi mov webm flv mpeg mpg 3gp"
AUD_EXT="mp3 m4a flac wav ogg opus aac wma"
ARC_EXT="zip rar 7z tar gz bz2 xz tgz txz tbz tbz2 iso"
APP_EXT="apk exe apks apkm xapk"

is_protected_artifact() {
    name="$1"
    lower="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"

    if is_custom_park_artifact "$lower"; then
        return 0
    fi

    case "$lower" in
        target-pi3__*|target-pi4__*|target-zeropi2__*|target-berylax__*|targets-*__*)
            return 0
            ;;
        pi3_*|pi4_*|zeropi2_*|berylax_*)
            return 0
            ;;
        pixel_local__*|pixel-termux*|pixel_termux*|termux-*|termux_*|repo_*)
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

    if should_hold_protected_artifact "$file"; then
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
    normalize_config
    limit="${SORTIFY_GUARD_MAX_FILES:-300}"
    find "$dir" -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r file; do
        name="$(basename "$file")"
        if is_protected_artifact "$name"; then
            printf '%s
' "$file"
        fi
    done | sed -n "1,${limit}p"
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

guard_status_raw() {
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
    echo "version=4.5.1-custom-park-prefixes"
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


guard_status() {
    normalize_config
    if [ "${SORTIFY_GUARD_STATUS_INNER:-0}" != "1" ]; then
        if command -v timeout >/dev/null 2>&1; then
            SORTIFY_GUARD_STATUS_INNER=1 timeout "$SORTIFY_GUARD_STATUS_TIMEOUT" sh "$0" --guard-status-raw
            rc=$?
            if [ "$rc" = "124" ]; then
                echo "== Sortify Dispatch Guard Status =="
                echo "guard_status=timeout"
                echo "timeout_seconds=$SORTIFY_GUARD_STATUS_TIMEOUT"
                echo "guard_max_files=$SORTIFY_GUARD_MAX_FILES"
                return 124
            fi
            return "$rc"
        fi
        if command -v toybox >/dev/null 2>&1 && toybox --list 2>/dev/null | grep -qx timeout; then
            SORTIFY_GUARD_STATUS_INNER=1 toybox timeout "$SORTIFY_GUARD_STATUS_TIMEOUT" sh "$0" --guard-status-raw
            rc=$?
            if [ "$rc" = "124" ]; then
                echo "== Sortify Dispatch Guard Status =="
                echo "guard_status=timeout"
                echo "timeout_seconds=$SORTIFY_GUARD_STATUS_TIMEOUT"
                echo "guard_max_files=$SORTIFY_GUARD_MAX_FILES"
                return 124
            fi
            return "$rc"
        fi
    fi
    guard_status_raw
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
    echo "sortify_custom_park_prefixes=$(custom_prefixes_csv)"
    echo "sortify_guard_max_files=$SORTIFY_GUARD_MAX_FILES"
    echo "sortify_guard_status_timeout=$SORTIFY_GUARD_STATUS_TIMEOUT"
    echo "dispatcher_runtime_dir=$PIDD_RUNTIME_DIR"
    echo "legacy_pidd_runtime_dir=$PIDD_RUNTIME_DIR"
    echo "dispatcher_sortify_release_dir=$PIDD_SORTIFY_RELEASE_DIR"
    echo "legacy_pidd_sortify_release_dir=$PIDD_SORTIFY_RELEASE_DIR"
    echo "dispatcher_required_policy=$PIDD_SORTIFY_REQUIRED_POLICY"
    echo "legacy_pidd_sortify_required_policy=$PIDD_SORTIFY_REQUIRED_POLICY"
    echo "sortify_contract=policy_v4115_sha_size_authority_pending"
    echo "dispatcher_integration_state=$(dispatcher_integration_state)"
    echo "dispatcher_sortify_release_dir=$PIDD_SORTIFY_RELEASE_DIR"
    echo "legacy_pidd_sortify_release_dir=$PIDD_SORTIFY_RELEASE_DIR"
    echo "dispatcher_required_policy=$PIDD_SORTIFY_REQUIRED_POLICY"
    echo "legacy_pidd_sortify_required_policy=$PIDD_SORTIFY_REQUIRED_POLICY"
}

dispatcher_status() {
    normalize_config
    runtime="${PIDD_RUNTIME_DIR:-/data/adb/ssh-drop-dispatcher}"
    config="$runtime/config.env"
    echo "== SSH Drop Dispatcher Link =="
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

zip_export_dir() {
    work="$1"
    out="$2"
    if command -v zip >/dev/null 2>&1; then
        (cd "$work" && zip -qr "$out" .)
        return $?
    fi
    py="/data/data/com.termux/files/usr/bin/python3"
    [ -x "$py" ] || py="/data/data/com.termux/files/usr/bin/python"
    if [ ! -x "$py" ]; then
        echo "config_export=failed"
        echo "reason=missing_zip_or_python"
        return 1
    fi
    (cd "$work" && "$py" -c 'import os,sys,zipfile; out=sys.argv[1]; root="."; z=zipfile.ZipFile(out,"w",zipfile.ZIP_DEFLATED); [z.write(os.path.join(b,f), os.path.relpath(os.path.join(b,f), root)) for b,d,fs in os.walk(root) for f in sorted(fs)]; z.close()' "$out")
}

sortify_config_export() {
    normalize_config
    ensure_dirs
    stamp="$(date '+%Y%m%d_%H%M%S' 2>/dev/null || echo now)"
    work="$DEST_BASE/.sortify_config_export_$stamp"
    out="$DOWNLOADS/Sortify-Dispatch-config-$stamp.zip"

    rm -rf "$work"
    mkdir -p "$work"
    {
        echo "backup_format=sortify-dispatch-config-v1"
        echo "created_at=$stamp"
        echo "version=4.5.1-custom-park-prefixes"
        echo "includes_sdd_targets=no"
        echo "includes_ssh_keys=no"
        echo "includes_dispatcher_config=no"
        echo "scope=sortify_only"
        echo "includes_custom_park_prefixes=yes"
        echo "includes_guard_bounds=yes"
    } > "$work/manifest.env"

    [ -f "$CONF_PATH" ] && cp -f "$CONF_PATH" "$work/sortify.conf" 2>/dev/null || true
    sortify_config_status > "$work/config-status.txt" 2>&1 || true
    guard_status > "$work/guard-status.txt" 2>&1 || true
    dispatcher_status > "$work/dispatcher-link-status.txt" 2>&1 || true
    [ -f "$MODULE_DIR/module.prop" ] && grep -E '^(id=|name=|version=|versionCode=|author=|description=|updateJson=)' "$MODULE_DIR/module.prop" > "$work/module.prop.snapshot" 2>/dev/null || true

    (cd "$work" && find . -type f | sort | while IFS= read -r f; do sha256sum "$f" 2>/dev/null || toybox sha256sum "$f" 2>/dev/null || true; done > SHA256SUMS)
    rm -f "$out"
    zip_export_dir "$work" "$out" || return $?
    chmod 600 "$out" 2>/dev/null || true
    rm -rf "$work"

    echo "== Sortify Dispatch Config Export =="
    echo "config_export=done"
    echo "config_zip=$out"
    echo "includes_sdd_targets=no"
    echo "includes_ssh_keys=no"
    echo "includes_dispatcher_config=no"
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
    --guard-status-raw|guard-status-raw)
        guard_status_raw
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
    --custom-prefixes-status|custom-prefixes-status)
        custom_prefixes_status
        ;;
    --test-filename|test-filename)
        test_filename_status "${2:-}"
        ;;
    --config-export|config-export)
        sortify_config_export
        ;;
    --sort|sort|"")
        sort_now
        ;;
    *)
        echo "Usage: action.sh [--sort|--guard-status|--guard-status-raw|--guard-clean|--dispatcher-status|--config-status|--custom-prefixes-status|--test-filename NAME|--config-export]"
        exit 2
        ;;
esac
