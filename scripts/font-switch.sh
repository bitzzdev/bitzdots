#!/bin/bash
# ============================================================
# Switch system and terminal font between JetBrainsMono and Paper Mono
# ============================================================
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

ensure_paper_mono() {
    # Check if Paper Mono is installed globally or locally
    if fc-list : family 2>/dev/null | grep -qi "Paper Mono"; then
        return 0
    fi

    # Check direct system / user font directories
    for dir in "/usr/local/share/fonts/paper-mono" "/usr/share/fonts/paper-mono" "$HOME/.local/share/fonts/paper-mono"; do
        if [ -d "$dir" ] && [ -n "$(ls -A "$dir" 2>/dev/null)" ]; then
            fc-cache -f "$dir" 2>/dev/null || true
            return 0
        fi
    done

    echo "Paper Mono not found. Downloading Paper Mono from GitHub..."

    # Prefer global directory /usr/local/share/fonts if writable or accessible via sudo, else local user directory
    local font_dir="/usr/local/share/fonts/paper-mono"
    local use_sudo=false

    if [ -w "/usr/local/share/fonts" ]; then
        mkdir -p "$font_dir"
    elif command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
        sudo mkdir -p "$font_dir"
        use_sudo=true
    else
        font_dir="$HOME/.local/share/fonts/paper-mono"
        mkdir -p "$font_dir"
    fi

    local tmp_zip="/tmp/paper-mono.zip"
    if command -v curl &>/dev/null; then
        curl -fsSL -o "$tmp_zip" "https://github.com/paper-design/paper-mono/releases/latest/download/paper-mono-v1.000.zip" || \
        curl -fsSL -o "$tmp_zip" "https://github.com/paper-design/paper-mono/archive/refs/heads/main.zip"
    elif command -v wget &>/dev/null; then
        wget -q -O "$tmp_zip" "https://github.com/paper-design/paper-mono/releases/latest/download/paper-mono-v1.000.zip" || \
        wget -q -O "$tmp_zip" "https://github.com/paper-design/paper-mono/archive/refs/heads/main.zip"
    fi

    if [ -f "$tmp_zip" ]; then
        local extract_dir="/tmp/paper-mono-extract"
        rm -rf "$extract_dir"
        mkdir -p "$extract_dir"

        if command -v bsdtar &>/dev/null; then
            bsdtar -xf "$tmp_zip" -C "$extract_dir" 2>/dev/null || true
        elif command -v unzip &>/dev/null; then
            unzip -q -o "$tmp_zip" -d "$extract_dir" 2>/dev/null || true
        fi
        rm -f "$tmp_zip"

        if $use_sudo; then
            sudo cp -rn "$extract_dir"/* "$font_dir/" 2>/dev/null || sudo cp -r "$extract_dir"/* "$font_dir/"
            sudo chmod -R 644 "$font_dir"/* 2>/dev/null || true
            sudo find "$font_dir" -type d -exec chmod 755 {} + 2>/dev/null || true
            sudo fc-cache -f "$font_dir" 2>/dev/null || true
        else
            cp -rn "$extract_dir"/* "$font_dir/" 2>/dev/null || cp -r "$extract_dir"/* "$font_dir/"
            fc-cache -f "$font_dir" 2>/dev/null || true
        fi
        rm -rf "$extract_dir"
        echo "Paper Mono installed successfully to $font_dir"
    else
        echo "Could not download Paper Mono automatically. Please install it manually from https://paper.design/mono"
    fi
}

switch_to() {
    local target="$1"
    local kitty_conf="$DOTFILES_DIR/kitty/kitty.conf"
    local kitty_target="$CONFIG_DIR/kitty/kitty.conf"
    local waybar_css="$DOTFILES_DIR/matugen/templates/waybar.css"
    local waybar_active="$CONFIG_DIR/waybar/style.css"

    case "$target" in
        paper|papermono|"Paper Mono")
            ensure_paper_mono
            echo "Switching font to Paper Mono..."

            # 1. Update kitty
            for f in "$kitty_conf" "$kitty_target"; do
                if [ -f "$f" ]; then
                    sed -i -E 's/^[# ]*font_family.*/font_family                 Paper Mono/' "$f"
                fi
            done

            # 2. Update waybar template (keep JetBrainsMono Nerd Font fallback for icons)
            for f in "$waybar_css" "$waybar_active"; do
                if [ -f "$f" ]; then
                    sed -i -E 's/font-family:[^;]*sans-serif;/font-family: "Paper Mono", "JetBrainsMono Nerd Font", "JetBrains Mono", sans-serif;/' "$f"
                fi
            done

            echo "Font switched to Paper Mono."
            ;;

        jetbrains|jetbrainsmono|"JetBrainsMono Nerd Font"|"JetBrains Mono")
            echo "Switching font to JetBrainsMono Nerd Font..."

            # 1. Update kitty
            for f in "$kitty_conf" "$kitty_target"; do
                if [ -f "$f" ]; then
                    sed -i -E 's/^[# ]*font_family.*/font_family                 JetBrainsMono Nerd Font/' "$f"
                fi
            done

            # 2. Update waybar template
            for f in "$waybar_css" "$waybar_active"; do
                if [ -f "$f" ]; then
                    sed -i -E 's/font-family:[^;]*sans-serif;/font-family: "JetBrainsMono Nerd Font", "JetBrains Mono", sans-serif;/' "$f"
                fi
            done

            echo "Font switched to JetBrainsMono Nerd Font."
            ;;

        *)
            echo "Usage: font-switch.sh [paper | jetbrains]"
            return 1
            ;;
    esac

    # Reload Kitty instances
    if pgrep -x kitty >/dev/null 2>&1; then
        killall -SIGUSR1 kitty 2>/dev/null || true
    fi

    # Reload Waybar
    if pgrep -x waybar >/dev/null 2>&1; then
        pkill -x waybar 2>/dev/null || true
        sleep 0.3
        waybar &>/dev/null &
    fi
}

TARGET="${1:-toggle}"
if [ "$TARGET" = "toggle" ]; then
    current_font=$(grep -E '^[# ]*font_family' "$CONFIG_DIR/kitty/kitty.conf" 2>/dev/null | awk '{print $2}' || echo "JetBrainsMono")
    if [[ "$current_font" =~ "Paper" ]]; then
        switch_to "jetbrains"
    else
        switch_to "paper"
    fi
else
    switch_to "$TARGET"
fi
