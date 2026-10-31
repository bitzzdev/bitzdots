#!/usr/bin/env bash

backlight_device=""
current=""
max=""

get_brightnessctl() {
    if ! command -v brightnessctl &>/dev/null; then
        return 1
    fi

    if [ -n "$backlight_device" ]; then
        local c m
        c=$(timeout 2 brightnessctl -d "$backlight_device" g 2>/dev/null)
        m=$(timeout 2 brightnessctl -d "$backlight_device" m 2>/dev/null)
        if [ -n "$c" ] && [ -n "$m" ] && [ "$m" -gt 0 ] 2>/dev/null; then
            current=$c; max=$m; return 0
        fi
    fi

    local c m
    c=$(timeout 2 brightnessctl g 2>/dev/null)
    m=$(timeout 2 brightnessctl m 2>/dev/null)
    if [ -n "$c" ] && [ -n "$m" ] && [ "$m" -gt 0 ] 2>/dev/null; then
        current=$c; max=$m; return 0
    fi

    local dev
    dev=$(timeout 2 brightnessctl -l 2>/dev/null | grep -oP "'[^']+'" | head -1 | tr -d "'")
    if [ -n "$dev" ]; then
        backlight_device="$dev"
        local c m
        c=$(timeout 2 brightnessctl -d "$dev" g 2>/dev/null)
        m=$(timeout 2 brightnessctl -d "$dev" m 2>/dev/null)
        if [ -n "$c" ] && [ -n "$m" ] && [ "$m" -gt 0 ] 2>/dev/null; then
            current=$c; max=$m; return 0
        fi
    fi

    return 1
}

get_sysfs() {
    local devs
    devs=$(ls /sys/class/backlight/ 2>/dev/null)
    [ -z "$devs" ] && return 1

    for d in $devs; do
        local dir="/sys/class/backlight/$d"
        local c m
        c=$(cat "$dir/actual_brightness" 2>/dev/null)
        m=$(cat "$dir/max_brightness" 2>/dev/null)
        if [ -n "$c" ] && [ -n "$m" ] && [ "$m" -gt 0 ] 2>/dev/null; then
            current=$c; max=$m; return 0
        fi
    done

    return 1
}

get_light() {
    command -v light &>/dev/null || return 1
    local c m
    c=$(timeout 2 light -G 2>/dev/null)
    [ -z "$c" ] && return 1
    c=${c%.*}
    m=100
    if [ -n "$c" ] && [ "$c" -ge 0 ] 2>/dev/null; then
        current=$c; max=$m; return 0
    fi
    return 1
}

if ! get_brightnessctl && ! get_sysfs && ! get_light; then
    printf '{"text":" <span font_desc=\x27JetBrainsMono Nerd Font\x27>󰃜</span> N/A","tooltip":"Brightness: N/A","class":""}\n'
    exit 0
fi

pct=$(( current * 100 / max ))

if [ "$pct" -ge 80 ]; then
    icon="󰃠"
elif [ "$pct" -ge 50 ]; then
    icon="󰃟"
elif [ "$pct" -ge 20 ]; then
    icon="󰃝"
else
    icon="󰃜"
fi

printf '{"text":"<span font_desc=\x27JetBrainsMono Nerd Font\x27>%s</span> %s%%","tooltip":"Brightness: %s%%","class":""}\n' \
    "$icon" "$pct" "$pct"
