#!/bin/bash
# Universal floating terminal wrapper for fzf dialogs and launchers
# Launches kitty in a dedicated floating class with appropriate dimensions

TITLE="${1:-FZF}"
WIDTH="${2:-800}"
HEIGHT="${3:-500}"
shift 3 2>/dev/null || shift $# 2>/dev/null

CMD="$@"

exec kitty --class "system-fzf" \
    --title "$TITLE" \
    -o initial_window_width="$WIDTH" \
    -o initial_window_height="$HEIGHT" \
    -o remember_window_size=no \
    -e bash -c "$CMD"
