#!/bin/bash
# Rofi clipboard manager using cliphist
# Usage: clipboard.sh           — copy mode
#        clipboard.sh --delete  — delete mode (SUPER+SHIFT+V)

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
ROFI_THEME="$CONFIG_DIR/rofi/themes/launcher.rasi"
DELETE_MODE=false
[ "${1:-}" = "--delete" ] && DELETE_MODE=true

if ! command -v cliphist &>/dev/null; then
    notify-send -u critical "cliphist not installed"
    exit 1
fi

if ! pgrep -f "cliphist store" > /dev/null; then
    wl-paste --watch cliphist store &
    sleep 0.5
fi

if ! entries=$(cliphist list 2>/dev/null); then
    notify-send -u critical "cliphist error" "Failed to read clipboard history"
    exit 1
fi

if [ -z "$entries" ]; then
    notify-send -u normal "Clipboard empty" "Copy something first, then use Super+V"
    exit 0
fi

if $DELETE_MODE; then
    PROMPT="Delete"
    KB_ENTER="Delete selection"
    KB_CUSTOM="Cancel"
else
    PROMPT="Copy"
    KB_ENTER="Copy selection"
    KB_CUSTOM="Cancel"
fi

selected=$(
    echo "$entries" | rofi -dmenu -i -p "$PROMPT" -theme "$ROFI_THEME" \
        -theme-str 'listview { columns: 1; lines: 10; spacing: 2px; padding: 6px; flow: vertical; } window { width: 620px; } element { orientation: horizontal; padding: 8px 12px; spacing: 12px; } element-icon { size: 22px; vertical-align: 0.5; } element-text { horizontal-align: 0; vertical-align: 0.5; text-color: @fg0; } entry { placeholder: ""; }'
)

if [ -z "$selected" ]; then
    exit 0
fi

item_id=$(echo "$selected" | cut -d'	' -f1)

if [ -z "$item_id" ]; then
    exit 0
fi

if $DELETE_MODE; then
    echo "$item_id" | cliphist delete
    notify-send "Clipboard" "Item #$item_id deleted"
else
    cliphist decode "$item_id" | wl-copy
    notify-send "Clipboard" "Item #$item_id copied"
fi
