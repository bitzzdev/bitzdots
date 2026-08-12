#!/bin/bash
# Spotlight search (Spotlight-style launcher)
# ALT+SPACE -> search across:
#   - installed applications    (matching .desktop entries)
#   - files and folders         (recursive find under $HOME)
#   - the web                   (opens default browser with the query)
#
# Two quick rofi prompts, on-demand only. No background daemon: rofi exits
# when the menu closes and nothing keeps running afterwards.
#
# Results carry metadata in the 2nd column (hidden with -display-columns 1),
# so the picked line can be dispatched reliably:
#   web: <query>          Search the web
#   app: <exec line>      Launch an application
#   dir: <path>           Open folder in the file explorer
#   file: <path>          Reveal file in the file explorer

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
ROFI_THEME="$CONFIG_DIR/rofi/themes/launcher.rasi"
DEFAULTS_FILE="$CONFIG_DIR/hypr/defaults.lua"

# --- Defaults (from hypr/defaults.lua) ---
browser="brave-origin"
file_explorer="nautilus"
if [ -f "$DEFAULTS_FILE" ]; then
    browser=$(sed -n 's/^BROWSER\s*=\s*"\(.*\)"/\1/p' "$DEFAULTS_FILE" | head -1) || browser="brave-origin"
    file_explorer=$(sed -n 's/^FILE_EXPLORER\s*=\s*"\(.*\)"/\1/p' "$DEFAULTS_FILE" | head -1) || file_explorer="nautilus"
fi
[ -z "$browser" ]       && browser="brave-origin"
[ -z "$file_explorer" ] && file_explorer="nautilus"

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

theme_str='listview { columns: 1; lines: 12; spacing: 2px; padding: 6px; flow: vertical; } window { width: 720px; } element { orientation: horizontal; padding: 8px 12px; spacing: 12px; } element-icon { size: 22px; vertical-align: 0.5; } element-text { horizontal-align: 0; vertical-align: 0.5; }'

# --- Stage 1: capture the query ---
query=$(rofi -dmenu -i -p "Spotlight" \
    -theme "$ROFI_THEME" \
    -theme-str "$theme_str")
[ -z "$query" ] && exit 0

# --- Build result list: web + apps + folders + files ---
results=$({
    # 1. Web search (always available)
    printf 'web: %s\tSearch the web: %s\n' "$query" "$query"

    # 2. Installed applications matching the query
    for dir in /usr/share/applications "$HOME/.local/share/applications" \
               /usr/local/share/applications; do
        [ -d "$dir" ] || continue
        grep -l -i -- "$query" "$dir"/*.desktop 2>/dev/null
    done | sort -u | while read -r desktop; do
        name=$(sed -n 's/^Name=\(.*\)$/\1/p' "$desktop" | head -1)
        exec_line=$(sed -n 's/^Exec=\(.*\)$/\1/p' "$desktop" | head -1)
        [ -n "$name" ] && [ -n "$exec_line" ] && printf 'app: %s\t%s\n' "$name" "$exec_line"
    done

    # 3. Folders matching the query
    find "$HOME" \
        \( -name ".cache" -o -name ".git" -o -name "node_modules" \
           -o -name "*.cache" -o -name ".thumbnails" -o -name "Wallpapers" \
           -o -name ".*" \) -prune -o \
        -type d -iname "*${query}*" -print 2>/dev/null | while read -r d; do
            printf 'dir: %s\t%s\n' "$d" "$d"
        done

    # 4. Files matching the query
    find "$HOME" \
        \( -name ".cache" -o -name ".git" -o -name "node_modules" \
           -o -name "*.cache" -o -name ".thumbnails" -o -name "Wallpapers" \
           -o -name ".*" \) -prune -o \
        -type f -iname "*${query}*" -print 2>/dev/null | while read -r f; do
            printf 'file: %s\t%s\n' "$f" "$f"
        done
} | head -80 | rofi -dmenu -i -p "Results" \
    -display-columns 1 \
    -theme "$ROFI_THEME" \
    -theme-str "$theme_str")

[ -z "$results" ] && exit 0

# --- Dispatch on the metadata prefix ---
case "$results" in
    web:*)
        # "web: <query>\tSearch the web: <query>" -> strip "web: " prefix
        web_query="${results#web: }"
        web_query="${web_query%%$'\t'*}"
        "$browser" "https://www.google.com/search?q=$(printf %s "$web_query" | sed 's/ /+/g')"
        ;;
    app:*)
        exec_line="${results#app: }"
        exec_line="${exec_line%%$'\t'*}"
        # Strip desktop-entry field codes (%f %u %U %F ...) and launch
        exec_line=$(printf %s "$exec_line" | sed -e 's/%%/__PERCENT__/g' \
            -e 's/%[fFuUdDnNickvm]//g' -e 's/__PERCENT__/%/g')
        setsid sh -c "$exec_line" >/dev/null 2>&1 &
        ;;
    dir:*)
        path="${results#dir: }"
        path="${path%%$'\t'*}"
        "$file_explorer" "$path"
        ;;
    file:*)
        path="${results#file: }"
        path="${path%%$'\t'*}"
        "$file_explorer" --select "$path" 2>/dev/null || "$file_explorer" "$(dirname "$path")"
        ;;
    *)
        notify-send -u normal "Spotlight" "Not found: $results"
        ;;
esac
