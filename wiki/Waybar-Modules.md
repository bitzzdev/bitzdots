# Waybar Modules

Waybar is configured with **15 modules** in `waybar/config.jsonc`. Custom modules are styled by matugen so colors always match the wallpaper.

## Layout

```
Left:    custom/workspaces | custom/runcat | custom/media
Center:  clock
Right:   tray | custom/recording | custom/brightness | pulseaudio |
         cpu | memory | custom/power-profiles | custom/notification |
         network | bluetooth | custom/power
```

## Custom Modules

### custom/workspaces

Batch-based workspace display showing 5 workspaces at a time, centered on the active one.

- **Script**: `waybar/scripts/workspaces.sh`
- **Poll interval**: 2s
- **Icons**: `[N]` = active, `|N|` = occupied, `N` = empty
- **Click**: Focus workspace (via `workspace-click.sh`)
- **Scroll**: Cycle workspaces (prev/next)

### custom/runcat

CPU activity animation — a running cat that speeds up when CPU is busy.

- **Script**: `waybar/modules/runcat-text/main.py` (Python)
- **Output**: JSON with emoji/text animation based on CPU usage
- **Disable**: Remove from `modules-left` in config.jsonc for low-end systems

### custom/media

Now-playing media display with playerctl integration.

- **Script**: `waybar/scripts/media.sh`
- **Format**: `icon artist - title` (truncated)
- **On startup**: Kills stale `playerctl metadata --follow` processes to prevent CPU leaks
- **Click**: Play/Pause | **Right click**: Stop | **Scroll**: Next/Previous

### custom/recording

Screen recording indicator — blinks when `wf-recorder` is active.

- **Script**: `waybar/scripts/recording-indicator.sh`
- **Poll interval**: 10s
- **Output**: Empty normally, blinking icon when recording

### custom/brightness

Display backlight control.

- **Script**: `waybar/scripts/brightness.sh`
- **Poll interval**: 5s
- **Icons**: 4 levels (full, high, low, off) + percentage
- **Scroll**: Adjust brightness by ±5% (via `brightness-adjust.sh`)

### custom/power-profiles

UPower power profile management (power-saver / balanced / performance).

- **Script**: `waybar/scripts/power-profile.sh`
- **Poll interval**: 5s
- **Implementation**: Uses `busctl` directly on the UPower D-Bus interface (avoids hang-prone `powerprofilesctl`)
- **Click**: Cycle to next profile via `power-profile-switch.sh`

### custom/notification

Notification center toggle.

- **Script**: `waybar/scripts/notification.sh`
- **Poll interval**: 10s
- **Click**: Toggle panel (`swaync-client -t`)
- **Right click**: Toggle Do Not Disturb (`swaync-client -d`)

### custom/power

Power menu trigger.

- **No script** — uses format + `on-click` directly
- **Click**: Opens rofi power menu (`system-power.sh`)

## Built-in Modules

### clock

- **Format**: `{:%I:%M %p}` (12-hour), tooltip shows a calendar
- **Interval**: 30s

### network

- **Icons**: WiFi (4 signal levels), ethernet, disconnected
- **Tooltip**: `{essid} ({signalStrength}%)`
- **Click**: opens `impala` WiFi TUI via `tui-wifi.sh`
- **Interval**: 3s

### bluetooth

- **Icons**: off, on (no connection), connected
- **Click**: opens `bluetui` via `tui-bluetooth.sh`

### pulseaudio

- **Icons**: high, mid, low, muted (device-aware icons)
- **Format**: `{icon} {volume}%`
- **Click**: opens `pulsemixer` via `tui-audio.sh`
- **Scroll**: Volume ±5%

### cpu

- **Format**: `{usage}%` with CPU icon
- **Click**: opens `btop` via `tui-cpu.sh`
- **Interval**: 5s

### memory

- **Format**: `{percentage}%` with RAM icon
- **Click**: opens `btop`
- **Interval**: 10s

### tray

- Standard Wayland system tray, spacing 8px

## System TUI Pattern

All system tools open in floating kitty windows with class `system-tui` (auto-floated by `hypr/rules.lua`):

| Tool | Opens | Waybar Click |
|------|-------|--------------|
| **impala** | WiFi network manager | network |
| **bluetui** | Bluetooth manager | bluetooth |
| **pulsemixer** | Audio mixer | pulseaudio |
| **btop** | System monitor | cpu / memory |

## Adding a Module

1. Add to `waybar/config.jsonc`:
```jsonc
"custom/my-module": {
  "exec": "~/.config/waybar/scripts/my-script.sh",
  "interval": 10,
  "return-type": "json",
  "on-click": "some-command"
}
```
2. Style it in `waybar/style.css` (or the `waybar.css.j2` template for permanence)
3. Restart waybar: `pkill -x waybar && waybar &`

## Troubleshooting

```bash
# Restart waybar
pkill -x waybar && waybar &

# View logs
journalctl --user -u waybar -f

# Test a script manually
~/.config/waybar/scripts/workspaces.sh
```
