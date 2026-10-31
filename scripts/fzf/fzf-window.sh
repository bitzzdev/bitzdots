#!/bin/bash
# Dedicated Kitty floating window launcher for system dialogs & fzf menus
# Makes Kitty a first-class floating UI menu with custom geometry, padding, and M3 styling

TITLE="${1:-Menu}"
WIDTH="${2:-800}"
HEIGHT="${3:-500}"
shift 3 2>/dev/null || shift $# 2>/dev/null

CMD="$@"

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
KITTY_CONF="$CONFIG_DIR/kitty/kitty.conf"

# Resolve font from kitty config to ensure consistency
FONT_FAMILY="JetBrainsMono Nerd Font"
if [ -f "$KITTY_CONF" ]; then
    _f=$(grep "^font_family" "$KITTY_CONF" 2>/dev/null | awk '{$1=""; print $0}' | sed 's/^[ \t]*//')
    [ -n "$_f" ] && FONT_FAMILY="$_f"
fi

exec kitty \
    --class "system-fzf" \
    --title "$TITLE" \
    -o remember_window_size=no \
    -o initial_window_width="$WIDTH" \
    -o initial_window_height="$HEIGHT" \
    -o window_padding_width=16 \
    -o hide_window_decorations=yes \
    -o confirm_os_window_close=0 \
    -o enable_audio_bell=no \
    -o font_size=11 \
    -o font_family="$FONT_FAMILY" \
    -e bash -c "export FZF_INNER=1; $CMD"
