#!/bin/bash
# ============================================================
# Switch system and terminal font between JetBrainsMono and Paper Mono
# ============================================================
set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DOTFILES_DIR="$(cd "$(dirname "$0")/.." && pwd)"

ensure_paper_mono() {
    # Check if Paper Mono is installed
    if fc-list :family 2>/dev/null | grep -qi "Paper Mono"; then
        return 0
    fi

    echo "Paper Mono not found. Downloading Paper Mono from GitHub..."
    local font_dir="$HOME/.local/share/fonts/paper-mono"
    mkdir -p "$font_dir"
    local tmp_zip="/tmp/paper-mono.zip"

    if command -v curl &>/dev/null; then
        curl -fsSL -o "$tmp_zip" "https://github.com/paper-design/paper-mono/releases/latest/download/paper-mono-v1.000.zip" || \
        curl -fsSL -o "$tmp_zip" "https://github.com/paper-design/paper-mono/archive/refs/heads/main.zip"
    elif command -v wget &>/dev/null; then
        wget -q -O "$tmp_zip" "https://github.com/paper-design/paper-mono/releases/latest/download/paper-mono-v1.000.zip" || \
        wget -q -O "$tmp_zip" "https://github.com/paper-design/paper-mono/archive/refs/heads/main.zip"
    fi

    if [ -f "$tmp_zip" ]; then
        if command -v bsdtar &>/dev/null; then
            bsdtar -xf "$tmp_zip" -C "$font_dir" 2>/dev/null || true
        elif command -v unzip &>/dev/null; then
            unzip -q -o "$tmp_zip" -d "$font_dir" 2>/dev/null || true
        fi
        rm -f "$tmp_zip"
        fc-cache -f "$font_dir" 2>/dev/null || true
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
            [ -f "$kitty_conf" ] && sed -i 's/^font_family .*/font_family                 Paper Mono/' "$kitty_conf"
            [ -f "$kitty_target" ] && sed -i 's/^font_family .*/font_family                 Paper Mono/' "$kitty_target"

            # 2. Update waybar template
            [ -f "$waybar_css" ] && sed -i 's/font-family: "[^"]*", "JetBrains Mono"/font-family: "Paper Mono", "JetBrains Mono"/' "$waybar_css"
            [ -f "$waybar_active" ] && sed -i 's/font-family: "[^"]*", "JetBrains Mono"/font-family: "Paper Mono", "JetBrains Mono"/' "$waybar_active"

            echo "Font switched to Paper Mono."
            ;;
        jetbrains|jetbrainsmono|"JetBrainsMono Nerd Font")
            echo "Switching font to JetBrainsMono Nerd Font..."

            # 1. Update kitty
            [ -f "$kitty_conf" ] && sed -i 's/^font_family .*/font_family                 JetBrainsMono Nerd Font/' "$kitty_conf"
            [ -f "$kitty_target" ] && sed -i 's/^font_family .*/font_family                 JetBrainsMono Nerd Font/' "$kitty_target"

            # 2. Update waybar template
            [ -f "$waybar_css" ] && sed -i 's/font-family: "[^"]*", "JetBrains Mono"/font-family: "JetBrainsMono Nerd Font", "JetBrains Mono"/' "$waybar_css"
            [ -f "$waybar_active" ] && sed -i 's/font-family: "[^"]*", "JetBrains Mono"/font-family: "JetBrainsMono Nerd Font", "JetBrains Mono"/' "$waybar_active"

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
    current_font=$(grep "^font_family" "$CONFIG_DIR/kitty/kitty.conf" 2>/dev/null | awk '{print $2}' || echo "JetBrainsMono")
    if [[ "$current_font" =~ "Paper" ]]; then
        switch_to "jetbrains"
    else
        switch_to "paper"
    fi
else
    switch_to "$TARGET"
fi
