local S  = "SUPER"
local AL = "ALT"
local SA = "SUPER + ALT"
local SS = "SUPER + SHIFT"
local SC = "SUPER + CTRL"

-- Terminal
hl.bind(S .. " + T", hl.dsp.exec_cmd(TERMINAL))

-- Close active window
hl.bind(S .. " + Q", hl.dsp.window.close())

-- File manager (Nautilus)
hl.bind(S .. " + E", hl.dsp.exec_cmd(FILE_EXPLORER))

-- Fullscreen
hl.bind(S .. " + F", hl.dsp.window.fullscreen())

-- Browser (Chromium ignores GTK theming; force dark chrome)
hl.bind(S .. " + W", hl.dsp.exec_cmd(BROWSER .. " --force-dark-mode"))

-- Lock screen
hl.bind(S .. " + L", hl.dsp.exec_cmd("hyprlock"))

-- Mouse: move window
hl.bind(S .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })

-- Mouse: resize window
hl.bind(S .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Resize mode (SUPER+CTRL+R)
hl.bind(SC .. " + R", hl.dsp.submap("resize"))
hl.define_submap("resize", function()
    hl.bind("right",      hl.dsp.window.resize({ x = 10,  y = 0,    relative = true }), { repeating = true })
    hl.bind("left",       hl.dsp.window.resize({ x = -10, y = 0,    relative = true }), { repeating = true })
    hl.bind("up",         hl.dsp.window.resize({ x = 0,   y = -10,  relative = true }), { repeating = true })
    hl.bind("down",       hl.dsp.window.resize({ x = 0,   y = 10,   relative = true }), { repeating = true })
    hl.bind("Escape",     hl.dsp.submap("reset"))
    hl.bind(SC .. " + R", hl.dsp.submap("reset"))
    hl.bind("catchall",   hl.dsp.submap("reset"))
end)

-- Workspace 1-9
for i = 1, 9 do
    hl.bind(S  .. " + " .. i,           hl.dsp.focus({ workspace = i }))
    hl.bind(SS .. " + " .. i,           hl.dsp.window.move({ workspace = i }))
end
hl.bind(S  .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(SS .. " + 0", hl.dsp.window.move({ workspace = 10 }))

-- Cycle workspaces with mouse wheel
hl.bind(S .. " + mouse_down", hl.dsp.focus({ workspace = "+1" }))
hl.bind(S .. " + mouse_up",   hl.dsp.focus({ workspace = "-1" }))

-- Move focused window to adjacent workspace with SUPER+ALT+scroll
hl.bind(SA .. " + mouse_down", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(SA .. " + mouse_up",   hl.dsp.window.move({ workspace = "-1" }))

-- SUPER+SHIFT+scroll same behavior
hl.bind(SS .. " + mouse_down", hl.dsp.window.move({ workspace = "+1" }))
hl.bind(SS .. " + mouse_up",   hl.dsp.window.move({ workspace = "-1" }))

-- Selection screenshot: grim + slurp + save to Freeform/
hl.bind(SS .. " + S", hl.dsp.exec_cmd("f=~/Pictures/Screenshots/Freeform/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png; grim -g \"$(slurp)\" \"$f\" && wl-copy < \"$f\" && notify-send 'Screenshot' 'Saved & Copied' || notify-send -u critical 'Screenshot' 'Canceled'"))

-- OCR screenshot
hl.bind(SS .. " + T", hl.dsp.exec_cmd("~/.local/bin/eink-ocr"))

-- Print screen: full screenshot
hl.bind("Print", hl.dsp.exec_cmd("f=~/Pictures/Screenshots/Fullscreen/screenshot_$(date +%Y-%m-%d_%H-%M-%S).png; grim \"$f\" && wl-copy < \"$f\" && notify-send 'Screenshot' 'Saved & Copied' || notify-send -u critical 'Screenshot' 'Failed'"))

-- Color picker (copies hex to clipboard)
hl.bind(SS .. " + C", hl.dsp.exec_cmd("hyprpicker -a && notify-send \"Color picked\" \"$(wl-paste)\""))

-- Notifications
hl.bind(S .. " + N", hl.dsp.exec_cmd("swaync-client -t"))

-- Rofi launcher
hl.bind(S .. " + space", hl.dsp.exec_cmd("rofi -show drun -theme ~/.config/rofi/themes/launcher.rasi"))

-- Spotlight search (apps, commands, files, windows) — on-demand, no daemon
hl.bind(AL .. " + space", hl.dsp.exec_cmd("~/.config/rofi/scripts/spotlight.sh"))

-- Power menu
hl.bind(S .. " + P", hl.dsp.exec_cmd("~/.config/rofi/scripts/system-power.sh"))

-- Clipboard history
hl.bind(S  .. " + V", hl.dsp.exec_cmd("~/.config/rofi/scripts/clipboard.sh"))
hl.bind(SS .. " + V", hl.dsp.exec_cmd("~/.config/rofi/scripts/clipboard.sh --delete"))
hl.bind(SA .. " + V", hl.dsp.exec_cmd("cliphist wipe"))

-- Additional useful binds
hl.bind(SC .. " + Q", hl.dsp.exit())
hl.bind(SC .. " + F", hl.dsp.window.float({ action = "toggle" }))
hl.bind(S  .. " + H", hl.dsp.window.float({ action = "toggle" }))
hl.bind(SS .. " + space", hl.dsp.exec_cmd("wofi --show drun"))
hl.bind(S  .. " + C",     hl.dsp.exec_cmd("chromium --force-dark-mode"))

-- Wallpaper selector
hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("~/.config/wallust/wallpaper-select.sh"))

-- Multimedia keys (laptop keyboard)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("~/.config/waybar/scripts/brightness-adjust.sh down"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("~/.config/waybar/scripts/brightness-adjust.sh up"),   { locked = true, repeating = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Screen recording: SUPER+R / SUPER+SHIFT+R to start, SUPER+S to stop any
hl.bind(S  .. " + R",  hl.dsp.exec_cmd("~/.config/wallust/record-fullscreen.sh"))
hl.bind(SS .. " + R",  hl.dsp.exec_cmd("~/.config/wallust/record-region.sh"))
hl.bind(S  .. " + S",  hl.dsp.exec_cmd("pkill -x wf-recorder 2>/dev/null && notify-send 'Recording' 'Stopped'"))
