#!/bin/bash
# Rofi wallpaper selector with automatic theme generation via wallust

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WALL_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
THEME_CACHE="$CACHE_DIR/wallust/themes"
ROFI_THEME="$CONFIG_DIR/rofi/themes/wallpaper-grid.rasi"
ROFI_POWER="$CONFIG_DIR/rofi/themes/power.rasi"
LIVE_DIR="$WALL_DIR/live"
THUMB_DIR="$CACHE_DIR/wallust-thumbs"
LOG_DIR="$CACHE_DIR/wallust"
LOG_FILE="$LOG_DIR/wallpaper-select.log"

mkdir -p "$CACHE_DIR" "$THUMB_DIR" "$THEME_CACHE" "$LOG_DIR"

alert() {
    local urgency="${2:-normal}"
    local title="$1"
    local msg="$3"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$urgency] $title${msg:+ - $msg}" >> "$LOG_FILE"
    echo "[wallpaper-select] $title${msg:+ - $msg}" >&2
    notify-send -u "$urgency" "$title" "$msg" 2>/dev/null || true
}

if [ ! -d "$WALL_DIR" ]; then
    alert "Wallpapers not found" critical "Directory $WALL_DIR does not exist"
    exit 1
fi

WALLUST_OUTPUTS=(
    "waybar/style.css"
    "waybar/config.jsonc"
    "swaync/style.css"
    "wlogout/style.css"
    "hypr/colors.lua"
    "kitty/colors.conf"
    "cava/themes/generated"
    "rofi/theme-generated.rasi"
    "wallust/env"
    "wallust/browser-colors.css"
    "wallust/chromium-theme.json"
    "rofi/themes/wallpaper-grid.rasi"
    "rofi/themes/power.rasi"
    "rofi/icons/lock.svg"
    "rofi/icons/logout.svg"
    "rofi/icons/sleep.svg"
    "rofi/icons/reboot.svg"
    "rofi/icons/shutdown.svg"
    "rofi/icons/cancel.svg"
    "rofi/icons/static.svg"
    "rofi/icons/live.svg"
    "kdeglobals"
    "bitzdots.colors"
    "qt6ct/qt6ct.conf"
)

backup_theme() {
    local backup_dir="$CACHE_DIR/wallust-backup"
    rm -rf "$backup_dir"
    for output in "${WALLUST_OUTPUTS[@]}"; do
        local src="$CONFIG_DIR/$output"
        if [ -f "$src" ]; then
            local dst="$backup_dir/$output"
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
        fi
    done
}

restore_theme() {
    local backup_dir="$CACHE_DIR/wallust-backup"
    if [ ! -d "$backup_dir" ]; then
        return
    fi
    for output in "${WALLUST_OUTPUTS[@]}"; do
        local src="$backup_dir/$output"
        local dst="$CONFIG_DIR/$output"
        if [ -f "$src" ]; then
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
        fi
    done
    rm -rf "$backup_dir"
}

clear_backup() {
    rm -rf "$CACHE_DIR/wallust-backup"
}

apply_cached_theme() {
    local name="$1"
    local cache_dir="$THEME_CACHE/$name"
    local marker="$cache_dir/.done"

    if [ ! -f "$marker" ]; then
        return 1
    fi

    # Invalidate cache if templates changed since it was made
    local template_dir="$CONFIG_DIR/wallust/templates"
    local latest=0
    for f in "$template_dir"/*.j2; do
        [ -f "$f" ] || continue
        local t
        t=$(stat -c '%Y' "$f")
        [ "$t" -gt "$latest" ] && latest=$t
    done
    local cache_time
    cache_time=$(stat -c '%Y' "$marker")
    if [ "$latest" -gt "$cache_time" ]; then
        rm -rf "$cache_dir"
        return 1
    fi

    for output in "${WALLUST_OUTPUTS[@]}"; do
        local src="$cache_dir/$output"
        local dst="$CONFIG_DIR/$output"
        if [ -f "$src" ]; then
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
        fi
    done

    return 0
}

cache_current_theme() {
    local name="$1"
    local cache_dir="$THEME_CACHE/$name"

    mkdir -p "$cache_dir"
    for output in "${WALLUST_OUTPUTS[@]}"; do
        local src="$CONFIG_DIR/$output"
        if [ -f "$src" ]; then
            mkdir -p "$(dirname "$cache_dir/$output")"
            cp "$src" "$cache_dir/$output"
        fi
    done
    touch "$cache_dir/.done"
}

# ── Helper: set static wallpaper ─────────────────────────────────
set_static() {
    local img="$1"
    local name
    name="$(basename "$img" | sed 's/\.[^.]*$//')"

    if ! command -v wallust &>/dev/null; then
        alert "wallust not installed" critical
        exit 1
    fi

    echo "$img" > "$CACHE_DIR/current_wallpaper.txt"
    ln -sf "$img" "$CACHE_DIR/current_wallpaper.png" 2>/dev/null || true

    # Stop any running live wallpaper first (awww can't override mpvpaper)
    pkill mpvpaper 2>/dev/null || true

    if command -v awww &>/dev/null; then
        if ! pgrep -x awww-daemon > /dev/null; then
            awww-daemon &
            sleep 0.5
        fi
        awww img "$img" \
            --transition-type grow \
            --transition-pos center \
            --transition-duration 2 \
            --transition-fps 60 || true
    fi

    if ! apply_cached_theme "$name"; then
        alert "Generating theme..." normal "Calculating color palette..."
        backup_theme
        if timeout 30 wallust run "$img" --config-dir "$CONFIG_DIR/wallust"; then
            cache_current_theme "$name" || true
            clear_backup
        else
            restore_theme
            alert "Theme generation failed" critical "Could not generate colors for this wallpaper"
            return 1
        fi
    fi

    "$CONFIG_DIR/wallust/reload-theme.sh" || true

    alert "Theme updated" normal "Wallpaper and colors applied"

    # Restart waybar to pick up new config.jsonc and CSS
    if pgrep -x waybar > /dev/null; then
        pkill -x waybar 2>/dev/null || true
        sleep 0.3
        waybar &>/dev/null &
    fi
}

# ── Helper: set live wallpaper ───────────────────────────────────
set_live() {
    local video="$1"
    local name
    name="$(basename "$video" | sed 's/\.[^.]*$//')"

    if ! command -v mpvpaper &>/dev/null; then
        alert "mpvpaper not installed" critical "Install mpvpaper for live wallpapers"
        exit 1
    fi

    echo "$video" > "$CACHE_DIR/current_wallpaper.txt"

    pkill mpvpaper 2>/dev/null || true
    mpvpaper -o "loop no-audio" '*' "$video"

    if command -v ffmpeg &>/dev/null && command -v wallust &>/dev/null; then
        local frame="$CACHE_DIR/live-frame.jpg"
        ffmpeg -i "$video" -vframes 1 "$frame" -y 2>/dev/null || true
        if [ -f "$frame" ]; then
            ln -sf "$frame" "$CACHE_DIR/current_wallpaper.png" 2>/dev/null || true
            if ! apply_cached_theme "$name"; then
                alert "Generating theme..." normal "Calculating color palette..."
                backup_theme
                if timeout 30 wallust run "$frame" --config-dir "$CONFIG_DIR/wallust"; then
                    cache_current_theme "$name" || true
                    clear_backup
                else
                    restore_theme
                    alert "Theme generation failed" critical "Could not generate colors for this wallpaper"
                    return 1
                fi
            fi
            "$CONFIG_DIR/wallust/reload-theme.sh" || true

            alert "Live wallpaper" normal "$(basename "$video")"

            # Restart waybar to pick up new config.jsonc and CSS
            if pgrep -x waybar > /dev/null; then
                pkill -x waybar 2>/dev/null || true
                sleep 0.3
                waybar &>/dev/null &
            fi
        fi
    fi
}

# ── Generate thumbnail for video ─────────────────────────────────
generate_thumb() {
    local video="$1"
    local thumb_name
    thumb_name="$(basename "$video" | sed 's/\.[^.]*$//').jpg"
    local thumb_path="$THUMB_DIR/$thumb_name"

    if [ ! -f "$thumb_path" ] && command -v ffmpeg &>/dev/null; then
        mkdir -p "$(dirname "$thumb_path")"
        ffmpeg -i "$video" -vframes 1 -vf "scale=180:-1" "$thumb_path" -y 2>/dev/null || true
    fi

    if [ -f "$thumb_path" ]; then
        echo "$thumb_path"
    else
        echo "$video"
    fi
}

# ── Pick static wallpaper ────────────────────────────────────────
pick_static() {
    local images
    mapfile -t images < <(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort)

    if [ ${#images[@]} -eq 0 ]; then
        alert "No wallpapers found" normal "Add images to $WALL_DIR/"
        return 1
    fi

    local selected
    selected=$(
        for f in "${images[@]}"; do
            local thumb="$THUMB_DIR/$(basename "$f" | sed 's/\.[^.]*$//').jpg"
            if [ -f "$thumb" ]; then
                echo -ne "$f\0icon\x1f$thumb\n"
            else
                echo -ne "$f\0icon\x1f$f\n"
            fi
        done \
        | rofi -dmenu -i -p "" -theme "$ROFI_THEME" -show-icons
    )

    if [ -z "$selected" ]; then
        return 1
    fi

    if [ ! -f "$selected" ]; then
        selected="$WALL_DIR/$selected"
    fi

    if [ ! -f "$selected" ]; then
        alert "Wallpaper not found" critical "$selected"
        return 1
    fi

    set_static "$selected"
}

# ── Pick live wallpaper ──────────────────────────────────────────
pick_live() {
    if [ ! -d "$LIVE_DIR" ]; then
        alert "No live wallpapers" critical "Directory $LIVE_DIR does not exist"
        return 1
    fi

    local videos
    mapfile -t videos < <(find "$LIVE_DIR" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.gif" \) | sort)

    if [ ${#videos[@]} -eq 0 ]; then
        alert "No live wallpapers" normal "Add videos to $LIVE_DIR/"
        return 1
    fi

    local selected
    selected=$(
        for f in "${videos[@]}"; do
            thumb=$(generate_thumb "$f")
            echo -ne "$f\0icon\x1f$thumb\n"
        done \
        | rofi -dmenu -i -p "" -theme "$ROFI_THEME" -show-icons
    )

    if [ -z "$selected" ]; then
        return 1
    fi

    if [ ! -f "$selected" ]; then
        selected="$LIVE_DIR/$selected"
    fi

    if [ ! -f "$selected" ]; then
        alert "Video not found" critical "$selected"
        return 1
    fi

    set_live "$selected"
}

# ── Main menu ────────────────────────────────────────────────────
main_menu() {
    local has_live=false
    [ -d "$LIVE_DIR" ] && [ "$(find "$LIVE_DIR" -maxdepth 1 -type f 2>/dev/null | wc -l)" -gt 0 ] && has_live=true

    local icons_dir="$CONFIG_DIR/rofi/icons"
    local choice
    choice=$(
        {
            printf "Static wallpaper\0icon\x1f${icons_dir}/static.svg\n"
            $has_live && printf "Live wallpaper\0icon\x1f${icons_dir}/live.svg\n"
        } | rofi -dmenu -i -p "Wallpaper" -theme "$ROFI_POWER" -show-icons \
            -theme-str 'listview { lines: 2; }'
    )

    case "$choice" in
        "Static wallpaper") pick_static ;;
        "Live wallpaper")   pick_live ;;
        *) exit 0 ;;
    esac
}

# ── Entry point ──────────────────────────────────────────────────
if [ $# -eq 1 ] && [ -f "$1" ]; then
    set_static "$1"
elif [ $# -eq 1 ] && [ "$1" = "--live" ]; then
    pick_live
else
    main_menu
fi
