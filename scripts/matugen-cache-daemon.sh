#!/bin/bash
# Event-driven wallpaper palette cache daemon
# Uses inotify to sleep at 0% CPU until a wallpaper changes.
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
WALL_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
THEME_CACHE="$CACHE_DIR/matugen/themes"
THUMB_DIR="$CACHE_DIR/matugen-thumbs"
LIVE_DIR="$WALL_DIR/live"
LOCK_FILE="$THEME_CACHE/daemon.lock"
LOG_TAG="matugen-daemon"

MATUGEN_OUTPUTS=(
    "waybar/style.css"
    "waybar/config.jsonc"
    "swaync/style.css"
    "wlogout/style.css"
    "hypr/colors.lua"
    "kitty/colors.conf"
    "cava/themes/generated"
    "rofi/theme-generated.rasi"
    "matugen/env"
    "matugen/browser-colors.css"
    "matugen/chromium-theme.json"
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

# Image/video extensions the daemon recognises
IMAGE_EXT_RE="\.(jpg|jpeg|png|webp|avif|bmp|gif|tiff|tif|svg)$"
VIDEO_EXT_RE="\.(mp4|webm|mkv|mov|avi|m4v)$"

# ── Helpers ────────────────────────────────────────────────────────

log() { echo "$LOG_TAG: $*"; }
warn() { echo "$LOG_TAG: WARNING: $*" >&2; }
err()  { echo "$LOG_TAG: ERROR: $*" >&2; }

is_supported() {
    local f="$1"
    [[ "$(basename "$f")" =~ ^[^.] ]] || return 1       # skip hidden
    [[ "$(basename "$f")" =~ \.tmp$|\.swp$|~$|4913$ ]] && return 1  # temp / swap
    [[ "$f" =~ $IMAGE_EXT_RE || "$f" =~ $VIDEO_EXT_RE ]]
}

cache_dir_for() {
    local img="$1"
    local name
    name="$(basename "$img" | sed 's/\.[^.]*$//')"
    echo "$THEME_CACHE/$name"
}

marker_for()   { echo "$(cache_dir_for "$1")/.done"; }
skip_marker_for() { echo "$(cache_dir_for "$1")/.skip"; }
thumb_for()    { echo "$THUMB_DIR/$(basename "$1" | sed 's/\.[^.]*$//').jpg"; }

# Does a complete, valid cache exist?
cache_valid() {
    local img="$1"
    local marker; marker=$(marker_for "$img")
    local thumb; thumb=$(thumb_for "$img")

    [ -f "$marker" ] || return 1

    local img_mtime cache_mtime
    img_mtime=$(stat -c %Y "$img" 2>/dev/null) || return 1
    cache_mtime=$(stat -c %Y "$marker" 2>/dev/null) || return 1
    [ "$img_mtime" -le "$cache_mtime" ] || return 1

    # Every expected output must exist in cache (not just .done)
    local cache_dir; cache_dir=$(cache_dir_for "$img")
    for output in "${MATUGEN_OUTPUTS[@]}"; do
        [ -f "$cache_dir/$output" ] || return 1
    done

    [ -f "$thumb" ] || return 1

    return 0
}

# Skip cache generation for images that persistently fail.
# Uses a cooldown: after failure, skip retries for 24 hours.
is_skipped() {
    local img="$1"
    local skip; skip=$(skip_marker_for "$img")
    [ -f "$skip" ] || return 1
    local skip_time now
    skip_time=$(stat -c %Y "$skip" 2>/dev/null) || return 1
    now=$(date +%s)
    [ $((now - skip_time)) -lt 86400 ] || return 1
    return 0
}

mark_skipped() {
    local img="$1"
    local skip; skip=$(skip_marker_for "$img")
    mkdir -p "$(dirname "$skip")"
    touch "$skip"
}

clear_skip() {
    local img="$1"
    rm -f "$(skip_marker_for "$img")"
}

# Extract a single frame from a video for matugen colour extraction
extract_frame() {
    local video="$1"
    local frame; frame=$(mktemp /tmp/matugen-frame-XXXXXX.jpg)
    ffmpeg -i "$video" -vframes 1 -vf "scale=320:-1" "$frame" -y 2>/dev/null || {
        rm -f "$frame"
        return 1
    }
    echo "$frame"
}

# ── Thumbnail generation ──────────────────────────────────────────

generate_thumbnail() {
    local img="$1"
    local thumb; thumb=$(thumb_for "$img")
    [ -f "$thumb" ] && return 0
    command -v convert &>/dev/null || return 0
    mkdir -p "$(dirname "$thumb")"
    convert "$img" -resize "200x200>" -quality 85 "$thumb" 2>/dev/null || true
}

# ── Palette generation ───────────────────────────────────────────

generate_palette() {
    local img="$1"
    local cache_dir; cache_dir=$(cache_dir_for "$img")
    local marker; marker=$(marker_for "$img")

    mkdir -p "$cache_dir"

    local backup_dir
    backup_dir=$(mktemp -d /tmp/matugen-daemon-backup-XXXXXX)
    for output in "${MATUGEN_OUTPUTS[@]}"; do
        local src="$CONFIG_DIR/$output"
        if [ -f "$src" ]; then
            mkdir -p "$(dirname "$backup_dir/$output")"
            cp "$src" "$backup_dir/$output"
        fi
    done

    if ! timeout 30 matugen image "$img" --config "$CONFIG_DIR/matugen/config.toml" -q 2>/dev/null; then
        for output in "${MATUGEN_OUTPUTS[@]}"; do
            local src="$backup_dir/$output"
            local dst="$CONFIG_DIR/$output"
            if [ -f "$src" ]; then
                mkdir -p "$(dirname "$dst")"
                cp "$src" "$dst"
            fi
        done
        rm -rf "$backup_dir"
        return 1
    fi

    for output in "${MATUGEN_OUTPUTS[@]}"; do
        local src="$CONFIG_DIR/$output"
        if [ -f "$src" ]; then
            mkdir -p "$(dirname "$cache_dir/$output")"
            cp "$src" "$cache_dir/$output"
        fi
    done

    for output in "${MATUGEN_OUTPUTS[@]}"; do
        local src="$backup_dir/$output"
        local dst="$CONFIG_DIR/$output"
        if [ -f "$src" ]; then
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
        fi
    done
    rm -rf "$backup_dir"

    touch "$marker"
    return 0
}

# ── Single wallpaper processing ──────────────────────────────────

process_one() {
    local path="$1"

    # Resolve symlinks (current_wallpaper.png etc.)
    [ -L "$path" ] && path=$(readlink -f "$path") || true
    [ -f "$path" ] || return 0

    is_supported "$path" || return 0

    # If image is in cooldown (failed before), skip until the file changes
    if is_skipped "$path"; then
        return 0
    fi

    generate_thumbnail "$path"

    if cache_valid "$path"; then
        return 0
    fi

    local src="$path"

    # For videos, extract a frame first
    if [[ "$src" =~ $VIDEO_EXT_RE ]]; then
        if command -v ffmpeg &>/dev/null; then
            local frame
            frame=$(extract_frame "$src") || {
                err "failed to extract frame from $src"
                mark_skipped "$path"
                return 1
            }
            src="$frame"
        else
            warn "ffmpeg not available — skipping $src"
            mark_skipped "$path"
            return 1
        fi
    fi

    if generate_palette "$src"; then
        clear_skip "$path"
        log "generated palette for $(basename "$path")"
    else
        mark_skipped "$path"
        err "failed to generate palette for $(basename "$path")"
    fi

    # Clean up extracted frame
    [[ "$src" != "$path" ]] && rm -f "$src"

    return 0
}

# ── Batch scan (initial / full) ──────────────────────────────────

scan_all() {
    local found=0
    local failed=0

    while IFS= read -r -d '' f; do
        if process_one "$f"; then
            [ -f "$(marker_for "$f")" ] && found=$((found + 1))
        else
            failed=$((failed + 1))
        fi
    done < <(
        {
            [ -d "$WALL_DIR" ] && find "$WALL_DIR" -maxdepth 1 -type f -print0
            [ -d "$LIVE_DIR" ] && find "$LIVE_DIR" -maxdepth 1 -type f -print0
        } 2>/dev/null | sort -z
    )

    log "initial scan: $found cached, $failed failed"
}

# ── Debounce: collect inotify events over a short window ────────

debounce_and_process() {
    # $1 is the initial file path from inotify
    # Read any additional events that arrive within 2 seconds
    local -A seen
    local path

    seen["$1"]=1

    while read -t 2 -r dir event file; do
        [ -z "$file" ] && continue
        path="${dir%/}/$file"
        [ -n "${seen[$path]:-}" ] && continue
        seen["$path"]=1
    done

    for path in "${!seen[@]}"; do
        # Clear skip marker — file was just added/modified, so retry even if previously failed
        clear_skip "$path"
        process_one "$path"
    done
}

# ── Startup ───────────────────────────────────────────────────────

startup() {
    mkdir -p "$THEME_CACHE" "$THUMB_DIR"

    # Acquire exclusive lock — fail fast if another instance is running
    exec 200>"$LOCK_FILE"
    flock -n 200 || {
        err "another instance is already running (lock: $LOCK_FILE)"
        exit 1
    }

    log "daemon started"

    # Remove stale skip markers older than 7 days
    find "$THEME_CACHE" -name '.skip' -mtime +7 -delete 2>/dev/null || true

    scan_all
}

# ── Main event loop ──────────────────────────────────────────────

main_loop() {
    # Verify dependencies
    command -v inotifywait &>/dev/null || {
        err "inotifywait not found — install inotify-tools"
        exit 1
    }

    # Build watch list
    local watch_dirs=()
    [ -d "$WALL_DIR" ] && watch_dirs+=("$WALL_DIR")
    [ -d "$LIVE_DIR" ] && watch_dirs+=("$LIVE_DIR")

    if [ ${#watch_dirs[@]} -eq 0 ]; then
        err "no wallpaper directories exist ($WALL_DIR, $LIVE_DIR)"
        exit 1
    fi

    log "watching ${watch_dirs[*]}"

    # Events: close_write (new/modified), moved_to (moved/copied in),
    #         moved_from + move (rename), delete (removed), create (hardlink)
    inotifywait -m "${watch_dirs[@]}" \
        -e close_write -e moved_to -e create \
        --format '%w%f' --no-dereference 2>/dev/null |
    while IFS= read -r path; do
        [ -z "$path" ] && continue
        # Ignore temporary / swap files
        [[ "$(basename "$path")" =~ ^\.|\.tmp$|\.swp$|~$|4913$ ]] && continue
        # Ignore non-supported extensions quickly
        is_supported "$path" || continue

        debounce_and_process "$path"
    done
}

# ── Entry ──────────────────────────────────────────────────────────

startup
main_loop
