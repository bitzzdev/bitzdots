#!/bin/bash
# fzf Application Launcher (.desktop files parser & runner)

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
[ -f "$CONFIG_DIR/matugen/fzf-colors.sh" ] && source "$CONFIG_DIR/matugen/fzf-colors.sh"

run_inside() {
    local apps_list=()
    local desktop_dirs=(
        "$HOME/.local/share/applications"
        "/usr/local/share/applications"
        "/usr/share/applications"
    )

    # Collect .desktop files
    local -A seen_apps
    local desktop_files=()
    for d in "${desktop_dirs[@]}"; do
        if [ -d "$d" ]; then
            while IFS= read -r f; do
                [ -n "$f" ] && desktop_files+=("$f")
            done < <(find "$d" -name "*.desktop" -type f 2>/dev/null)
        fi
    done

    # Parse names and exec lines
    local menu_items=""
    for df in "${desktop_files[@]}"; do
        # Skip if NoDisplay=true
        if grep -qi "^NoDisplay=true" "$df" 2>/dev/null; then
            continue
        fi

        local name; name=$(grep -m1 "^Name=" "$df" 2>/dev/null | cut -d= -f2-)
        local comment; comment=$(grep -m1 "^Comment=" "$df" 2>/dev/null | cut -d= -f2-)
        local exec_cmd; exec_cmd=$(grep -m1 "^Exec=" "$df" 2>/dev/null | cut -d= -f2- | sed 's/ %[a-zA-Z]//g')

        [ -z "$name" ] && continue
        [ -z "$exec_cmd" ] && continue
        [ -n "${seen_apps[$name]:-}" ] && continue
        seen_apps["$name"]=1

        # Format: Name \t Comment \t Exec
        menu_items+="${name}\t${comment}\t${exec_cmd}\n"
    done

    local selected
    selected=$(echo -e "$menu_items" | fzf \
        --delimiter='\t' \
        --with-nth=1,2 \
        --preview='echo -e "\033[1;36mCommand:\033[0m {3}\n\n\033[1;33mDescription:\033[0m {2}"' \
        --preview-window='down:3:wrap' \
        --header='Press [Enter] to launch, [Esc] to exit' \
        --prompt='󰀻 Launch > ')

    if [ -n "$selected" ]; then
        local cmd
        cmd=$(echo "$selected" | cut -f3)
        if [ -n "$cmd" ]; then
            nohup bash -c "$cmd" >/dev/null 2>&1 &
        fi
    fi
}

if [ "${1:-}" = "--inner" ] || [ -n "${FZF_INNER:-}" ]; then
    run_inside
else
    win_launcher="$CONFIG_DIR/fzf/fzf-window.sh"
    [ ! -f "$win_launcher" ] && win_launcher="$(dirname "$0")/../../scripts/fzf/fzf-window.sh"
    self_script="$CONFIG_DIR/fzf/launcher.sh"
    [ ! -f "$self_script" ] && self_script="$(realpath "$0")"
    exec "$win_launcher" "Application Launcher" 850 520 "$self_script --inner"
fi
