#!/usr/bin/env bash
set -euo pipefail

SOURCE="${SORTIFY_CLEANUP_SOURCE:-/storage/emulated/0/Download}"
ARCHIVE_ROOT="${SORTIFY_CLEANUP_ARCHIVE_ROOT:-$SOURCE/pixel_local__sortify-archive}"
WORK_ROOT="${SORTIFY_CLEANUP_WORK_ROOT:-$SOURCE/pixel_local__repo-helper-work/sortify-download-cleanup}"
RUN_ID="${SORTIFY_CLEANUP_RUN_ID:-$(date +%Y%m%d_%H%M%S)}"
RUN_DIR="${SORTIFY_CLEANUP_RUN_DIR:-$WORK_ROOT/run_$RUN_ID}"
LATEST_PATH="$WORK_ROOT/latest-run.path"
mkdir -p "$WORK_ROOT"

active_folder_name() {
    case "$1" in
        WhatsApp|Telegram|"Quick Share"|CHECK24|Nagram|Turrit|"WA Call Recordings"|WaEnhancerX|docs|files|fitbit) return 0 ;;
    esac
    return 1
}

protected_name() {
    name="$1"
    case "$name" in
        ""|.*|.work|.pidd-quarantine|.00_live_slot.state|.zip) return 0 ;;
        pixel_local__*|heimnetz__*|target-*__*|targets-*__*) return 0 ;;
        pidd-smoke-hold*|pixel_local_hold*|*live*anchor*|*current*|*active*|*hold*) return 0 ;;
    esac
    active_folder_name "$name" && return 0
    return 1
}

review_name() {
    case "$1" in
        Redmi_Buds_6_Play_M2420E1_Wavelet_AutoEQ_estimated_profiles|TS-DoH-DoT-BypassBlock-V5_4_3|hhh|hhhb) return 0 ;;
    esac
    return 1
}

safe_name() {
    name="$1"
    case "$name" in
        Sortify-Dispatch-v*.zip|ssh-drop-dispatcher*.zip|pixel-drop-dispatch*.zip|mrt-dev*.zip|mrt-dev*.zip.sha256) return 0 ;;
        handover_*.md|mini_handover_*.md|magisk_install_log_*.log|pixel_thermal_*.txt) return 0 ;;
        __pycache__) return 0 ;;
    esac
    return 1
}

classify_entry() {
    path="$1"
    name="$(basename "$path")"
    if [ -d "$path/.git" ]; then printf '%s\tprotected\tgit_worktree\t%s\n' "$name" "$path"; return 0; fi
    if protected_name "$name"; then printf '%s\tprotected\tprotected_name\t%s\n' "$name" "$path"; return 0; fi
    if review_name "$name"; then printf '%s\treview\treview_policy_name\t%s\n' "$name" "$path"; return 0; fi
    if safe_name "$name"; then printf '%s\tsafe\tsafe_policy_name\t%s\n' "$name" "$path"; return 0; fi
    printf '%s\tprotected\tdefault_protect\t%s\n' "$name" "$path"
}

scan_cmd() {
    mkdir -p "$RUN_DIR"
    printf '%s\n' "$RUN_DIR" > "$LATEST_PATH"
    index="$RUN_DIR/index.tsv"
    safe="$RUN_DIR/safe_candidates.tsv"
    review="$RUN_DIR/review_candidates.tsv"
    protected="$RUN_DIR/protected.tsv"
    printf 'name\tclass\treason\tpath\n' > "$index"
    printf 'name\tclass\treason\tpath\n' > "$safe"
    printf 'name\tclass\treason\tpath\n' > "$review"
    printf 'name\tclass\treason\tpath\n' > "$protected"
    if [ -d "$SOURCE" ]; then
        find "$SOURCE" -mindepth 1 -maxdepth 1 -print 2>/dev/null | sort | while IFS= read -r entry; do
            line="$(classify_entry "$entry")"
            printf '%s\n' "$line" >> "$index"
            cls="$(printf '%s\n' "$line" | awk -F '\t' '{print $2}')"
            case "$cls" in
                safe) printf '%s\n' "$line" >> "$safe" ;;
                review) printf '%s\n' "$line" >> "$review" ;;
                *) printf '%s\n' "$line" >> "$protected" ;;
            esac
        done
    fi
    indexed=$(( $(wc -l < "$index") - 1 ))
    safe_count=$(( $(wc -l < "$safe") - 1 ))
    review_count=$(( $(wc -l < "$review") - 1 ))
    protected_count=$(( $(wc -l < "$protected") - 1 ))
    echo "== Sortify Download Cleanup Scan =="
    echo "source=$SOURCE"
    echo "run=$RUN_DIR"
    echo "indexed=$indexed"
    echo "safe=$safe_count"
    echo "review=$review_count"
    echo "protected=$protected_count"
    echo "RESULT: SORTIFY_DOWNLOAD_SAFE_SCAN_DONE rc=0"
}

latest_run_dir() {
    if [ -n "${SORTIFY_CLEANUP_RUN_DIR:-}" ]; then printf '%s\n' "$SORTIFY_CLEANUP_RUN_DIR"; return 0; fi
    if [ -f "$LATEST_PATH" ]; then sed -n '1p' "$LATEST_PATH"; return 0; fi
    echo "latest_run_missing" >&2
    return 1
}

guard_cmd() {
    run="$(latest_run_dir)"
    safe="$run/safe_candidates.tsv"
    test -f "$safe"
    suspicious="$run/suspicious_safe.tsv"
    awk -F '\t' 'NR>1 {print $1}' "$safe" | grep -E '^(\.|pixel_local__|heimnetz__|target-|targets-)|(^|.*)(work|live|active|current|state|slot|quarantine|pidd|dispatch|hold)(.*)$|^(WhatsApp|Telegram|Quick Share|CHECK24|Nagram|Turrit|WA Call Recordings|WaEnhancerX|docs|files|fitbit)$' > "$suspicious" || true
    echo "== suspicious inside safe list =="
    if [ -s "$suspicious" ]; then
        cat "$suspicious"
        echo "RESULT: SORTIFY_SAFE_LIST_GUARD_FAIL rc=1"
        return 1
    fi
    : > "$run/guard.pass"
    echo "RESULT: SORTIFY_SAFE_LIST_GUARD_DONE rc=0"
}

archive_safe_cmd() {
    run="$(latest_run_dir)"
    safe="$run/safe_candidates.tsv"
    guard="$run/guard.pass"
    test -f "$safe"
    test -f "$guard"
    archive="$ARCHIVE_ROOT/archive_$RUN_ID"
    items="$archive/items"
    manifest="$run/archive_manifest.tsv"
    rollback="$run/rollback_$RUN_ID.sh"
    mkdir -p "$items"
    printf 'original_path\tarchive_path\tname\n' > "$manifest"
    awk -F '\t' 'NR>1 {print $1 "\t" $4}' "$safe" | while IFS=$(printf '\t') read -r name path; do
        [ -e "$path" ] || continue
        dest="$items/$name"
        if [ -e "$dest" ]; then dest="$items/${name}.$(date +%s)"; fi
        mv "$path" "$dest"
        printf '%s\t%s\t%s\n' "$path" "$dest" "$name" >> "$manifest"
    done
    printf '%s\n' '#!/usr/bin/env bash' > "$rollback"
    printf '%s\n' 'set -euo pipefail' >> "$rollback"
    printf '%s\n' 'manifest="${1:-archive_manifest.tsv}"' >> "$rollback"
    printf '%s\n' 'awk -F "\t" '\''NR>1 {print $1 "\t" $2}'\'' "$manifest" | while IFS=$(printf "\t") read -r src dst; do mkdir -p "$(dirname "$src")"; if [ -e "$dst" ] && [ ! -e "$src" ]; then mv "$dst" "$src"; fi; done' >> "$rollback"
    chmod 0755 "$rollback"
    echo "archive=$archive"
    echo "items=$items"
    echo "run=$run"
    echo "manifest=$manifest"
    echo "rollback=$rollback"
    echo "RESULT: SORTIFY_DOWNLOAD_ARCHIVE_SAFE_DONE rc=0"
}

verify_cmd() {
    run="$(latest_run_dir)"
    manifest="$run/archive_manifest.tsv"
    rollback="$(find "$run" -maxdepth 1 -name 'rollback_*.sh' | sort | tail -1)"
    test -f "$manifest"
    test -f "$rollback"
    bash -n "$rollback"
    archive="$(awk -F '\t' 'NR==2 {print $2}' "$manifest" | sed 's#/items/.*##')"
    items="$archive/items"
    test -d "$archive"
    test -d "$items"
    moved=$(( $(wc -l < "$manifest") - 1 ))
    top_level_items="$(find "$items" -mindepth 1 -maxdepth 1 -print 2>/dev/null | wc -l | tr -d ' ')"
    echo "PASS: archive dir present"
    echo "PASS: items dir present"
    echo "PASS: manifest present"
    echo "PASS: rollback present"
    echo "top_level_items=$top_level_items"
    echo "manifest_lines=$(wc -l < "$manifest")"
    test "$top_level_items" = "$moved"
    echo "RESULT: SORTIFY_ARCHIVE_SAFE_FINAL_VERIFY_DONE rc=0"
}

rollback_info_cmd() {
    run="$(latest_run_dir)"
    echo "run=$run"
    find "$run" -maxdepth 1 -name 'rollback_*.sh' -print | sort | tail -1 | sed 's/^/rollback=/'
    test -f "$run/archive_manifest.tsv" && echo "manifest=$run/archive_manifest.tsv"
    echo "RESULT: SORTIFY_DOWNLOAD_CLEANUP_ROLLBACK_INFO_DONE rc=0"
}

case "${1:-}" in
    scan) scan_cmd ;;
    guard) guard_cmd ;;
    archive-safe) archive_safe_cmd ;;
    verify) verify_cmd ;;
    rollback-info) rollback_info_cmd ;;
    *) echo "Usage: sortify-download-cleanup.sh scan|guard|archive-safe|verify|rollback-info"; exit 2 ;;
esac
