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

if [ "${1:-}" = "--inner" ] || [ -n "${FZF_INNER:-}" ]; then
    run_inside
else
    win_launcher="$CONFIG_DIR/fzf/fzf-window.sh"
    [ ! -f "$win_launcher" ] && win_launcher="$(dirname "$0")/../../scripts/fzf/fzf-window.sh"
    self_script="$CONFIG_DIR/fzf/system-power.sh"
    [ ! -f "$self_script" ] && self_script="$(realpath "$0")"
    exec "$win_launcher" "Power Menu" 380 260 "$self_script --inner"
fi
