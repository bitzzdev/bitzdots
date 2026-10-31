#!/bin/bash
# Spotlight search (Spotlight-style launcher)
# ALT+SPACE -> search across:
#   - installed applications   (from .desktop entries, with their icons)
#   - files and folders        (recursive find under $HOME, with icons)
#   - the web                  (pick "Search the web" or just press Enter)
#
# Single rofi instance. The candidate list is cached for instant startup (<10ms).
# Each row is formatted as:
#     <token>\0display\x1f<label>\x1ficon\x1f<icon>\x1fmeta\x1f<terms>

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE_FILE="$CACHE_DIR/rofi-spotlight.cache"
DEFAULTS_FILE="$CONFIG_DIR/hypr/defaults.lua"

ROFI_THEME="$CONFIG_DIR/rofi/themes/launcher.rasi"
if [ ! -f "$ROFI_THEME" ]; then
    ROFI_THEME="$CONFIG_DIR/rofi/theme-generated.rasi"
fi

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

# Find browser icon (theme name) for web search row
browser_desktop=""
for d in "/usr/share/applications/$browser.desktop" \
         "$HOME/.local/share/applications/$browser.desktop" \
         "/usr/share/applications/"*"$browser"*.desktop \
         "$HOME/.local/share/applications/"*"$browser"*.desktop; do
    if [ -f "$d" ]; then
        browser_desktop="$d"
        break
    fi
done

browser_icon=""
if [ -n "$browser_desktop" ]; then
    browser_icon=$(sed -n 's/^Icon=\(.*\)$/\1/p' "$browser_desktop" 2>/dev/null | head -1)
fi
[ -z "$browser_icon" ] && browser_icon="$browser"
[ -z "$browser_icon" ] && browser_icon="web-browser"

# --- Function to generate full candidate cache ---
build_full_cache() {
    mkdir -p "$CACHE_DIR"
    local tmp_file="$CACHE_FILE.tmp.$$"

    # 1. Web search (permanent row: always visible, never filtered out)
    printf 'web:\0display\x1fSearch the web\x1ficon\x1f%s\x1fmeta\x1fgoogle search browser\x1fpermanent\x1ftrue\n' "$browser_icon" > "$tmp_file"

    # 2. Installed applications (fast single-pass awk)
    awk -F= '
    FNR==1 {
        if (name != "" && exec_cmd != "" && nodisplay != "true") {
            if (icon == "") icon = "application-x-executable";
            print "app:" exec_cmd "\0display\x1f" name "\x1ficon\x1f" icon "\x1fmeta\x1f" name " " exec_cmd;
        }
        name=""; exec_cmd=""; icon=""; nodisplay="false"; in_entry=0;
    }
    /^\[Desktop Entry\]/ { in_entry=1; next }
    /^\[/ { in_entry=0 }
    in_entry {
        if ($1 == "Name" && name == "") name = substr($0, index($0, "=")+1);
        else if ($1 == "Exec" && exec_cmd == "") exec_cmd = substr($0, index($0, "=")+1);
        else if ($1 == "Icon" && icon == "") icon = substr($0, index($0, "=")+1);
        else if ($1 == "NoDisplay" && tolower($2) == "true") nodisplay = "true";
    }
    END {
        if (name != "" && exec_cmd != "" && nodisplay != "true") {
            if (icon == "") icon = "application-x-executable";
            print "app:" exec_cmd "\0display\x1f" name "\x1ficon\x1f" icon "\x1fmeta\x1f" name " " exec_cmd;
        }
    }
    ' /usr/share/applications/*.desktop "$HOME/.local/share/applications/"*.desktop /usr/local/share/applications/*.desktop 2>/dev/null >> "$tmp_file"

    # 3. Folders (default folder icon)
    find "$HOME" \
        \( -name ".cache" -o -name ".git" -o -name "node_modules" \
           -o -name ".thumbnails" -o -name ".local" -o -name ".cargo" \
           -o -name ".rustup" -o -name "venv" -o -name "__pycache__" \) -prune -o \
        -type d -print 2>/dev/null | awk -v home="$HOME" '
    {
        path = $0
        if (path == home) next
        n = split(path, parts, "/")
        base = parts[n]
        if (base == "" || substr(base, 1, 1) == ".") next
        print "dir:" path "\0display\x1f" base "\x1ficon\x1ffolder\x1fmeta\x1f" base
    }
    ' >> "$tmp_file"

    # 4. Files (default file icon & extension icons)
    find "$HOME" \
        \( -name ".cache" -o -name ".git" -o -name "node_modules" \
           -o -name ".thumbnails" -o -name ".local" -o -name ".cargo" \
           -o -name ".rustup" -o -name "venv" -o -name "__pycache__" \) -prune -o \
        -type f -print 2>/dev/null | awk '
    BEGIN {
        img = "image-x-generic"
        vid = "video-x-generic"
        aud = "audio-x-generic"
        doc = "x-office-document"
        arc = "application-x-archive"
        exe = "application-x-executable"

        ext_map["png"]=img; ext_map["jpg"]=img; ext_map["jpeg"]=img; ext_map["gif"]=img; ext_map["svg"]=img; ext_map["webp"]=img; ext_map["bmp"]=img; ext_map["ico"]=img; ext_map["avif"]=img;
        ext_map["mp4"]=vid; ext_map["mkv"]=vid; ext_map["webm"]=vid; ext_map["avi"]=vid; ext_map["mov"]=vid; ext_map["mpg"]=vid; ext_map["mpeg"]=vid; ext_map["flv"]=vid;
        ext_map["mp3"]=aud; ext_map["wav"]=aud; ext_map["flac"]=aud; ext_map["ogg"]=aud; ext_map["m4a"]=aud; ext_map["opus"]=aud; ext_map["aac"]=aud;
        ext_map["pdf"]=doc; ext_map["doc"]=doc; ext_map["docx"]=doc; ext_map["xls"]=doc; ext_map["xlsx"]=doc; ext_map["ppt"]=doc; ext_map["pptx"]=doc; ext_map["odt"]=doc;
        ext_map["zip"]=arc; ext_map["tar"]=arc; ext_map["gz"]=arc; ext_map["xz"]=arc; ext_map["bz2"]=arc; ext_map["7z"]=arc; ext_map["rar"]=arc; ext_map["zst"]=arc;
        ext_map["sh"]=exe; ext_map["py"]=exe; ext_map["js"]=exe; ext_map["ts"]=exe; ext_map["rs"]=exe; ext_map["go"]=exe; ext_map["c"]=exe; ext_map["cpp"]=exe; ext_map["h"]=exe; ext_map["fish"]=exe;
    }
    {
        path = $0
        n = split(path, parts, "/")
        base = parts[n]
        if (base == "" || substr(base, 1, 1) == ".") next

        ext = ""
        dot = index(base, ".")
        if (dot > 0) {
            m = split(base, subparts, ".")
            ext = tolower(subparts[m])
        }

        icon = (ext in ext_map) ? ext_map[ext] : "text-x-generic"
        print "file:" path "\0display\x1f" base "\x1ficon\x1f" icon "\x1fmeta\x1f" base
    }
    ' >> "$tmp_file"

    mv "$tmp_file" "$CACHE_FILE"
}

# Ensure cache exists or rebuild in background if older than 5 minutes (300 seconds)
if [ -f "$CACHE_FILE" ]; then
    cache_age=$(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0)))
    if [ "$cache_age" -gt 300 ]; then
        (build_full_cache) &>/dev/null &
    fi
else
    build_full_cache
fi

# --- Launch rofi (instant display from cache, using matugen theme & icons) ---
out=$(cat "$CACHE_FILE" | rofi -dmenu -i -show-icons -p "Spotlight" \
    -theme "$ROFI_THEME" \
    -theme-str 'listview { columns: 1; lines: 10; spacing: 4px; padding: 6px; flow: vertical; } window { width: 640px; border-radius: 0px; } element { orientation: horizontal; padding: 8px 12px; spacing: 12px; border: 0px; border-radius: 0px; } element selected { border-radius: 0px; } element-icon { size: 24px; vertical-align: 0.5; } element-text { horizontal-align: 0; vertical-align: 0.5; text-color: inherit; } entry { placeholder: "Search apps, files, folders or the web..."; }' \
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


