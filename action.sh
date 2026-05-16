#!/system/bin/sh
# Sortify Dispatch v4.0-artifact-guard - Manual Action

ui_print() {
    echo "$1"
}

ui_print "▶ Sortify Dispatch: Manual sort started"

DOWNLOADS="${DOWNLOADS:-/sdcard/Download}"
DEST_BASE="${DEST_BASE:-/sdcard/Sortify}"

mkdir -p "$DEST_BASE/Documents"          "$DEST_BASE/Images"          "$DEST_BASE/Videos"          "$DEST_BASE/Audio"          "$DEST_BASE/Archives"          "$DEST_BASE/Apps"          "$DEST_BASE/Others"          "$DEST_BASE/Duplicates"

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

    if is_protected_artifact "$filename"; then
        ui_print "KEEP artifact: $filename"
        return 0
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
        find "$DOWNLOADS" -maxdepth 1 -type f             ! -name ".*"             ! -name "*.crdownload"             ! -name "*.partial"             ! -name "*.tmp"             -iname "*.$ext" -print | while IFS= read -r file; do
                move_one "$dest" "$file"
            done
    done
}

move_files "$DEST_BASE/Documents" $DOC_EXT
move_files "$DEST_BASE/Images" $IMG_EXT
move_files "$DEST_BASE/Videos" $VID_EXT
move_files "$DEST_BASE/Audio" $AUD_EXT
move_files "$DEST_BASE/Archives" $ARC_EXT
move_files "$DEST_BASE/Apps" $APP_EXT

find "$DOWNLOADS" -maxdepth 1 -type f     ! -name ".*"     ! -name "*.crdownload"     ! -name "*.partial"     ! -name "*.tmp" -print | while IFS= read -r file; do
        move_one "$DEST_BASE/Others" "$file"
    done

if [ -d "$DEST_BASE" ]; then
    date "+[%Y-%m-%d %H:%M:%S] Manual sort triggered" >> "$DEST_BASE/sortify.log"
fi

ui_print "✔ Sortify Dispatch: Manual sort completed"
