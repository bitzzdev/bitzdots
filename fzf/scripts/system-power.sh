#!/bin/bash
# fzf Power Menu (Lock, Logout, Sleep, Reboot, Shutdown)

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
[ -f "$CONFIG_DIR/matugen/fzf-colors.sh" ] && source "$CONFIG_DIR/matugen/fzf-colors.sh"

run_inside() {
    local options=(
        "  Lock Screen"
        "󰍃  Log Out"
        "󰤄  Sleep (Suspend)"
        "󰜉  Reboot System"
        "  Power Off"
        "󰅖  Cancel"
    )

    local choice
    choice=$(printf "%s\n" "${options[@]}" | fzf \
        --prompt=" Power > " \
        --header="Select system power action:" \
        --height=100% \
        --layout=reverse \
        --no-info)

    case "$choice" in
        *"Lock"*)     hyprlock ;;
        *"Log Out"*)  "$HOME/.local/bin/hyprlogout" ;;
        *"Sleep"*)    systemctl suspend ;;
        *"Reboot"*)   systemctl reboot ;;
        *"Power Off"*) systemctl poweroff ;;
        *)            exit 0 ;;
    esac
}

if [ "${1:-}" = "--inner" ]; then
    run_inside
else
    "$CONFIG_DIR/fzf/fzf-window.sh" "Power Menu" 380 260 "$CONFIG_DIR/fzf/system-power.sh --inner"
fi
