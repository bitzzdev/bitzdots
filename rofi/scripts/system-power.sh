#!/bin/bash
ICON_DIR="$HOME/.config/rofi/icons"

choice=$(
    printf '%s\0icon\x1f%s\n' \
        "Lock"     "$ICON_DIR/lock.svg" \
        "Logout"   "$ICON_DIR/logout.svg" \
        "Sleep"    "$ICON_DIR/sleep.svg" \
        "Reboot"   "$ICON_DIR/reboot.svg" \
        "Shutdown" "$ICON_DIR/shutdown.svg" \
        "Cancel"   "$ICON_DIR/cancel.svg" \
    | rofi -dmenu -show-icons -p "Power" -theme "$HOME/.config/rofi/themes/power.rasi"
)

case "$choice" in
    *Lock)     hyprlock ;;
    *Logout)   hyprlogout ;;
    *Sleep)    systemctl suspend ;;
    *Reboot)   systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
    *Cancel|*) exit 0 ;;
esac
