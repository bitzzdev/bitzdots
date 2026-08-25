#!/bin/bash
# Notify themed applications that colors changed
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"

echo ":: Theme files updated..."

# Source environment variables from matugen
if [ -f "$CONFIG_DIR/matugen/env" ]; then
    source "$CONFIG_DIR/matugen/env"
elif [ -f "$CONFIG_DIR/wallust/env" ]; then
    source "$CONFIG_DIR/wallust/env"
fi

# Fix ~ not being expanded by qt6ct in color_scheme_path
if [ -f "$CONFIG_DIR/qt6ct/qt6ct.conf" ]; then
    sed -i "s|^color_scheme_path=~|color_scheme_path=$HOME|" "$CONFIG_DIR/qt6ct/qt6ct.conf" 2>/dev/null || true
fi

# --- SwayNC : reload CSS in-place ---
if pgrep -x swaync > /dev/null; then
    swaync-client --reload-css 2>/dev/null || swaync-client -R 2>/dev/null || true
    echo "   SwayNC CSS reloaded"
fi

# --- Hyprland border colors: update via keyword (compatible across all versions) ---
if command -v hyprctl &>/dev/null && [ -f "$CONFIG_DIR/hypr/colors.lua" ]; then
    c1=$(grep "color1" "$CONFIG_DIR/hypr/colors.lua" | head -1 | sed "s/.*= \"\(.*\)\",/\1/" || true)
    c4=$(grep "color4" "$CONFIG_DIR/hypr/colors.lua" | head -1 | sed "s/.*= \"\(.*\)\",/\1/" || true)
    c8=$(grep "color8" "$CONFIG_DIR/hypr/colors.lua" | head -1 | sed "s/.*= \"\(.*\)\",/\1/" || true)
    if [ -n "$c1" ] && [ -n "$c4" ]; then
        hyprctl keyword general:col.active_border "rgba(${c1}ee) rgba(${c4}ee) 45deg" &>/dev/null || true
    fi
    if [ -n "$c8" ]; then
        hyprctl keyword general:col.inactive_border "rgba(${c8}ee)" &>/dev/null || true
    fi
    echo "   Hyprland border colors updated"
fi

# --- Chromium BrowserThemeColor Enterprise Policy Sync ---
chromium_theme=""
if [ -f "$CONFIG_DIR/matugen/chromium-theme.json" ]; then
    chromium_theme="$CONFIG_DIR/matugen/chromium-theme.json"
elif [ -f "$CONFIG_DIR/wallust/chromium-theme.json" ]; then
    chromium_theme="$CONFIG_DIR/wallust/chromium-theme.json"
fi

if [ -n "$chromium_theme" ]; then
    DEFAULTS_FILE="$CONFIG_DIR/hypr/defaults.lua"
    browser="brave-origin"
    if [ -f "$DEFAULTS_FILE" ]; then
        _v=$(sed -n 's/^BROWSER\s*=\s*"\(.*\)"/\1/p' "$DEFAULTS_FILE" | head -1)
        [ -n "$_v" ] && browser="$_v"
    fi
    unset _v

    target_dirs=()
    case "$browser" in
        *brave*)    target_dirs=("/etc/brave/policies/managed") ;;
        *chrome*)   target_dirs=("/etc/opt/chrome/policies/managed") ;;
        *chromium*) target_dirs=("/etc/chromium/policies/managed") ;;
        *edge*)     target_dirs=("/etc/opt/edge/policies/managed") ;;
        *vivaldi*)  target_dirs=("/etc/vivaldi/policies/managed") ;;
        *thorium*)  target_dirs=("/etc/thorium/policies/managed") ;;
        *)          target_dirs=("/etc/brave/policies/managed" "/etc/opt/chrome/policies/managed" "/etc/chromium/policies/managed") ;;
    esac

    for target_dir in "${target_dirs[@]}"; do
        mkdir -p "$target_dir" 2>/dev/null || true
        if cp "$chromium_theme" "$target_dir/color.json" 2>/dev/null; then
            echo "   Chromium policy theme updated ($target_dir/color.json)"
        elif command -v sudo &>/dev/null && sudo -n true 2>/dev/null; then
            sudo cp "$chromium_theme" "$target_dir/color.json" 2>/dev/null || true
            echo "   Chromium policy theme updated via sudo ($target_dir/color.json)"
        fi
    done
fi

echo ":: Theme reload complete!"
