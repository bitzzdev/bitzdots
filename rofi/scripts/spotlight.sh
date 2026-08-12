#!/bin/bash
# Spotlight search (Spotlight-style launcher)
# ALT+SPACE -> search across:
#   - installed applications   (from .desktop entries, with their icons)
#   - files and folders        (recursive find under $HOME, with icons)
#   - the web                  (pick "Search the web" or just press Enter)
#
# Single rofi instance. The candidate list is generated once at launch; rofi
# filters it live (client-side, as you type). Each row is:
#     <dispatch-token>\0display\x1f<label>\0icon\x1f<icon>\0meta\x1f<terms>
# The entry text (before \0) is the dispatch token; rofi prints it on accept.
#
# rofi -format $'s\tf' outputs "<entry>\t<filter>", so:
#   - selecting a row      -> "<token>\t<typed-filter>"
#   - Enter with no match  -> "<typed-text>\t<typed-text>"  (custom input)
# The web row is "permanent" (always visible) and uses the filter part as the
# query. Bare Enter (no matching row) also falls back to web search.
#
# On-demand only: rofi exits when the menu closes; nothing keeps running.

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
ROFI_THEME="$CONFIG_DIR/rofi/themes/launcher.rasi"
DEFAULTS_FILE="$CONFIG_DIR/hypr/defaults.lua"

# --- Defaults (from hypr/defaults.lua) ---
browser="brave-origin"
file_explorer="nautilus"
if [ -f "$DEFAULTS_FILE" ]; then
    _v=$(sed -n 's/^BROWSER\s*=\s*"\(.*\)"/\1/p' "$DEFAULTS_FILE" | head -1)
    [ -n "$_v" ] && browser="$_v"
    _v=$(sed -n 's/^FILE_EXPLORER\s*=\s*"\(.*\)"/\1/p' "$DEFAULTS_FILE" | head -1)
    [ -n "$_v" ] && file_explorer="$_v"
fi
unset _v

if ! command -v rofi &>/dev/null; then
    notify-send -u critical "rofi not installed" "Spotlight search requires rofi"
    exit 1
fi

# --- Cleanup any previous rofi + stale pidfile lock (rofi refuses to start
# otherwise with "Failed to set lock on pidfile: Rofi already running?") ---
pkill -x rofi 2>/dev/null
ROFI_PIDFILE="/run/user/$(id -u)/rofi.pid"
[ -f "$ROFI_PIDFILE" ] && rm -f "$ROFI_PIDFILE" 2>/dev/null
sleep 0.05

# Browser icon (theme name) for the web row.
browser_icon=$(sed -n 's/^Icon=\(.*\)$/\1/p' "/usr/share/applications/$browser.desktop" 2>/dev/null | head -1)
[ -z "$browser_icon" ] && browser_icon="$browser"

# Icon for a file based on its extension.
file_icon() {
    case "${1##*.}" in
        png|jpg|jpeg|gif|svg|webp|bmp|ico|avif) echo "image-x-generic" ;;
        mp4|mkv|webm|avi|mov|mpg|mpeg|flv)       echo "video-x-generic" ;;
        mp3|wav|flac|ogg|m4a|opus|aac)           echo "audio-x-generic" ;;
        pdf)                                     echo "x-office-document" ;;
        zip|tar|gz|xz|bz2|7z|rar|zst)            echo "application-x-archive" ;;
        sh|py|js|ts|rs|go|c|cpp|h|rb|pl|fish)   echo "application-x-executable" ;;
        *)                                       echo "text-x-generic" ;;
    esac
}

# --- Build candidate list ---
build_list() {
    # 1. Web search (permanent row: always visible, never filtered out)
    printf 'web:\0display\x1fSearch the web\0meta\x1fgoogle search browser\0icon\x1f%s\x1fpermanent\x1ftrue\n' "$browser_icon"

    # 2. Installed applications
    for dir in /usr/share/applications "$HOME/.local/share/applications" \
               /usr/local/share/applications; do
        [ -d "$dir" ] || continue
        for desktop in "$dir"/*.desktop; do
            [ -f "$desktop" ] || continue
            grep -qi '^NoDisplay=true' "$desktop" && continue
            name=$(sed -n 's/^Name=\(.*\)$/\1/p' "$desktop" | head -1)
            exec_line=$(sed -n 's/^Exec=\(.*\)$/\1/p' "$desktop" | head -1)
            icon=$(sed -n 's/^Icon=\(.*\)$/\1/p' "$desktop" | head -1)
            [ -n "$name" ] && [ -n "$exec_line" ] || continue
            [ -n "$icon" ] || icon="application-x-executable"
            printf 'app:%s\0display\x1f%s\0icon\x1f%s\0meta\x1f%s %s\n' \
                "$exec_line" "$name" "$icon" "$name" "$exec_line"
        done
    done

    # 3. Folders
    find "$HOME" \
        \( -name ".cache" -o -name ".git" -o -name "node_modules" \
           -o -name "*.cache" -o -name ".thumbnails" -o -name ".*" \) -prune -o \
        -type d -print 2>/dev/null | while read -r d; do
        [ "$d" = "$HOME" ] && continue
        printf 'dir:%s\0display\x1f%s\0icon\x1ffolder\0meta\x1f%s\n' \
            "$d" "${d##*/}" "${d##*/}"
    done

    # 4. Files
    find "$HOME" \
        \( -name ".cache" -o -name ".git" -o -name "node_modules" \
           -o -name "*.cache" -o -name ".thumbnails" -o -name ".*" \) -prune -o \
        -type f -print 2>/dev/null | while read -r f; do
        printf 'file:%s\0display\x1f%s\0icon\x1f%s\0meta\x1f%s\n' \
            "$f" "${f##*/}" "$(file_icon "$f")" "${f##*/}"
    done
}

# --- Launch rofi (sync: build list fully, then show, live-filter) ---
out=$(build_list | rofi -dmenu -i -p "Spotlight" -sync \
    -theme "$ROFI_THEME" \
    -theme-str 'listview { columns: 1; lines: 12; spacing: 2px; padding: 6px; flow: vertical; } window { width: 620px; } element { orientation: horizontal; padding: 8px 12px; spacing: 12px; } element-icon { size: 22px; vertical-align: 0.5; } element-text { horizontal-align: 0; vertical-align: 0.5; text-color: @fg0; } entry { placeholder: "Search apps, files, folders or the web..."; }' \
    -format $'s\tf' -sep $'\n')

[ -z "$out" ] && exit 0

# --- Dispatch ---
entry="${out%%$'\t'*}"   # before first tab: dispatch token (or typed text)
filter="${out#*$'\t'}"   # after first tab: the typed filter

case "$entry" in
    web:)
        [ -n "$filter" ] || exit 0
        q=$(printf %s "$filter" | sed 's/ /+/g')
        "$browser" "https://www.google.com/search?q=$q"
        ;;
    app:*)
        cmd="${entry#app:}"
        cmd=$(printf %s "$cmd" | sed -e 's/%%/__PERCENT__/g' \
            -e 's/%[fFuUdDnNickvm]//g' -e 's/__PERCENT__/%/g')
        setsid sh -c "$cmd" >/dev/null 2>&1 &
        ;;
    dir:*)
        "$file_explorer" "${entry#dir:}"
        ;;
    file:*)
        "$file_explorer" --select "${entry#file:}" 2>/dev/null \
            || "$file_explorer" "$(dirname "${entry#file:}")"
        ;;
    *)
        # Custom input (Enter with no matching row) -> web search
        [ -n "$entry" ] || exit 0
        q=$(printf %s "$entry" | sed 's/ /+/g')
        "$browser" "https://www.google.com/search?q=$q"
        ;;
esac
