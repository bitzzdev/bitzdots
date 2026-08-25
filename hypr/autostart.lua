hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor catppuccin-mocha-dark-cursors 24")
    hl.exec_cmd("waybar &")
    hl.exec_cmd("swaync &")
    hl.exec_cmd("polkit-kde-authentication-agent-1")
    hl.exec_cmd("wl-paste --watch cliphist store")

    -- Start wallpaper daemon and restore last wallpaper
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("bash -c 'sleep 0.5 && test -f $HOME/.cache/current_wallpaper.png && awww img $HOME/.cache/current_wallpaper.png'")

    -- Workspace event monitor for instant waybar updates
    hl.exec_cmd("bash -c '~/.config/waybar/scripts/workspace-monitor.sh &'")

    -- Ensure WiFi is up: wait for NetworkManager, then reconnect if needed.
    -- Prevents the "strikethrough WiFi" waybar icon and impala crashes on boot.
    hl.exec_cmd("bash -c 'sleep 3 && ~/.config/matugen/wifi-fix.sh &'")

    -- Matugen palette cache daemon runs as a systemd user service
    -- (matugen-cache-daemon.service) — no need to start it here

    -- Restart portal to prevent CPU loop (known xdg-desktop-portal-hyprland 1.4.x bug)
    hl.exec_cmd("bash -c 'sleep 3 && systemctl --user restart xdg-desktop-portal-hyprland &>/dev/null'")
end)
