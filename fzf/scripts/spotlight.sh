#!/bin/bash
# fzf Spotlight Search across Applications, Files/Folders, and Web Search

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
DEFAULTS_FILE="$CONFIG_DIR/hypr/defaults.lua"

[ -f "$CONFIG_DIR/matugen/fzf-colors.sh" ] && source "$CONFIG_DIR/matugen/fzf-colors.sh"

browser="brave-origin"
file_explorer="nautilus"
if [ -f "$DEFAULTS_FILE" ]; then
    _b=$(sed -n 's/^BROWSER\s*=\s*"\(.*\)"/\1/p' "$DEFAULTS_FILE" | head -1)
    [ -n "$_b" ] && browser="$_b"
    _f=$(sed -n 's/^FILE_EXPLORER\s*=\s*"\(.*\)"/\1/p' "$DEFAULTS_FILE" | head -1)
    [ -n "$_f" ] && file_explorer="$_f"
fi

run_inside() {
    # Generate unified candidate list
    local candidates=""

    # 1. Applications
    for d in "$HOME/.local/share/applications" "/usr/share/applications"; do
        if [ -d "$d" ]; then
            while IFS= read -r f; do
                [ -z "$f" ] && continue
                grep -qi "^NoDisplay=true" "$f" 2>/dev/null && continue
                local name; name=$(grep -m1 "^Name=" "$f" 2>/dev/null | cut -d= -f2-)
                local cmd; cmd=$(grep -m1 "^Exec=" "$f" 2>/dev/null | cut -d= -f2- | sed 's/ %[a-zA-Z]//g')
                [ -n "$name" ] && [ -n "$cmd" ] && candidates+="[App]  ${name}\t${cmd}\n"
            done < <(find "$d" -name "*.desktop" -type f 2>/dev/null)
        fi
    done

    # 2. Frequent/Recent user files and directories
    while IFS= read -r p; do
        [ -n "$p" ] && candidates+="[File] ${p}\t${p}\n"
    done < <(find "$HOME" -maxdepth 3 \( -path '*/.*' -o -path '*/venv*' -o -path '*/node_modules*' \) -prune -o -type f -print 2>/dev/null | head -n 300)

    while IFS= read -r p; do
        [ -n "$p" ] && candidates+="[Dir]  ${p}\t${p}\n"
    done < <(find "$HOME" -maxdepth 2 \( -path '*/.*' \) -prune -o -type d -print 2>/dev/null | head -n 100)

    local selected
    selected=$(echo -e "$candidates" | fzf \
        --delimiter='\t' \
        --with-nth=1 \
        --print-query \
        --prompt=" Search > " \
        --header="Type to filter apps/files, or press [Enter] to web search query" \
        --preview='echo -e "\033[1;36mTarget:\033[0m {2}"' \
        --preview-window='down:2:wrap')

    local query; query=$(echo "$selected" | head -n 1)
    local match; match=$(echo "$selected" | sed -n '2p')

    if [ -n "$match" ]; then
        local type; type=$(echo "$match" | cut -d' ' -f1)
        local target; target=$(echo "$match" | cut -f2)

        case "$type" in
            "[App]")
                nohup bash -c "$target" >/dev/null 2>&1 &
                ;;
            "[Dir]")
                nohup "$file_explorer" "$target" >/dev/null 2>&1 &
                ;;
            "[File]")
                nohup xdg-open "$target" >/dev/null 2>&1 &
                ;;
        esac
    elif [ -n "$query" ]; then
        # Search the web with current query
        local search_url="https://duckduckgo.com/?q=$(printf '%s' "$query" | jq -sRr @uri)"
        nohup "$browser" "$search_url" >/dev/null 2>&1 &
    fi
}

if [ "${1:-}" = "--inner" ]; then
    run_inside
else
    "$CONFIG_DIR/fzf/fzf-window.sh" "Spotlight Search" 900 550 "$CONFIG_DIR/fzf/spotlight.sh --inner"
fi
