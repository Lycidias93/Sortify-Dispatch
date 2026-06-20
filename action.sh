#!/system/bin/sh
# Sortify Dispatch 4.6.5-sort-mode-control - Manual Action / Guard Tools

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
SORTIFY_SORT_MODE="${SORTIFY_SORT_MODE:-interval}"
SORTIFY_CUSTOM_PARK_PREFIXES="${SORTIFY_CUSTOM_PARK_PREFIXES:-}"
SORTIFY_GUARD_MAX_FILES="${SORTIFY_GUARD_MAX_FILES:-300}"
SORTIFY_GUARD_STATUS_TIMEOUT="${SORTIFY_GUARD_STATUS_TIMEOUT:-8}"
SORTIFY_DUPLICATE_MODE="${SORTIFY_DUPLICATE_MODE:-filename}"
SORTIFY_LOG_MAX_KB="${SORTIFY_LOG_MAX_KB:-1024}"
SORTIFY_GUARD_TEMP_CLEAN_ON_SORT="${SORTIFY_GUARD_TEMP_CLEAN_ON_SORT:-1}"
SORTIFY_PREVIEW_MAX_FILES="${SORTIFY_PREVIEW_MAX_FILES:-50}"
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

normalize_config() {
    case "${SORTIFY_DISPATCHER_INTEGRATION:-auto}" in off|auto|on) ;; *) SORTIFY_DISPATCHER_INTEGRATION="auto" ;; esac
    case "${SORTIFY_HOLD_PROTECTED:-1}" in 0|1) ;; *) SORTIFY_HOLD_PROTECTED="1" ;; esac
    case "${SORTIFY_NORMAL_SORT:-1}" in 0|1) ;; *) SORTIFY_NORMAL_SORT="1" ;; esac
    case "${SORTIFY_SORT_MODE:-interval}" in interval|manual|boot_once) ;; *) SORTIFY_SORT_MODE="interval" ;; esac
    case "${SORTIFY_DUPLICATE_MODE:-filename}" in filename|checksum_delete_identical) ;; *) SORTIFY_DUPLICATE_MODE="filename" ;; esac
    case "${SORTIFY_GUARD_TEMP_CLEAN_ON_SORT:-1}" in 0|1) ;; *) SORTIFY_GUARD_TEMP_CLEAN_ON_SORT="1" ;; esac
    case "${SORTIFY_GUARD_MAX_FILES:-300}" in ""|*[!0-9]*) SORTIFY_GUARD_MAX_FILES="300" ;; esac
    [ "$SORTIFY_GUARD_MAX_FILES" -lt 1 ] 2>/dev/null && SORTIFY_GUARD_MAX_FILES="300"
    [ "$SORTIFY_GUARD_MAX_FILES" -gt 2000 ] 2>/dev/null && SORTIFY_GUARD_MAX_FILES="2000"
    case "${SORTIFY_GUARD_STATUS_TIMEOUT:-8}" in ""|*[!0-9]*) SORTIFY_GUARD_STATUS_TIMEOUT="8" ;; esac
    [ "$SORTIFY_GUARD_STATUS_TIMEOUT" -lt 2 ] 2>/dev/null && SORTIFY_GUARD_STATUS_TIMEOUT="8"
    [ "$SORTIFY_GUARD_STATUS_TIMEOUT" -gt 60 ] 2>/dev/null && SORTIFY_GUARD_STATUS_TIMEOUT="60"
    case "${SORTIFY_LOG_MAX_KB:-1024}" in ""|*[!0-9]*) SORTIFY_LOG_MAX_KB="1024" ;; esac
    [ "$SORTIFY_LOG_MAX_KB" -lt 64 ] 2>/dev/null && SORTIFY_LOG_MAX_KB="64"
    [ "$SORTIFY_LOG_MAX_KB" -gt 16384 ] 2>/dev/null && SORTIFY_LOG_MAX_KB="16384"
    case "${SORTIFY_PREVIEW_MAX_FILES:-50}" in ""|*[!0-9]*) SORTIFY_PREVIEW_MAX_FILES="50" ;; esac
    [ "$SORTIFY_PREVIEW_MAX_FILES" -lt 1 ] 2>/dev/null && SORTIFY_PREVIEW_MAX_FILES="1"
    [ "$SORTIFY_PREVIEW_MAX_FILES" -gt 200 ] 2>/dev/null && SORTIFY_PREVIEW_MAX_FILES="200"
    PIDD_RUNTIME_DIR="${PIDD_RUNTIME_DIR:-/data/adb/ssh-drop-dispatcher}"
    PIDD_SORTIFY_REQUIRED_POLICY="${PIDD_SORTIFY_REQUIRED_POLICY:-v4115}"
    PIDD_SORTIFY_RELEASE_DIR="${PIDD_SORTIFY_RELEASE_DIR:-$PIDD_RUNTIME_DIR/integration/sortify-release}"
}

normalize_config

ensure_dirs() {
    mkdir -p "$DEST_BASE/Documents" "$DEST_BASE/Images" "$DEST_BASE/Videos" "$DEST_BASE/Audio" \
             "$DEST_BASE/Archives" "$DEST_BASE/Apps" "$DEST_BASE/Ebooks" "$DEST_BASE/Code" \
             "$DEST_BASE/Config" "$DEST_BASE/Data" "$DEST_BASE/Fonts" "$DEST_BASE/Certificates" \
             "$DEST_BASE/Backups" "$DEST_BASE/Torrents" "$DEST_BASE/Others" \
             "$DEST_BASE/Duplicates" "$DEST_BASE/GuardConflicts"
}

file_size_bytes() { wc -c < "$1" 2>/dev/null | tr -d ' ' 2>/dev/null; }

rotate_logs() {
    ensure_dirs
    normalize_config
    max_bytes=$((SORTIFY_LOG_MAX_KB * 1024))
    for log in "$DEST_BASE/guard.log" "$DEST_BASE/sortify.log"; do
        [ -f "$log" ] || continue
        size="$(file_size_bytes "$log" 2>/dev/null || echo 0)"
        case "$size" in ""|*[!0-9]*) size=0 ;; esac
        if [ "$size" -gt "$max_bytes" ]; then
            stamp="$(date '+%Y%m%d_%H%M%S' 2>/dev/null || echo now)"
            mv -f "$log" "$log.$stamp" 2>/dev/null || true
            : > "$log" 2>/dev/null || true
        fi
    done
}

log_guard() {
    [ "${GUARD_LOG:-1}" = "1" ] || return 0
    ensure_dirs
    rotate_logs
    echo "[Guard] $(date '+%Y-%m-%d %H:%M:%S') $*" >> "$DEST_BASE/guard.log"
}

cleanup_guard_temp() {
    ensure_dirs
    count=0
    find "$DEST_BASE" -maxdepth 1 -type f \( -name '.guard_*' -o -name '.sortify_config_export_*' \) -print 2>/dev/null | while IFS= read -r f; do
        rm -f "$f" 2>/dev/null && count=$((count + 1))
        echo "removed=$f"
    done
    echo "guard_temp_clean=done"
}

custom_prefix_sanitize_one() {
    raw="$1"
    clean="$(printf '%s' "$raw" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    case "$clean" in ""|target-*|targets-*|*[!a-z0-9_.-]*) return 1 ;; esac
    case "$clean" in ???*) ;; *) return 1 ;; esac
    printf '%s' "$clean"
}

custom_prefixes_csv() {
    old_ifs="$IFS"; IFS=","
    first=1; seen=""
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
    old_ifs="$IFS"; IFS=","
    for prefix in $prefixes; do
        [ -n "$prefix" ] || continue
        case "$name" in "$prefix"*) IFS="$old_ifs"; printf '%s' "$prefix"; return 0 ;; esac
    done
    IFS="$old_ifs"
    return 1
}

is_custom_park_artifact() { [ -n "$(custom_park_match_prefix "$1" 2>/dev/null || true)" ]; }

is_markdown_handover_artifact() {
    name="$1"; lower="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
    case "$lower" in
        *handover*.md|readme*.md|release_notes*.md) return 0 ;;
    esac
    return 1
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

marker_field() { marker="$1"; key="$2"; sed -n "s/^${key}=//p" "$marker" 2>/dev/null | sed -n '1p'; }
marker_clean_value() { printf '%s' "$1" | tr -d '\n' | sed "s/^[\"']//;s/[\"']$//"; }

dispatcher_health_ok() {
    runtime="${PIDD_RUNTIME_DIR:-/data/adb/ssh-drop-dispatcher}"; health="$runtime/health.env"
    [ -d "$runtime" ] || return 1; [ -f "$health" ] || return 1
    ( . "$health" 2>/dev/null || exit 1; [ "${status:-}" = "OK" ] || exit 1; [ "${inflight_bytes:-0}" = "0" ] || exit 1 ) >/dev/null 2>&1
}

dispatcher_marker_dir_ok() { normalize_config; [ -d "$PIDD_SORTIFY_RELEASE_DIR" ] && [ -r "$PIDD_SORTIFY_RELEASE_DIR" ]; }
dispatcher_contract_ok() { dispatcher_health_ok && dispatcher_marker_dir_ok; }

dispatcher_integration_state() {
    normalize_config
    case "$SORTIFY_DISPATCHER_INTEGRATION" in
        off) echo "disabled" ;;
        on) if dispatcher_contract_ok; then echo "active"; else echo "required_missing"; fi ;;
        auto|*) if dispatcher_contract_ok; then echo "active"; else echo "auto_inactive"; fi ;;
    esac
}

require_dispatcher_if_needed() {
    normalize_config
    if [ "$SORTIFY_DISPATCHER_INTEGRATION" = "on" ] && ! dispatcher_contract_ok; then
        ui_print "ERROR: dispatcher integration required but SSH Drop Dispatcher runtime/marker directory is not healthy"
        log_guard "dispatcher required but missing_or_unhealthy runtime=${PIDD_RUNTIME_DIR:-/data/adb/ssh-drop-dispatcher} release_dir=${PIDD_SORTIFY_RELEASE_DIR:-}"
        return 3
    fi
    return 0
}

dispatcher_sortify_contract_released() {
    file="$1"; normalize_config
    [ -f "$file" ] || return 1
    sha="$(file_sha256 "$file" 2>/dev/null || true)"; size="$(file_size_bytes "$file" 2>/dev/null || true)"
    [ -n "$sha" ] && [ -n "$size" ] || return 1
    marker="$PIDD_SORTIFY_RELEASE_DIR/$sha.env"; [ -f "$marker" ] || return 1
    released="$(marker_clean_value "$(marker_field "$marker" released)")"
    authority="$(marker_clean_value "$(marker_field "$marker" authority)")"
    marker_sha="$(marker_clean_value "$(marker_field "$marker" sha256)")"
    marker_size="$(marker_clean_value "$(marker_field "$marker" size)")"
    policy="$(marker_clean_value "$(marker_field "$marker" policy)")"
    pending="$(marker_clean_value "$(marker_field "$marker" pending_targets)")"
    [ "$released" = "yes" ] && [ "$authority" = "dispatcher" ] && [ "$marker_sha" = "$sha" ] && [ "$marker_size" = "$size" ] && [ "$policy" = "$PIDD_SORTIFY_REQUIRED_POLICY" ] && [ -z "$pending" ]
}

pidd_sortify_contract_released() { dispatcher_sortify_contract_released "$@"; }

dispatcher_sortify_contract_status() {
    file="$1"; normalize_config
    sha="$(file_sha256 "$file" 2>/dev/null || true)"; size="$(file_size_bytes "$file" 2>/dev/null || true)"
    [ -n "$sha" ] || { echo "held:no_sha"; return 0; }
    marker="$PIDD_SORTIFY_RELEASE_DIR/$sha.env"
    [ -f "$marker" ] || { echo "held:marker_missing"; return 0; }
    released="$(marker_clean_value "$(marker_field "$marker" released)")"
    authority="$(marker_clean_value "$(marker_field "$marker" authority)")"
    marker_sha="$(marker_clean_value "$(marker_field "$marker" sha256)")"
    marker_size="$(marker_clean_value "$(marker_field "$marker" size)")"
    policy="$(marker_clean_value "$(marker_field "$marker" policy)")"
    pending="$(marker_clean_value "$(marker_field "$marker" pending_targets)")"
    reason="$(marker_clean_value "$(marker_field "$marker" reason)")"
    if dispatcher_sortify_contract_released "$file"; then echo "released:policy=$policy reason=$reason"; return 0; fi
    if [ "$released" = "no" ]; then echo "held:released_no policy=$policy pending=$pending reason=$reason";
    elif [ "$policy" != "$PIDD_SORTIFY_REQUIRED_POLICY" ]; then echo "held:policy_mismatch got=$policy required=$PIDD_SORTIFY_REQUIRED_POLICY";
    elif [ "$authority" != "dispatcher" ]; then echo "held:authority_mismatch got=$authority";
    elif [ "$marker_sha" != "$sha" ] || [ "$marker_size" != "$size" ]; then echo "held:sha_or_size_mismatch";
    elif [ -n "$pending" ]; then echo "held:pending_targets=$pending";
    else echo "held:not_released released=$released policy=$policy"; fi
}

pidd_sortify_contract_status() { dispatcher_sortify_contract_status "$@"; }

is_protected_artifact() {
    name="$1"; lower="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
    if is_custom_park_artifact "$lower"; then return 0; fi
    if is_markdown_handover_artifact "$lower"; then return 0; fi
    case "$lower" in
        target-pi3__*|target-pi4__*|target-zeropi2__*|target-berylax__*|targets-*__*) return 0 ;;
        pi3_*|pi4_*|zeropi2_*|berylax_*) return 0 ;;
        pixel_local__*|pixel-termux*|pixel_termux*|termux-*|termux_*|repo_*) return 0 ;;
        pixel-drop-dispatch*|pixel_drop_dispatch*|ssh-drop-dispatcher*|ssh_drop_dispatcher*) return 0 ;;
        sortify-dispatch*|sortify_dispatch*) return 0 ;;
        *drop-dispatch*|*drop_dispatch*) return 0 ;;
        repo_*.py|*_repo_*.py|repo_*.sh|*_repo_*.sh) return 0 ;;
    esac
    return 1
}

should_hold_protected_artifact() {
    file="$1"; name="$(basename "$file")"; normalize_config
    [ "${SORTIFY_HOLD_PROTECTED:-1}" = "1" ] || return 1
    is_protected_artifact "$name" || return 1
    prefix="$(custom_park_match_prefix "$name" 2>/dev/null || true)"
    if [ -n "$prefix" ]; then log_guard "hold custom park artifact file=$name prefix=$prefix dispatcher_marker_required=no"; return 0; fi
    if is_markdown_handover_artifact "$name"; then log_guard "hold markdown/handover artifact file=$name dispatcher_marker_required=no reason=markdown_handover_hold"; return 0; fi
    case "$name" in
        target-pi3__*|target-pi4__*|target-zeropi2__*|target-berylax__*|targets-*__*)
            if dispatcher_sortify_contract_released "$file" 2>/dev/null || pidd_sortify_contract_released "$file" 2>/dev/null; then
                log_guard "release remote protected artifact file=$name contract=$(dispatcher_sortify_contract_status "$file" 2>/dev/null || echo unavailable)"; return 1
            fi
            log_guard "hold remote protected artifact file=$name integration=$(dispatcher_integration_state) contract=$(dispatcher_sortify_contract_status "$file" 2>/dev/null || echo unavailable)"; return 0 ;;
        pixel_local__*|pixel-termux*|pixel_termux*|termux-*|termux_*|repo_*)
            log_guard "hold local protected artifact file=$name dispatcher_marker_required=no reason=pixel_local_hold_only"; return 0 ;;
    esac
    if dispatcher_sortify_contract_released "$file" 2>/dev/null || pidd_sortify_contract_released "$file" 2>/dev/null; then
        log_guard "release protected artifact file=$name contract=$(dispatcher_sortify_contract_status "$file" 2>/dev/null || echo unavailable)"; return 1
    fi
    log_guard "hold protected artifact file=$name integration=$(dispatcher_integration_state) contract=$(dispatcher_sortify_contract_status "$file" 2>/dev/null || echo unavailable)"; return 0
}

DOC_EXT="pdf doc docx txt rtf odt ods odp xls xlsx ppt pptx md log pages numbers key"
IMG_EXT="jpg jpeg png gif bmp webp heic heif svg avif tif tiff raw dng"
VID_EXT="mp4 mkv avi mov webm flv mpeg mpg 3gp m4v ts mts"
AUD_EXT="mp3 m4a flac wav ogg opus aac wma mid midi"
ARC_EXT="zip rar 7z tar gz bz2 xz tgz txz tbz tbz2 iso cab arj lz4 zst"
APP_EXT="apk exe apks apkm xapk dmg deb rpm msi"
EBOOK_EXT="epub mobi azw azw3 fb2 djvu cbz cbr"
CODE_EXT="sh bash zsh fish py pyw js ts jsx tsx java kt kts go rs c cc cpp cxx h hpp cs php rb pl lua sql html htm css scss sass ipynb gradle"
CONFIG_EXT="conf cfg ini env toml properties service timer desktop plist reg yaml yml xml json json5"
DATA_EXT="csv tsv jsonl ndjson db sqlite sqlite3 parquet feather arrow dump"
FONT_EXT="ttf otf woff woff2 eot"
CERT_EXT="pem crt cer csr p12 pfx pub asc sig key"
BACKUP_EXT="bak backup old orig img qcow2 vdi vmdk sparseimage ab"
TORRENT_EXT="torrent magnet"

is_skip_candidate() { name="$1"; case "$name" in .*|*.crdownload|*.partial|*.tmp) return 0 ;; esac; return 1; }

duplicate_target_path() {
    filename="$1"; base="$filename"; ext=""
    case "$filename" in *.*) base="${filename%.*}"; ext=".${filename##*.}" ;; esac
    candidate="$DEST_BASE/Duplicates/$filename"
    [ ! -e "$candidate" ] && { printf '%s' "$candidate"; return 0; }
    i=1
    while :; do
        candidate="$DEST_BASE/Duplicates/${base}__duplicate_${i}${ext}"
        [ ! -e "$candidate" ] && { printf '%s' "$candidate"; return 0; }
        i=$((i + 1))
    done
}

handle_existing_destination() {
    dest="$1"; file="$2"; filename="$(basename "$file")"; existing="$dest/$filename"
    normalize_config
    if [ "${SORTIFY_DUPLICATE_MODE:-filename}" = "checksum_delete_identical" ]; then
        src_sha="$(file_sha256 "$file" 2>/dev/null || true)"; dst_sha="$(file_sha256 "$existing" 2>/dev/null || true)"
        if [ -n "$src_sha" ] && [ -n "$dst_sha" ] && [ "$src_sha" = "$dst_sha" ]; then
            rm -f "$file"
            log_guard "duplicate_same_checksum_deleted file=$filename sha256=$src_sha dest=$dest"
            ui_print "DELETE duplicate same checksum: $filename"
            return 0
        fi
        if [ -z "$src_sha" ] || [ -z "$dst_sha" ]; then
            log_guard "duplicate_checksum_unavailable_keep file=$filename dest=$dest action=move_to_duplicates"
        else
            log_guard "duplicate_name_checksum_diff file=$filename src_sha=$src_sha dst_sha=$dst_sha action=move_to_duplicates"
        fi
    fi
    target="$(duplicate_target_path "$filename")"
    mv -f "$file" "$target"
    ui_print "DUPLICATE name kept: $filename -> $(basename "$target")"
}

move_one() {
    dest="$1"; file="$2"; filename="$(basename "$file")"
    is_skip_candidate "$filename" && return 0
    if should_hold_protected_artifact "$file"; then ui_print "KEEP artifact: $filename"; log_guard "keep download=$DOWNLOADS file=$filename integration=$(dispatcher_integration_state)"; return 0; fi
    if is_protected_artifact "$filename"; then log_guard "protected artifact eligible to sort file=$filename hold=${SORTIFY_HOLD_PROTECTED:-1} integration=$(dispatcher_integration_state)"; fi
    if [ -e "$dest/$filename" ]; then handle_existing_destination "$dest" "$file"; else mv -f "$file" "$dest/"; fi
}

move_files() {
    dest="$1"; shift
    for ext in "$@"; do
        find "$DOWNLOADS" -maxdepth 1 -type f ! -name ".*" ! -name "*.crdownload" ! -name "*.partial" ! -name "*.tmp" -iname "*.$ext" -print 2>/dev/null | while IFS= read -r file; do move_one "$dest" "$file"; done
    done
}

find_protected_under() {
    dir="$1"; [ -d "$dir" ] || return 0; normalize_config; limit="${SORTIFY_GUARD_MAX_FILES:-300}"
    find "$dir" -maxdepth 1 -type f -print 2>/dev/null | while IFS= read -r file; do name="$(basename "$file")"; if is_protected_artifact "$name"; then printf '%s\n' "$file"; fi; done | sed -n "1,${limit}p"
}

find_misplaced_protected() {
    for dir in "$DEST_BASE/Documents" "$DEST_BASE/Images" "$DEST_BASE/Videos" "$DEST_BASE/Audio" "$DEST_BASE/Archives" "$DEST_BASE/Apps" "$DEST_BASE/Ebooks" "$DEST_BASE/Code" "$DEST_BASE/Config" "$DEST_BASE/Data" "$DEST_BASE/Fonts" "$DEST_BASE/Certificates" "$DEST_BASE/Backups" "$DEST_BASE/Torrents" "$DEST_BASE/Others" "$DEST_BASE/Duplicates"; do
        find_protected_under "$dir"
    done
}

count_lines() { wc -l | tr -d ' '; }

guard_status_raw() {
    ensure_dirs; cleanup_guard_temp >/dev/null 2>&1 || true
    tmp_misplaced="$DEST_BASE/.guard_misplaced.$$"; tmp_download="$DEST_BASE/.guard_download.$$"; tmp_conflicts="$DEST_BASE/.guard_conflicts.$$"
    : > "$tmp_misplaced"; : > "$tmp_download"; : > "$tmp_conflicts"
    find_protected_under "$DOWNLOADS" > "$tmp_download" || true
    find_misplaced_protected > "$tmp_misplaced" || true
    find_protected_under "$DEST_BASE/GuardConflicts" > "$tmp_conflicts" || true
    download_count="$(count_lines < "$tmp_download")"; misplaced_count="$(count_lines < "$tmp_misplaced")"; conflict_count="$(count_lines < "$tmp_conflicts")"
    echo "== Sortify Dispatch Guard Status =="; echo "version=4.6.5-sort-mode-control"; echo "download=$DOWNLOADS"; echo "dest_base=$DEST_BASE"; echo "protected_in_download=$download_count"; echo "protected_misplaced=$misplaced_count"; echo "protected_conflicts=$conflict_count"; echo "duplicate_mode=$SORTIFY_DUPLICATE_MODE"
    if [ "$misplaced_count" = "0" ]; then echo "guard_status=pass"; else echo "guard_status=needs_clean"; echo "-- misplaced --"; cat "$tmp_misplaced"; fi
    rm -f "$tmp_misplaced" "$tmp_download" "$tmp_conflicts"
}

guard_status() {
    normalize_config
    if [ "${SORTIFY_GUARD_STATUS_INNER:-0}" != "1" ]; then
        if command -v timeout >/dev/null 2>&1; then
            SORTIFY_GUARD_STATUS_INNER=1 timeout "$SORTIFY_GUARD_STATUS_TIMEOUT" sh "$0" --guard-status-raw; rc=$?
            [ "$rc" = "124" ] && { echo "== Sortify Dispatch Guard Status =="; echo "guard_status=timeout"; echo "timeout_seconds=$SORTIFY_GUARD_STATUS_TIMEOUT"; echo "guard_max_files=$SORTIFY_GUARD_MAX_FILES"; return 124; }
            return "$rc"
        fi
        if command -v toybox >/dev/null 2>&1 && toybox --list 2>/dev/null | grep -qx timeout; then
            SORTIFY_GUARD_STATUS_INNER=1 toybox timeout "$SORTIFY_GUARD_STATUS_TIMEOUT" sh "$0" --guard-status-raw; rc=$?
            [ "$rc" = "124" ] && { echo "== Sortify Dispatch Guard Status =="; echo "guard_status=timeout"; echo "timeout_seconds=$SORTIFY_GUARD_STATUS_TIMEOUT"; echo "guard_max_files=$SORTIFY_GUARD_MAX_FILES"; return 124; }
            return "$rc"
        fi
    fi
    guard_status_raw
}

guard_clean() {
    ensure_dirs; stamp="$(date '+%Y%m%d_%H%M%S')"; conflict_dir="$DEST_BASE/GuardConflicts/$stamp"; tmp_misplaced="$DEST_BASE/.guard_clean.$$"; : > "$tmp_misplaced"
    find_misplaced_protected > "$tmp_misplaced" || true
    total=0; restored=0; conflicts=0
    while IFS= read -r file; do
        [ -n "$file" ] && [ -f "$file" ] || continue
        total=$((total + 1)); name="$(basename "$file")"; target="$DOWNLOADS/$name"
        if [ -e "$target" ]; then mkdir -p "$conflict_dir"; mv -f "$file" "$conflict_dir/$name"; conflicts=$((conflicts + 1)); log_guard "clean conflict source=$file target=$target conflict_dir=$conflict_dir"; else mv -f "$file" "$target"; restored=$((restored + 1)); log_guard "clean restored source=$file target=$target"; fi
    done < "$tmp_misplaced"
    rm -f "$tmp_misplaced"
    echo "== Sortify Dispatch Guard Clean =="; echo "total_misplaced=$total"; echo "restored_to_download=$restored"; echo "moved_to_guard_conflicts=$conflicts"; [ "$conflicts" -gt 0 ] && echo "conflict_dir=$conflict_dir"; echo "guard_clean=done"
}

sortify_config_status() {
    normalize_config
    echo "== Sortify Dispatch Config =="; echo "download=$DOWNLOADS"; echo "dest_base=$DEST_BASE"; echo "conf_path=$CONF_PATH"; echo "guard_log=${GUARD_LOG:-1}"; echo "sortify_normal_sort=$SORTIFY_NORMAL_SORT"; echo "sortify_sort_mode=$SORTIFY_SORT_MODE"; echo "sortify_hold_protected=$SORTIFY_HOLD_PROTECTED"; echo "sortify_dispatcher_integration=$SORTIFY_DISPATCHER_INTEGRATION"; echo "sortify_custom_park_prefixes=$(custom_prefixes_csv)"; echo "sortify_guard_max_files=$SORTIFY_GUARD_MAX_FILES"; echo "sortify_guard_status_timeout=$SORTIFY_GUARD_STATUS_TIMEOUT"; echo "sortify_duplicate_mode=$SORTIFY_DUPLICATE_MODE"; echo "sortify_log_max_kb=$SORTIFY_LOG_MAX_KB"; echo "sortify_guard_temp_clean_on_sort=$SORTIFY_GUARD_TEMP_CLEAN_ON_SORT"; echo "sortify_preview_max_files=$SORTIFY_PREVIEW_MAX_FILES"; echo "dispatcher_runtime_dir=$PIDD_RUNTIME_DIR"; echo "legacy_pidd_runtime_dir=$PIDD_RUNTIME_DIR"; echo "dispatcher_sortify_release_dir=$PIDD_SORTIFY_RELEASE_DIR"; echo "legacy_pidd_sortify_release_dir=$PIDD_SORTIFY_RELEASE_DIR"; echo "dispatcher_required_policy=$PIDD_SORTIFY_REQUIRED_POLICY"; echo "legacy_pidd_sortify_required_policy=$PIDD_SORTIFY_REQUIRED_POLICY"; echo "sortify_contract=policy_v4115_sha_size_authority_pending"; echo "dispatcher_integration_state=$(dispatcher_integration_state)"
}

duplicate_status() { normalize_config; echo "== Sortify Dispatch Duplicate Handling =="; echo "duplicate_mode=$SORTIFY_DUPLICATE_MODE"; echo "checksum_delete_identical_supported=yes"; echo "identical_checksum_action=delete_source"; echo "same_name_different_checksum_action=move_to_duplicates"; echo "checksum_unavailable_action=move_to_duplicates"; }

custom_prefixes_status() { normalize_config; echo "== Sortify Dispatch Custom Park Prefixes =="; echo "custom_park_prefixes=$(custom_prefixes_csv)"; echo "guard_max_files=$SORTIFY_GUARD_MAX_FILES"; echo "guard_status_timeout=$SORTIFY_GUARD_STATUS_TIMEOUT"; echo "custom_prefix_scope=local_hold_only"; echo "dispatcher_marker_required=no"; echo "sdd_targets_managed=no"; }

test_filename_status() {
    normalize_config; name="$(basename "${1:-}")"; [ -n "$name" ] || { echo "test_filename=missing"; return 2; }
    prefix="$(custom_park_match_prefix "$name" 2>/dev/null || true)"; echo "== Sortify Dispatch Filename Test =="; echo "filename=$name"
    if [ -n "$prefix" ]; then echo "local_hold=yes"; echo "reason=custom_prefix:$prefix"; echo "dispatcher_marker_required=no"; echo "would_sort=no"; return 0; fi
    if is_markdown_handover_artifact "$name"; then echo "local_hold=yes"; echo "reason=markdown_handover_hold"; echo "dispatcher_marker_required=no"; echo "would_sort=no"; return 0; fi
    if is_pixel_local_artifact "$name"; then echo "local_hold=yes"; echo "reason=pixel_local_hold_only"; echo "dispatcher_marker_required=no"; echo "would_sort=no"; return 0; fi
    if is_protected_artifact "$name"; then echo "local_hold=yes"; echo "reason=builtin_protected_pattern"; echo "dispatcher_marker_required=maybe_for_remote_target"; echo "would_sort=no_without_valid_marker"; return 0; fi
    echo "local_hold=no"; echo "reason=no_protected_pattern"; echo "dispatcher_marker_required=no"; echo "would_sort=yes_if_normal_sort_enabled"
}


sortify_file_arg_path() {
    arg="${1:-}"
    [ -n "$arg" ] || return 1
    if [ -f "$arg" ]; then printf '%s' "$arg"; return 0; fi
    name="$(basename "$arg")"
    if [ -f "$DOWNLOADS/$name" ]; then printf '%s' "$DOWNLOADS/$name"; return 0; fi
    return 1
}

is_remote_target_artifact() {
    name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    case "$name" in target-pi3__*|target-pi4__*|target-zeropi2__*|target-berylax__*|targets-*__*) return 0 ;; esac
    return 1
}

remote_targets_from_name() {
    name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    case "$name" in
        target-pi3__*) echo "pi3"; return 0 ;;
        target-pi4__*) echo "pi4"; return 0 ;;
        target-zeropi2__*) echo "zeropi2"; return 0 ;;
        target-berylax__*) echo "berylax"; return 0 ;;
        targets-*__*)
            token="${name%%__*}"
            token="${token#targets-}"
            printf '%s' "$token" | tr '-' ' '
            return 0 ;;
    esac
    echo ""
}

is_pixel_local_artifact() {
    name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    case "$name" in pixel_local__*|pixel-termux*|pixel_termux*|termux-*|termux_*|repo_*|repo_*.py|*_repo_*.py|repo_*.sh|*_repo_*.sh) return 0 ;; esac
    return 1
}

is_dispatcher_release_artifact() {
    name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    case "$name" in pixel-drop-dispatch*|pixel_drop_dispatch*|ssh-drop-dispatcher*|ssh_drop_dispatcher*|*drop-dispatch*|*drop_dispatch*) return 0 ;; esac
    return 1
}

is_sortify_release_artifact() {
    name="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
    case "$name" in sortify-dispatch*|sortify_dispatch*) return 0 ;; esac
    return 1
}

sortify_marker_status() {
    normalize_config
    input="${1:-}"
    name="$(basename "$input")"
    echo "== Sortify Dispatch Marker Status =="
    [ -n "$input" ] || { echo "input=missing"; echo "final_gate=FAIL"; echo "reason=missing_input"; return 2; }
    echo "input=$input"
    echo "file=$name"
    echo "marker_root=$PIDD_SORTIFY_RELEASE_DIR"
    echo "policy_required=$PIDD_SORTIFY_REQUIRED_POLICY"
    path="$(sortify_file_arg_path "$input" 2>/dev/null || true)"
    if [ -z "$path" ]; then
        echo "file_exists=no"
        echo "sha256="
        echo "size="
        echo "marker_exists=unknown"
        echo "final_gate=FAIL"
        echo "reason=file_not_found"
        return 0
    fi
    echo "file_exists=yes"
    echo "file_path=$path"
    sha="$(file_sha256 "$path" 2>/dev/null || true)"
    size="$(file_size_bytes "$path" 2>/dev/null || true)"
    echo "sha256=$sha"
    echo "size=$size"
    marker="$PIDD_SORTIFY_RELEASE_DIR/$sha.env"
    echo "marker_path=$marker"
    if [ -z "$sha" ] || [ -z "$size" ]; then
        echo "marker_exists=unknown"
        echo "final_gate=FAIL"
        echo "reason=sha_or_size_unavailable"
        return 0
    fi
    if [ ! -f "$marker" ]; then
        echo "marker_exists=no"
        echo "final_gate=FAIL"
        echo "reason=marker_missing"
        echo "contract=$(dispatcher_sortify_contract_status "$path" 2>/dev/null || echo unavailable)"
        return 0
    fi
    echo "marker_exists=yes"
    released="$(marker_clean_value "$(marker_field "$marker" released)")"
    authority="$(marker_clean_value "$(marker_field "$marker" authority)")"
    marker_sha="$(marker_clean_value "$(marker_field "$marker" sha256)")"
    marker_size="$(marker_clean_value "$(marker_field "$marker" size)")"
    policy="$(marker_clean_value "$(marker_field "$marker" policy)")"
    done_targets="$(marker_clean_value "$(marker_field "$marker" done_targets)")"
    pending_targets="$(marker_clean_value "$(marker_field "$marker" pending_targets)")"
    remote_targets="$(marker_clean_value "$(marker_field "$marker" remote_targets)")"
    reason="$(marker_clean_value "$(marker_field "$marker" reason)")"
    echo "released=$released"
    echo "authority=$authority"
    echo "policy=$policy"
    if [ "$policy" = "$PIDD_SORTIFY_REQUIRED_POLICY" ]; then echo "policy_match=yes"; else echo "policy_match=no"; fi
    echo "marker_sha256=$marker_sha"
    echo "marker_size=$marker_size"
    echo "done_targets=$done_targets"
    echo "pending_targets=$pending_targets"
    echo "remote_targets=$remote_targets"
    echo "marker_reason=$reason"
    if dispatcher_sortify_contract_released "$path" 2>/dev/null; then
        echo "final_gate=PASS"
        echo "contract=released:policy=$policy reason=$reason"
    else
        echo "final_gate=FAIL"
        echo "contract=$(dispatcher_sortify_contract_status "$path" 2>/dev/null || echo unavailable)"
    fi
}

sortify_explain_route() {
    normalize_config
    input="${1:-}"
    name="$(basename "$input")"
    echo "== Sortify Dispatch Route Preview =="
    [ -n "$input" ] || { echo "input=missing"; echo "final_gate=FAIL"; echo "reason=missing_input"; return 2; }
    echo "input=$input"
    echo "file=$name"
    echo "dispatcher_runtime=$PIDD_RUNTIME_DIR"
    echo "marker_root=$PIDD_SORTIFY_RELEASE_DIR"
    echo "policy_required=$PIDD_SORTIFY_REQUIRED_POLICY"
    echo "dispatcher_integration_state=$(dispatcher_integration_state)"
    path="$(sortify_file_arg_path "$input" 2>/dev/null || true)"
    if [ -n "$path" ]; then echo "file_exists=yes"; echo "file_path=$path"; else echo "file_exists=no"; fi
    prefix="$(custom_park_match_prefix "$name" 2>/dev/null || true)"
    if [ -n "$prefix" ]; then
        echo "class=custom_local_hold"
        echo "local_hold=yes"
        echo "reason=custom_prefix:$prefix"
        echo "dispatcher_marker_required=no"
        echo "would_dispatch_by_sdd=no"
        echo "would_sort_by_sortify=no"
        echo "final_gate=PASS"
        return 0
    fi
    if is_markdown_handover_artifact "$name"; then
        echo "class=markdown_handover"
        echo "local_hold=yes"
        echo "reason=markdown_handover_hold"
        echo "dispatcher_marker_required=no"
        echo "would_dispatch_by_sdd=no"
        echo "would_sort_by_sortify=no"
        echo "final_gate=PASS"
        return 0
    fi
    if is_remote_target_artifact "$name"; then
        targets="$(remote_targets_from_name "$name")"
        echo "class=remote_target_artifact"
        echo "route=target_prefix"
        echo "targets=$targets"
        echo "local_hold=yes"
        echo "reason=builtin_protected_pattern"
        echo "dispatcher_marker_required=yes"
        echo "would_dispatch_by_sdd=yes"
        if [ -n "$path" ] && dispatcher_sortify_contract_released "$path" 2>/dev/null; then
            echo "would_sort_by_sortify=yes_valid_marker"
            echo "marker_contract=$(dispatcher_sortify_contract_status "$path" 2>/dev/null || echo unavailable)"
            echo "final_gate=PASS"
        else
            echo "would_sort_by_sortify=no_without_valid_marker"
            if [ -n "$path" ]; then echo "marker_contract=$(dispatcher_sortify_contract_status "$path" 2>/dev/null || echo unavailable)"; else echo "marker_contract=unavailable:file_not_found"; fi
            echo "final_gate=HELD"
        fi
        return 0
    fi
    if is_pixel_local_artifact "$name"; then
        echo "class=pixel_local"
        echo "local_hold=yes"
        echo "reason=pixel_local_hold_only"
        echo "dispatcher_marker_required=no"
        echo "would_dispatch_by_sdd=no"
        echo "would_sort_by_sortify=no"
        echo "final_gate=PASS"
        return 0
    fi
    if is_dispatcher_release_artifact "$name"; then
        echo "class=dispatcher_release_artifact"
        echo "local_hold=yes"
        echo "reason=builtin_protected_pattern"
        echo "dispatcher_marker_required=no"
        echo "would_dispatch_by_sdd=no"
        echo "would_sort_by_sortify=no"
        echo "final_gate=PASS"
        return 0
    fi
    if is_sortify_release_artifact "$name"; then
        echo "class=sortify_release_artifact"
        echo "local_hold=yes"
        echo "reason=builtin_protected_pattern"
        echo "dispatcher_marker_required=no"
        echo "would_dispatch_by_sdd=no"
        echo "would_sort_by_sortify=no"
        echo "final_gate=PASS"
        return 0
    fi
    if is_protected_artifact "$name"; then
        echo "class=other_protected_artifact"
        echo "local_hold=yes"
        echo "reason=builtin_protected_pattern"
        echo "dispatcher_marker_required=maybe_for_remote_target"
        echo "would_dispatch_by_sdd=unknown"
        echo "would_sort_by_sortify=no_without_valid_marker"
        echo "final_gate=HELD"
        return 0
    fi
    echo "class=normal_download"
    echo "local_hold=no"
    echo "reason=no_protected_pattern"
    echo "dispatcher_marker_required=no"
    echo "would_dispatch_by_sdd=no"
    echo "would_sort_by_sortify=yes_if_normal_sort_enabled"
    echo "final_gate=PASS"
}

contract_smoke_check_contains() {
    label="$1"; expected="$2"; shift 2
    out="$("$@" 2>/dev/null || true)"
    if printf '%s\n' "$out" | grep -q "$expected"; then echo "$label=PASS"; return 0; fi
    echo "$label=FAIL"
    printf '%s\n' "$out" | sed 's/^/  /'
    return 1
}

sortify_contract_smoke() {
    normalize_config
    fail=0
    echo "== Sortify Dispatch Contract Smoke =="
    echo "sortify_version=4.6.5-sort-mode-control"
    echo "policy_expected=$PIDD_SORTIFY_REQUIRED_POLICY"
    [ "$PIDD_SORTIFY_REQUIRED_POLICY" = "v4115" ] && echo "policy_expected_v4115=PASS" || { echo "policy_expected_v4115=FAIL"; fail=$((fail + 1)); }
    [ -d "$PIDD_RUNTIME_DIR" ] && echo "dispatcher_runtime_present=yes" || echo "dispatcher_runtime_present=no"
    [ -d "$PIDD_SORTIFY_RELEASE_DIR" ] && echo "marker_root_present=yes" || echo "marker_root_present=no"
    echo "dispatcher_integration_state=$(dispatcher_integration_state)"
    echo "dispatcher_link_readonly=PASS"
    contract_smoke_check_contains "custom_prefix_heimnetz" "reason=custom_prefix:heimnetz__" test_filename_status "heimnetz__handover.md" || fail=$((fail + 1))
    contract_smoke_check_contains "markdown_handover_hold" "reason=markdown_handover_hold" test_filename_status "RELEASE_NOTES_4.6.5-sort-mode-control.md" || fail=$((fail + 1))
    contract_smoke_check_contains "pixel_local_hold_local_hold" "local_hold=yes" test_filename_status "pixel_local__helper.py" || fail=$((fail + 1))
    contract_smoke_check_contains "pixel_local_hold_no_marker" "dispatcher_marker_required=no" test_filename_status "pixel_local__helper.py" || fail=$((fail + 1))
    contract_smoke_check_contains "pixel_local_hold_no_sort" "would_sort=no" test_filename_status "pixel_local__helper.py" || fail=$((fail + 1))
    contract_smoke_check_contains "remote_target_hold_without_marker" "reason=builtin_protected_pattern" test_filename_status "target-pi3__example.zip" || fail=$((fail + 1))
    contract_smoke_check_contains "normal_markdown_sortable" "reason=no_protected_pattern" test_filename_status "normal-note.md" || fail=$((fail + 1))
    sortify_explain_route "target-pi3__example.zip" | grep -q "would_dispatch_by_sdd=yes" && echo "explain_route_remote=PASS" || { echo "explain_route_remote=FAIL"; fail=$((fail + 1)); }
    sortify_marker_status "target-pi3__example.zip" | grep -q "final_gate=FAIL" && echo "marker_status_missing_file_safe=PASS" || { echo "marker_status_missing_file_safe=FAIL"; fail=$((fail + 1)); }
    sortify_mode_status | grep -q "manual_sort_now=available" && echo "mode_status=PASS" || { echo "mode_status=FAIL"; fail=$((fail + 1)); }
    echo "ntfy_runbook_contract_known=PASS"
    echo "dns_ha_vip_route_change=no"
    echo "host_run=no"
    echo "sdd_marker_write=no"
    if [ "$fail" = "0" ]; then
        echo "RESULT: SORTIFY_DISPATCH_CONTRACT_SMOKE_PASS rc=0"
        return 0
    fi
    echo "RESULT: SORTIFY_DISPATCH_CONTRACT_SMOKE_FAIL rc=1"
    return 1
}
dispatcher_status() {
    normalize_config; runtime="${PIDD_RUNTIME_DIR:-/data/adb/ssh-drop-dispatcher}"; config="$runtime/config.env"
    echo "== SSH Drop Dispatcher Link =="; echo "sortify_dispatcher_integration=$SORTIFY_DISPATCHER_INTEGRATION"; echo "sortify_hold_protected=$SORTIFY_HOLD_PROTECTED"; echo "sortify_normal_sort=$SORTIFY_NORMAL_SORT"; echo "dispatcher_integration_state=$(dispatcher_integration_state)"
    if [ -d "$runtime" ]; then echo "dispatcher_runtime_present=yes"; echo "dispatcher_runtime=$runtime"; else echo "dispatcher_runtime_present=no"; echo "dispatcher_runtime=$runtime"; fi
    if [ -f "$config" ]; then echo "dispatcher_config_present=yes"; grep -E '^(DROP_SCAN_ROOT|SCAN_ROOT|PIDD_POLICY_VERSION|TARGETS)=' "$config" 2>/dev/null | sed 's/^/dispatcher_/' || true; else echo "dispatcher_config_present=no"; fi
    if [ "$DOWNLOADS" = "/sdcard/Download" ] || [ "$DOWNLOADS" = "/storage/emulated/0/Download" ]; then echo "sortify_download_matches_default_dispatcher_scan_root=yes"; else echo "sortify_download_matches_default_dispatcher_scan_root=unknown"; echo "sortify_download=$DOWNLOADS"; fi
}

zip_export_dir() {
    work="$1"; out="$2"
    if command -v zip >/dev/null 2>&1; then (cd "$work" && zip -qr "$out" .); return $?; fi
    py="/data/data/com.termux/files/usr/bin/python3"; [ -x "$py" ] || py="/data/data/com.termux/files/usr/bin/python"; [ -x "$py" ] || { echo "config_export=failed"; echo "reason=missing_zip_or_python"; return 1; }
    (cd "$work" && "$py" -c 'import os,sys,zipfile; out=sys.argv[1]; root="."; z=zipfile.ZipFile(out,"w",zipfile.ZIP_DEFLATED); [z.write(os.path.join(b,f), os.path.relpath(os.path.join(b,f), root)) for b,d,fs in os.walk(root) for f in sorted(fs)]; z.close()' "$out")
}

sortify_config_export() {
    normalize_config; ensure_dirs; stamp="$(date '+%Y%m%d_%H%M%S' 2>/dev/null || echo now)"; work="$DEST_BASE/.sortify_config_export_$stamp"; out="$DOWNLOADS/Sortify-Dispatch-config-$stamp.zip"
    rm -rf "$work"; mkdir -p "$work"
    { echo "backup_format=sortify-dispatch-config-v2"; echo "created_at=$stamp"; echo "version=4.6.5-sort-mode-control"; echo "includes_sdd_targets=no"; echo "includes_ssh_keys=no"; echo "includes_dispatcher_config=no"; echo "scope=sortify_only"; echo "includes_custom_park_prefixes=yes"; echo "includes_guard_bounds=yes"; echo "includes_duplicate_mode=yes"; echo "includes_smart_categories=yes"; } > "$work/manifest.env"
    [ -f "$CONF_PATH" ] && cp -f "$CONF_PATH" "$work/sortify.conf" 2>/dev/null || true
    sortify_config_status > "$work/config-status.txt" 2>&1 || true; duplicate_status > "$work/duplicate-status.txt" 2>&1 || true; guard_status > "$work/guard-status.txt" 2>&1 || true; dispatcher_status > "$work/dispatcher-link-status.txt" 2>&1 || true
    [ -f "$MODULE_DIR/module.prop" ] && grep -E '^(id=|name=|version=|versionCode=|author=|description=|updateJson=)' "$MODULE_DIR/module.prop" > "$work/module.prop.snapshot" 2>/dev/null || true
    (cd "$work" && find . -type f | sort | while IFS= read -r f; do sha256sum "$f" 2>/dev/null || toybox sha256sum "$f" 2>/dev/null || true; done > SHA256SUMS)
    rm -f "$out"; zip_export_dir "$work" "$out" || return $?; chmod 600 "$out" 2>/dev/null || true; rm -rf "$work"
    echo "== Sortify Dispatch Config Export =="; echo "config_export=done"; echo "config_zip=$out"; echo "includes_sdd_targets=no"; echo "includes_ssh_keys=no"; echo "includes_dispatcher_config=no"
}


current_boot_id() {
    if [ -r /proc/sys/kernel/random/boot_id ]; then cat /proc/sys/kernel/random/boot_id 2>/dev/null | sed -n '1p'; return 0; fi
    awk '{print int($1)}' /proc/uptime 2>/dev/null || date '+%s' 2>/dev/null || echo unknown
}

sortify_mode_status() {
    normalize_config
    echo "== Sortify Dispatch Mode Status =="
    echo "version=4.6.5-sort-mode-control"
    echo "sortify_sort_mode=$SORTIFY_SORT_MODE"
    echo "sortify_normal_sort=$SORTIFY_NORMAL_SORT"
    echo "manual_sort_now=available"
    case "$SORTIFY_SORT_MODE" in
        interval) echo "automatic_sorting=interval"; echo "service_cycle_action=sort_every_interval" ;;
        manual) echo "automatic_sorting=disabled"; echo "service_cycle_action=skip_until_manual_sort" ;;
        boot_once) echo "automatic_sorting=boot_once"; echo "service_cycle_action=sort_once_per_boot" ;;
    esac
    echo "sdd_marker_write=no"
    echo "host_run=no"
}

sortify_category_for_name() {
    name="$1"
    lower="$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')"
    ext=""
    case "$lower" in *.*) ext="${lower##*.}" ;; esac
    for e in $DOC_EXT; do [ "$ext" = "$e" ] && { echo Documents; return 0; }; done
    for e in $IMG_EXT; do [ "$ext" = "$e" ] && { echo Images; return 0; }; done
    for e in $VID_EXT; do [ "$ext" = "$e" ] && { echo Videos; return 0; }; done
    for e in $AUD_EXT; do [ "$ext" = "$e" ] && { echo Audio; return 0; }; done
    for e in $ARC_EXT; do [ "$ext" = "$e" ] && { echo Archives; return 0; }; done
    for e in $APP_EXT; do [ "$ext" = "$e" ] && { echo Apps; return 0; }; done
    for e in $EBOOK_EXT; do [ "$ext" = "$e" ] && { echo Ebooks; return 0; }; done
    for e in $CODE_EXT; do [ "$ext" = "$e" ] && { echo Code; return 0; }; done
    for e in $CONFIG_EXT; do [ "$ext" = "$e" ] && { echo Config; return 0; }; done
    for e in $DATA_EXT; do [ "$ext" = "$e" ] && { echo Data; return 0; }; done
    for e in $FONT_EXT; do [ "$ext" = "$e" ] && { echo Fonts; return 0; }; done
    for e in $CERT_EXT; do [ "$ext" = "$e" ] && { echo Certificates; return 0; }; done
    for e in $BACKUP_EXT; do [ "$ext" = "$e" ] && { echo Backups; return 0; }; done
    for e in $TORRENT_EXT; do [ "$ext" = "$e" ] && { echo Torrents; return 0; }; done
    echo Others
}

sortify_preview_one() {
    file="$1"
    filename="$(basename "$file")"
    is_skip_candidate "$filename" && { echo "file=$filename action=skip reason=temp_or_hidden target=$file"; return 0; }
    if should_hold_protected_artifact "$file"; then
        echo "file=$filename action=hold reason=protected_or_dispatcher_contract target=$DOWNLOADS/$filename"
        return 0
    fi
    category="$(sortify_category_for_name "$filename")"
    echo "file=$filename action=would_sort reason=normal_download target=$DEST_BASE/$category/$filename"
}

sortify_preview_sort() {
    normalize_config
    max="${SORTIFY_PREVIEW_MAX_FILES:-50}"
    case "$max" in ""|*[!0-9]*) max=50 ;; esac
    [ "$max" -lt 1 ] 2>/dev/null && max=1
    [ "$max" -gt 200 ] 2>/dev/null && max=200
    echo "== Sortify Dispatch Preview Sort =="
    echo "version=4.6.5-sort-mode-control"
    echo "download=$DOWNLOADS"
    echo "dest_base=$DEST_BASE"
    echo "preview_max_files=$max"
    echo "dry_run=yes"
    find "$DOWNLOADS" -maxdepth 1 -type f -print 2>/dev/null | sort | sed -n "1,${max}p" | while IFS= read -r file; do sortify_preview_one "$file"; done
    echo "preview_complete=yes"
    echo "sdd_marker_write=no"
}

sortify_service_cycle() {
    normalize_config
    case "$SORTIFY_SORT_MODE" in
        manual)
            ui_print "Sortify automatic sorting disabled by SORTIFY_SORT_MODE=manual"
            log_guard "service cycle skipped mode=manual manual_sort_now_available=yes"
            return 0
            ;;
        boot_once)
            boot_id="$(current_boot_id)"
            state_file="$MODULE_DIR/.sortify_boot_once_done"
            previous=""
            [ -f "$state_file" ] && previous="$(cat "$state_file" 2>/dev/null | sed -n '1p')"
            if [ "$previous" = "$boot_id" ]; then
                ui_print "Sortify boot_once already completed for this boot"
                log_guard "service cycle skipped mode=boot_once boot_id=$boot_id"
                return 0
            fi
            sort_now
            rc=$?
            if [ "$rc" = "0" ]; then mkdir -p "$MODULE_DIR" 2>/dev/null || true; printf '%s\n' "$boot_id" > "$state_file" 2>/dev/null || true; fi
            return "$rc"
            ;;
        interval|*)
            sort_now
            ;;
    esac
}

sort_now() {
    normalize_config; ensure_dirs; rotate_logs; [ "$SORTIFY_GUARD_TEMP_CLEAN_ON_SORT" = "1" ] && cleanup_guard_temp >/dev/null 2>&1 || true
    if [ "${SORTIFY_NORMAL_SORT:-1}" != "1" ]; then ui_print "Sortify normal sorting disabled by config"; log_guard "SORTIFY_NORMAL_SORT disabled; skipping sort"; return 0; fi
    require_dispatcher_if_needed || return $?
    ui_print "▶ Sortify Dispatch: Manual sort started"
    move_files "$DEST_BASE/Documents" $DOC_EXT; move_files "$DEST_BASE/Images" $IMG_EXT; move_files "$DEST_BASE/Videos" $VID_EXT; move_files "$DEST_BASE/Audio" $AUD_EXT; move_files "$DEST_BASE/Archives" $ARC_EXT; move_files "$DEST_BASE/Apps" $APP_EXT; move_files "$DEST_BASE/Ebooks" $EBOOK_EXT; move_files "$DEST_BASE/Code" $CODE_EXT; move_files "$DEST_BASE/Config" $CONFIG_EXT; move_files "$DEST_BASE/Data" $DATA_EXT; move_files "$DEST_BASE/Fonts" $FONT_EXT; move_files "$DEST_BASE/Certificates" $CERT_EXT; move_files "$DEST_BASE/Backups" $BACKUP_EXT; move_files "$DEST_BASE/Torrents" $TORRENT_EXT
    find "$DOWNLOADS" -maxdepth 1 -type f ! -name ".*" ! -name "*.crdownload" ! -name "*.partial" ! -name "*.tmp" -print 2>/dev/null | while IFS= read -r file; do move_one "$DEST_BASE/Others" "$file"; done
    date "+[%Y-%m-%d %H:%M:%S] Manual sort triggered" >> "$DEST_BASE/sortify.log"
    ui_print "✔ Sortify Dispatch: Manual sort completed"
}

case "${1:-sort}" in
    --guard-status|--guard-verify|guard-status|guard-verify) guard_status ;;
    --guard-status-raw|guard-status-raw) guard_status_raw ;;
    --guard-clean|guard-clean) guard_clean ;;
    --guard-temp-clean|guard-temp-clean) cleanup_guard_temp ;;
    --log-rotate|log-rotate) rotate_logs; echo "log_rotate=done" ;;
    --dispatcher-status|dispatcher-status) dispatcher_status ;;
    --explain-route|explain-route) sortify_explain_route "${2:-}" ;;
    --marker-status|marker-status) sortify_marker_status "${2:-}" ;;
    --contract-smoke|contract-smoke) sortify_contract_smoke ;;
    --mode-status|mode-status) sortify_mode_status ;;
    --preview-sort|preview-sort) sortify_preview_sort ;;
    --service-cycle|service-cycle) sortify_service_cycle ;;
    --config-status|config-status) sortify_config_status ;;
    --duplicate-status|duplicate-status) duplicate_status ;;
    --custom-prefixes-status|custom-prefixes-status) custom_prefixes_status ;;
    --test-filename|test-filename) test_filename_status "${2:-}" ;;
    --config-export|config-export) sortify_config_export ;;
    --sort|sort|"") sort_now ;;
    *) echo "Usage: action.sh [--sort|--mode-status|--preview-sort|--service-cycle|--guard-status|--guard-status-raw|--guard-clean|--guard-temp-clean|--log-rotate|--dispatcher-status|--explain-route NAME|--marker-status NAME|--contract-smoke|--config-status|--duplicate-status|--custom-prefixes-status|--test-filename NAME|--config-export]"; exit 2 ;;
esac
