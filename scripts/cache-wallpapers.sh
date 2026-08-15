#!/bin/bash
# One-shot wallpaper palette cache generator
# Pre-generates wallust color schemes so theme switching is instant.
# The event-driven daemon is wallust-cache-daemon.sh (systemd service).

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WALL_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
THEME_CACHE="$CACHE_DIR/wallust/themes"
THUMB_DIR="$CACHE_DIR/wallust-thumbs"
LIVE_DIR="$WALL_DIR/live"

mkdir -p "$THEME_CACHE" "$THUMB_DIR"

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

cache_wallpaper() {
    local img="$1"
    local name
    name="$(basename "$img" | sed 's/\.[^.]*$//')"
    local cache_dir="$THEME_CACHE/$name"
    local marker="$cache_dir/.done"
    local thumb_path="$THUMB_DIR/${name}.jpg"

    # Generate small thumbnail for rofi grid (regardless of wallust cache freshness)
    if [ ! -f "$thumb_path" ] && command -v convert &>/dev/null; then
        convert "$img" -resize "200x200>" -quality 85 "$thumb_path" 2>/dev/null || true
    fi

    # Check if wallust cache is still fresh
    if [ -f "$marker" ]; then
        local fmtime mmtime
        fmtime=$(stat -c %Y "$img" 2>/dev/null)
        mmtime=$(stat -c %Y "$marker" 2>/dev/null)
        [ -n "$fmtime" ] && [ -n "$mmtime" ] && [ "$fmtime" -le "$mmtime" ] && return 0
    fi

    mkdir -p "$cache_dir"

    # Backup current theme so we can restore after caching
    local backup_dir
    backup_dir=$(mktemp -d /tmp/wallust-cache-backup-XXXXXX)
    for output in "${WALLUST_OUTPUTS[@]}"; do
        local src="$CONFIG_DIR/$output"
        if [ -f "$src" ]; then
            mkdir -p "$(dirname "$backup_dir/$output")"
            cp "$src" "$backup_dir/$output"
        fi
    done

    if ! timeout 30 wallust run "$img" --config-dir "$CONFIG_DIR/wallust" -q 2>/dev/null; then
        restore_backup "$backup_dir"
        return 1
    fi

    for output in "${WALLUST_OUTPUTS[@]}"; do
        local src="$CONFIG_DIR/$output"
        if [ -f "$src" ]; then
            mkdir -p "$(dirname "$cache_dir/$output")"
            cp "$src" "$cache_dir/$output"
        fi
    done

    touch "$marker"

    # Restore the user's active theme
    restore_backup "$backup_dir"
}

restore_backup() {
    local backup_dir="$1"
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

scan_and_cache() {
    local found=0

    while IFS= read -r -d '' f; do
        cache_wallpaper "$f" && found=$((found + 1))
    done < <(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0 2>/dev/null)

    if [ -d "$LIVE_DIR" ]; then
        while IFS= read -r -d '' f; do
            # Live wallpapers: extract a frame and cache that
            local name
            name="$(basename "$f" | sed 's/\.[^.]*$//')"
            local cache_dir="$THEME_CACHE/$name"
            local marker="$cache_dir/.done"

            if [ -f "$marker" ] && [ -f "$f" ]; then
                local fmtime mmtime
                fmtime=$(stat -c %Y "$f" 2>/dev/null)
                mmtime=$(stat -c %Y "$marker" 2>/dev/null)
                [ -n "$fmtime" ] && [ -n "$mmtime" ] && [ "$fmtime" -le "$mmtime" ] && continue
            fi

            if command -v ffmpeg &>/dev/null; then
                local frame
                frame="$(mktemp /tmp/wallust-frame-XXXXXX.jpg)"
                ffmpeg -i "$f" -vframes 1 "$frame" -y 2>/dev/null || { rm -f "$frame"; continue; }
                cache_wallpaper "$frame"
                rm -f "$frame"
            fi
        done < <(find "$LIVE_DIR" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.gif" \) -print0 2>/dev/null)
    fi

    [ "$found" -gt 0 ] && echo "cached $found wallpapers"
    return 0
}

# Daemon mode was removed — use wallust-cache-daemon.sh instead (systemd service).
# This script is kept for manual one-shot caching:
#   ~/.config/wallust/cache-wallpapers.sh
scan_and_cache
