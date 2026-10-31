#!/bin/bash
# fzf Clipboard Manager using cliphist
# Usage: clipboard.sh           — copy mode
#        clipboard.sh --delete  — delete mode

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
[ -f "$CONFIG_DIR/matugen/fzf-colors.sh" ] && source "$CONFIG_DIR/matugen/fzf-colors.sh"

DELETE_MODE=false
[ "${1:-}" = "--delete" ] && DELETE_MODE=true
[ "${2:-}" = "--delete" ] && DELETE_MODE=true

run_inside() {
    if ! command -v cliphist &>/dev/null; then
        echo "cliphist is not installed."
        read -r
        exit 1
    fi

    if ! pgrep -f "cliphist store" > /dev/null; then
        wl-paste --watch cliphist store &
        sleep 0.3
    fi

    local entries
    if ! entries=$(cliphist list 2>/dev/null) || [ -z "$entries" ]; then
        echo "Clipboard history is empty."
        sleep 1
        exit 0
    fi

    local prompt_text=" Copy > "
    local header_text="[Enter] Copy selection, [Esc] Exit"
    if $DELETE_MODE; then
        prompt_text=" Delete > "
        header_text="[Enter] Delete item from clipboard history, [Esc] Exit"
    fi

    local selected
    selected=$(echo "$entries" | fzf \
        --prompt="$prompt_text" \
        --header="$header_text" \
        --preview='echo -e "\033[1;36mClipboard Entry:\033[0m\n"; echo {} | cut -f2- | fold -s -w 70' \
        --preview-window='right:50%:wrap')

    [ -z "$selected" ] && exit 0

    local item_id
    item_id=$(echo "$selected" | cut -d$'\t' -f1)
    [ -z "$item_id" ] && exit 0

    if $DELETE_MODE; then
        echo "$item_id" | cliphist delete
        notify-send "Clipboard" "Item #$item_id deleted" 2>/dev/null || true
    else
        cliphist decode "$item_id" | wl-copy
        notify-send "Clipboard" "Copied to clipboard" 2>/dev/null || true
    fi
}

if [ "${1:-}" = "--inner" ] || [ "${2:-}" = "--inner" ]; then
    run_inside
else
    mode_arg=""
    $DELETE_MODE && mode_arg="--delete"
    "$CONFIG_DIR/fzf/fzf-window.sh" "Clipboard Manager" 880 500 "$CONFIG_DIR/fzf/clipboard.sh --inner $mode_arg"
fi
