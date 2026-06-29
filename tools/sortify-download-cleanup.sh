#!/usr/bin/env bash
set -euo pipefail

SOURCE="${SORTIFY_CLEANUP_SOURCE:-/storage/emulated/0/Download}"
WORK_ROOT="${SORTIFY_CLEANUP_WORK_ROOT:-/storage/emulated/0/Download/pixel_local__repo-helper-work/sortify-download-cleanup}"
RUN_ID="${SORTIFY_CLEANUP_RUN_ID:-$(date +%Y%m%d_%H%M%S)}"
RUN_DIR="${SORTIFY_CLEANUP_RUN_DIR:-$WORK_ROOT/run_$RUN_ID}"
ARCHIVE_ROOT="${SORTIFY_CLEANUP_ARCHIVE_ROOT:-/storage/emulated/0/Download/pixel_local__sortify-archive}"
ARCHIVE_DIR="${SORTIFY_CLEANUP_ARCHIVE_DIR:-$ARCHIVE_ROOT/archive_$RUN_ID}"
ITEMS_DIR="$ARCHIVE_DIR/items"

mkdir -p "$RUN_DIR"

is_git_worktree() {
  local p="$1"
  [ -d "$p/.git" ]
}

protected_name() {
  local name="$1" path="$2"
  case "$name" in
    .*) return 0 ;;
    pixel_local__*) return 0 ;;
    heimnetz__*) return 0 ;;
    target-*__*) return 0 ;;
    targets-*__*) return 0 ;;
    .work|.pidd-quarantine|.00_live_slot.state|.zip) return 0 ;;
    WhatsApp|Telegram|"Quick Share"|CHECK24|Nagram|Turrit|"WA Call Recordings"|WaEnhancerX|docs|files|fitbit) return 0 ;;
    pidd-smoke-hold|pixel_local_hold*|*live*anchor*|*current*|*active*|*hold*) return 0 ;;
  esac
  if [ -d "$path" ] && is_git_worktree "$path"; then return 0; fi
  return 1
}

stale_review_name() {
  local name="$1" path="$2"
  case "$name" in
    pixel_local__repo-helper-work|pixel_local__sortify-archive) return 1 ;;
    pixel_local__*rollback*|pixel_local__*backup*|pixel_local__*evidence*) return 1 ;;
    pixel_local__*.zip|pixel_local__*.py|pixel_local__*.sh|pixel_local__*.md|pixel_local__*.txt|pixel_local__*.log) return 0 ;;
  esac
  return 1
}

review_name() {
  local name="$1"
  case "$name" in
    Redmi_Buds_6_Play_M2420E1_Wavelet_AutoEQ_estimated_profiles|TS-DoH-DoT-BypassBlock-V5_4_3|hhh|hhhb) return 0 ;;
  esac
  return 1
}

safe_name() {
  local name="$1" path="$2"
  case "$name" in
    Sortify-Dispatch-v*.zip|ssh-drop-dispatcher-magisk_v*.zip|pixel-drop-dispatch*.zip) return 0 ;;
    handover_*.md|mini_handover_*.md|magisk_install_log_*.log|pixel_thermal_*.txt) return 0 ;;
    __pycache__) return 0 ;;
    *.sha256) return 0 ;;
  esac
  if [ -d "$path" ]; then
    case "$name" in
      *_20[0-9][0-9][0-9][0-9][0-9][0-9]*|run_20[0-9][0-9][0-9][0-9][0-9][0-9]*|release_*|evidence_*) return 0 ;;
    esac
  fi
  return 1
}

classify_one() {
  local path="$1" name
  name="$(basename "$path")"
  if protected_name "$name" "$path"; then printf '%s\tprotected\tprotected_name\t%s\n' "$name" "$path"; return 0; fi
  if review_name "$name"; then printf '%s\treview\treview_policy_name\t%s\n' "$name" "$path"; return 0; fi
  if safe_name "$name" "$path"; then printf '%s\tsafe\tsafe_policy_name\t%s\n' "$name" "$path"; return 0; fi
  printf '%s\tprotected\tdefault_protect\t%s\n' "$name" "$path"
}

write_stale_review() {
  local out="$1"
  printf 'name\tclass\treason\tpath\n' > "$out"
  find "$SOURCE" -mindepth 1 -maxdepth 1 -print 2>/dev/null | sort | while IFS= read -r path; do
    [ -e "$path" ] || continue
    local name
    name="$(basename "$path")"
    if stale_review_name "$name" "$path"; then
      printf '%s\tstale_review\tpixel_local_review_only\t%s\n' "$name" "$path" >> "$out"
    fi
  done
}

scan_cmd() {
  mkdir -p "$RUN_DIR"
  : > "$RUN_DIR/index.tsv.tmp"
  printf 'name\tclass\treason\tpath\n' > "$RUN_DIR/index.tsv.tmp"
  find "$SOURCE" -mindepth 1 -maxdepth 1 -print 2>/dev/null | sort | while IFS= read -r path; do
    [ -e "$path" ] || continue
    classify_one "$path" >> "$RUN_DIR/index.tsv.tmp"
  done
  mv "$RUN_DIR/index.tsv.tmp" "$RUN_DIR/index.tsv"
  awk -F '\t' 'NR==1 || $2=="safe"' "$RUN_DIR/index.tsv" > "$RUN_DIR/safe_candidates.tsv"
  awk -F '\t' 'NR==1 || $2=="review"' "$RUN_DIR/index.tsv" > "$RUN_DIR/review_candidates.tsv"
  awk -F '\t' 'NR==1 || $2=="protected"' "$RUN_DIR/index.tsv" > "$RUN_DIR/protected.tsv"
  write_stale_review "$RUN_DIR/stale_review_candidates.tsv"
  indexed=$(( $(wc -l < "$RUN_DIR/index.tsv") - 1 ))
  safe=$(( $(wc -l < "$RUN_DIR/safe_candidates.tsv") - 1 ))
  review=$(( $(wc -l < "$RUN_DIR/review_candidates.tsv") - 1 ))
  protected=$(( $(wc -l < "$RUN_DIR/protected.tsv") - 1 ))
  stale_review=$(( $(wc -l < "$RUN_DIR/stale_review_candidates.tsv") - 1 ))
  echo "== Sortify Download Cleanup Scan =="
  echo "source=$SOURCE"
  echo "run=$RUN_DIR"
  echo "indexed=$indexed"
  echo "safe=$safe"
  echo "review=$review"
  echo "protected=$protected"
  echo "stale_review=$stale_review"
  echo "RESULT: SORTIFY_DOWNLOAD_SAFE_SCAN_DONE rc=0"
}

guard_cmd() {
  test -f "$RUN_DIR/safe_candidates.tsv"
  echo "== suspicious inside safe list =="
  awk -F '\t' 'NR>1 {print $1}' "$RUN_DIR/safe_candidates.tsv" | grep -E '^(\.|pixel_local__|heimnetz__|target-|targets-)|work|live|active|current|state|slot|quarantine|pidd|dispatch|hold|WhatsApp|Telegram|Quick Share|CHECK24|Nagram|Turrit|WA Call Recordings|WaEnhancerX|docs|files|fitbit' > "$RUN_DIR/guard_suspicious.txt" || true
  if [ -s "$RUN_DIR/guard_suspicious.txt" ]; then
    cat "$RUN_DIR/guard_suspicious.txt"
    echo "RESULT: SORTIFY_SAFE_LIST_GUARD_FAIL rc=1"
    exit 1
  fi
  date +%s > "$RUN_DIR/guard.pass"
  echo "RESULT: SORTIFY_SAFE_LIST_GUARD_DONE rc=0"
}

archive_safe_cmd() {
  test -f "$RUN_DIR/safe_candidates.tsv"
  test -f "$RUN_DIR/guard.pass"
  mkdir -p "$ITEMS_DIR"
  local manifest="$RUN_DIR/archive_manifest.tsv" rollback="$RUN_DIR/rollback_$RUN_ID.sh"
  printf 'name\tsource\tdestination\n' > "$manifest"
  awk -F '\t' 'NR>1 {print $1 "\t" $4}' "$RUN_DIR/safe_candidates.tsv" | while IFS="$(printf '\t')" read -r name source_path; do
    [ -n "$name" ] || continue
    [ -e "$source_path" ] || continue
    dest="$ITEMS_DIR/$name"
    if [ -e "$dest" ]; then
      echo "archive_dest_exists=$dest"
      exit 30
    fi
    mv "$source_path" "$dest"
    printf '%s\t%s\t%s\n' "$name" "$source_path" "$dest" >> "$manifest"
  done
  {
    echo '#!/usr/bin/env bash'
    echo 'set -euo pipefail'
    echo 'manifest="'"$manifest"'"'
    echo 'tail -n +2 "$manifest" | while IFS="$(printf '\''\\t'\'')" read -r name source destination; do'
    echo '  [ -n "$name" ] || continue'
    echo '  if [ -e "$source" ]; then echo "restore_skip_source_exists=$source"; continue; fi'
    echo '  mkdir -p "$(dirname "$source")"'
    echo '  mv "$destination" "$source"'
    echo '  echo "restored=$source"'
    echo 'done'
  } > "$rollback"
  chmod 0755 "$rollback"
  echo "archive=$ARCHIVE_DIR"
  echo "items=$ITEMS_DIR"
  echo "run=$RUN_DIR"
  echo "manifest=$manifest"
  echo "rollback=$rollback"
  echo "RESULT: SORTIFY_DOWNLOAD_ARCHIVE_SAFE_DONE rc=0"
}

verify_cmd() {
  local manifest="$RUN_DIR/archive_manifest.tsv" rollback
  rollback="$(find "$RUN_DIR" -maxdepth 1 -name 'rollback_*.sh' | sort | tail -1 || true)"
  test -d "$ARCHIVE_DIR" && echo "PASS: archive dir present"
  test -d "$ITEMS_DIR" && echo "PASS: items dir present"
  test -f "$manifest" && echo "PASS: manifest present"
  test -n "$rollback" && test -f "$rollback" && echo "PASS: rollback present"
  bash -n "$rollback"
  top_level_items="$(find "$ITEMS_DIR" -mindepth 1 -maxdepth 1 -print 2>/dev/null | wc -l | tr -d ' ')"
  manifest_lines="$(wc -l < "$manifest" | tr -d ' ')"
  echo "top_level_items=$top_level_items"
  echo "manifest_lines=$manifest_lines"
  if [ "$manifest_lines" -ne $(( top_level_items + 1 )) ]; then
    echo "RESULT: SORTIFY_ARCHIVE_SAFE_FINAL_VERIFY_FAIL rc=1"
    exit 1
  fi
  echo "RESULT: SORTIFY_ARCHIVE_SAFE_FINAL_VERIFY_DONE rc=0"
}

rollback_info_cmd() {
  local run="$RUN_DIR"
  if [ ! -d "$run" ]; then
    run="$(find "$WORK_ROOT" -mindepth 1 -maxdepth 1 -type d -name 'run_*' 2>/dev/null | sort | tail -1 || true)"
  fi
  if [ -z "$run" ] || [ ! -d "$run" ]; then
    echo "rollback_info=none"
    echo "RESULT: SORTIFY_DOWNLOAD_ROLLBACK_INFO_DONE rc=0"
    return 0
  fi
  local manifest rollback archive items
  manifest="$run/archive_manifest.tsv"
  rollback="$(find "$run" -maxdepth 1 -name 'rollback_*.sh' | sort | tail -1 || true)"
  archive=""
  items=""
  if [ -f "$manifest" ]; then
    items="$(awk -F '\t' 'NR==2 {print $3}' "$manifest" | sed 's#/items/.*#/items#')"
    archive="$(dirname "$items")"
  fi
  echo "run=$run"
  echo "manifest=$manifest"
  echo "rollback=$rollback"
  echo "archive=$archive"
  echo "items=$items"
  if [ -f "$manifest" ]; then echo "manifest_lines=$(wc -l < "$manifest" | tr -d ' ')"; fi
  if [ -n "$rollback" ] && [ -f "$rollback" ]; then bash -n "$rollback" && echo "rollback_syntax=PASS"; fi
  echo "RESULT: SORTIFY_DOWNLOAD_ROLLBACK_INFO_DONE rc=0"
}

archive_review_approved_dry_run_cmd() {
  if [ -z "${SORTIFY_CLEANUP_RUN_ID:-}" ] && [ -z "${SORTIFY_CLEANUP_RUN_DIR:-}" ]; then
    echo "archive_review_exact_run=FAIL"
    echo "RESULT: SORTIFY_ARCHIVE_REVIEW_APPROVED_DRY_RUN_FAIL rc=31"
    exit 31
  fi
  if [ "${SORTIFY_CLEANUP_APPROVED_FOR_ARCHIVE:-no}" != "yes" ]; then
    echo "approved_for_archive=no"
    echo "RESULT: SORTIFY_ARCHIVE_REVIEW_APPROVED_DRY_RUN_APPROVAL_REQUIRED rc=32"
    exit 32
  fi

  local preview="${SORTIFY_CLEANUP_APPROVAL_PREVIEW:-$RUN_DIR/stale_review_approval_preview/approval_preview.tsv}"
  local planned="${SORTIFY_CLEANUP_PLANNED_MANIFEST:-$RUN_DIR/planned_review_archive_manifest.tsv}"
  local review_archive="${SORTIFY_CLEANUP_REVIEW_ARCHIVE_DIR:-$ARCHIVE_ROOT/review_archive_$RUN_ID}"
  local review_items="$review_archive/items"
  local invalid="$RUN_DIR/archive_review_invalid_candidates.tsv"
  local missing="$RUN_DIR/archive_review_missing_sources.tsv"
  local dupes="$RUN_DIR/archive_review_duplicate_destinations.tsv"
  local tmp="$planned.tmp"

  test -f "$preview"
  awk -F '	' 'NR==1 && $1=="decision" && $2=="bucket" && $5=="name" && $7=="path" {ok=1} END {exit ok ? 0 : 1}' "$preview"

  awk -F '	' 'NR>1 && $1=="candidate_for_manual_archive_review" && $2!="A_temp_helper_scripts" && $2!="C_logs_boot_watch_thermal_txt" {print}' "$preview" > "$invalid"
  if [ -s "$invalid" ]; then
    echo "archive_review_invalid_candidates=FAIL"
    cat "$invalid"
    echo "RESULT: SORTIFY_ARCHIVE_REVIEW_APPROVED_DRY_RUN_FAIL rc=33"
    exit 33
  fi

  : > "$missing"
  printf 'name	source	destination	bucket	decision
' > "$tmp"
  tail -n +2 "$preview" | while IFS="$(printf '	')" read -r decision bucket family extension name reason path note; do
    [ "$decision" = "candidate_for_manual_archive_review" ] || continue
    case "$name" in ""|*/*) echo "$name" >> "$missing"; continue ;; esac
    if [ ! -e "$path" ]; then
      printf '%s	%s
' "$name" "$path" >> "$missing"
      continue
    fi
    dest="$review_items/$name"
    printf '%s	%s	%s	%s	%s
' "$name" "$path" "$dest" "$bucket" "$decision" >> "$tmp"
  done

  if [ -s "$missing" ]; then
    echo "archive_review_missing_sources=FAIL"
    cat "$missing"
    echo "RESULT: SORTIFY_ARCHIVE_REVIEW_APPROVED_DRY_RUN_FAIL rc=34"
    exit 34
  fi

  awk -F '	' 'NR>1 {c[$3]++; if (c[$3] == 2) print $3}' "$tmp" > "$dupes"
  if [ -s "$dupes" ]; then
    echo "archive_review_duplicate_destinations=FAIL"
    cat "$dupes"
    echo "RESULT: SORTIFY_ARCHIVE_REVIEW_APPROVED_DRY_RUN_FAIL rc=35"
    exit 35
  fi

  mv "$tmp" "$planned"
  candidate_count=$(( $(wc -l < "$planned") - 1 ))
  hold_count="$(awk -F '	' 'NR>1 && $1=="hold" {c++} END {print c+0}' "$preview")"
  echo "archive_review_mode=dry-run"
  echo "approved_for_archive=yes"
  echo "run=$RUN_DIR"
  echo "approval_preview=$preview"
  echo "planned_manifest=$planned"
  echo "archive=$review_archive"
  echo "items=$review_items"
  echo "candidate_for_manual_archive_review=$candidate_count"
  echo "hold=$hold_count"
  echo "archive_safe=no"
  echo "file_move=no"
  echo "RESULT: SORTIFY_ARCHIVE_REVIEW_APPROVED_DRY_RUN_DONE rc=0"
}

case "${1:-}" in
  scan) scan_cmd ;;
  guard) guard_cmd ;;
  archive-safe) archive_safe_cmd ;;
  verify) verify_cmd ;;
  rollback-info) rollback_info_cmd ;;
  archive-review-approved)
    case "${2:-}" in
      dry-run) archive_review_approved_dry_run_cmd ;;
      *) echo "Usage: sortify-download-cleanup.sh archive-review-approved dry-run"; exit 2 ;;
    esac
    ;;
  *) echo "Usage: sortify-download-cleanup.sh scan|guard|archive-safe|verify|rollback-info|archive-review-approved dry-run"; exit 2 ;;
esac
