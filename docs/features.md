# Features

Complete overview of everything bitzdots has to offer.

## 1. Automatic Color Theming

The core feature. Every component derives its colors from your current wallpaper.

### How It Works

1. **matugen** extracts a 16-color palette from your wallpaper using the fastresize backend (fast and reliable on low-end hardware)
2. **25 Jinja2 templates** render these colors into config files
3. **reload-theme.sh** notifies all running applications of the change
4. **Cache daemon** pre-generates palettes so switching wallpapers is instant

### Themed Components (20+)

| Component | What Gets Themed |
|-----------|-----------------|
| **Hyprland** | Active/inactive border colors (2-color gradient) |
| **Waybar** | Full CSS (background, text, module colors) + JSONC config |
| **Kitty** | Terminal 16-color palette |
| **Rofi** | Launcher, power menu, wallpaper picker themes |
| **SwayNC** | Notification center background, text, accent colors |
| **Wlogout** | Logout screen CSS |
| **Cava** | Audio visualizer color scheme |
| **Qt/KDE** | Full color scheme via qt6ct + kdeglobals |
| **GTK** | GTK settings.ini links |
| **Hyprlock** | Lock screen background and styling |
| **Browser** | CSS file for web-based theming |

## 2. Waybar Status Bar

Top-mounted, 26px height status bar with 15 modules:

- **Workspaces** — Batch display (5 at a time, centered on active). Click to focus, scroll to cycle
- **Runcat** — CPU activity animation (Python-based)
- **Media** — Now-playing display with play/pause/next/prev controls
- **Clock** — AM/PM format, calendar tooltip on hover
- **Network** — WiFi/ethernet icons with signal strength, click to open impala TUI
- **Bluetooth** — Connection status, click to open bluetui
- **Audio** — Volume slider, click to open pulsemixer
- **Brightness** — Backlight level with 4-tier icon, scroll to adjust
- **Power Profiles** — Current power profile (balanced/power-saver), click to cycle
- **CPU** — Usage percentage, click to open btop
- **Memory** — RAM usage, click to open btop
- **Recording** — Flashing indicator when screen recording
- **Notification** — Bell icon with DnD status, click to toggle panel
- **System Tray** — Standard Wayland system tray
- **Power** — Logout/restart/shutdown menu

## 3. Keyboard-Driven Interface

55+ keybindings for mouse-free operation. See [Keybindings](keybindings.md) for the full list.

## 4. Rofi Menus

Every system function has a keyboard-navigable rofi interface:

- **App Launcher** — `SUPER + Space`
- **Clipboard History** — `SUPER + V` to copy, `SUPER + SHIFT + V` to delete (cliphist integration)
- **Power Menu** — `SUPER + P` (lock, logout, sleep, reboot, shutdown)
- **Wallpaper Picker** — `SUPER + SHIFT + W` (static + live, grid with thumbnails)
- **Audio Menu** — Switch output/input devices, open pulsemixer
- **Bluetooth Menu** — Toggle, connect devices
- **WiFi Menu** — Connect to networks, toggle
- **System Monitor** — Open btop/htop

## 5. System TUI Pattern

All system tools open in floating Kitty windows with the `system-tui` class:
- Auto-float window rule for consistent behavior
- Centered, 800x600 default size
- Accessible via waybar click or keybind

| Tool | Function |
|------|----------|
| **btop** | System monitor (CPU, RAM, processes) |
| **pulsemixer** | Audio mixer |
| **impala** | WiFi network manager |
| **bluetui** | Bluetooth manager |
| **nmtui** | Network manager (fallback) |

## 6. Screenshots & Recording

- **Fullscreen screenshot** — `Print` → saves to `~/Pictures/Screenshots/Fullscreen/` + clipboard
- **Selection screenshot** — `SUPER + SHIFT + S` → select region with slurp → saves to `~/Pictures/Screenshots/Freeform/` + clipboard
- **OCR screenshot** — `SUPER + SHIFT + T` → select region, runs eink-ocr
- **Fullscreen recording** — `SUPER + R` → wf-recorder with audio → saves to `~/Videos/Recordings/Fullscreen/`
- **Region recording** — `SUPER + SHIFT + R` → select region → saves to `~/Videos/Recordings/Region/`

## 7. Notification Center

SwayNC-based notification center with:

- **MPRIS widget** — Now-playing with album art, play/pause/next/prev
- **Volume slider** — Master volume control
- **Backlight slider** — Screen brightness control
- **Quick toggles** — WiFi, Bluetooth, microphone mute, speaker mute
- **Do Not Disturb** mode
- **3-second notification timeout** for minimal intrusiveness

## 8. Wallpaper Management

- **Static wallpapers** via `awww` with animated crossfade transitions
- **Live video wallpapers** via `mpvpaper`
- **Cache daemon** pre-generates color palettes for all wallpapers in the background
- **Grid picker** with thumbnails for instant preview
- **Automatic color extraction** from both static images and video frames

## 9. Low-End Optimizations

- **CPU-efficient scripts** — All waybar polling scripts use minimal intervals where possible; power-profiles uses D-Bus directly (no hang-prone powerprofilesctl)
- **No playerctl leaks** — Media script kills stale `playerctl metadata --follow` processes on startup
- **Efficient workspace polling** — Uses `hyprctl workspaces -j` (lightweight) instead of `hyprctl clients -j`
- **Low-resource idle** — Full stack under 300MB RAM
- **Cache daemon runs at idle priority** — Nice=19, IO scheduling class=idle

## 10. Fish Shell + Fastfetch

- **Fish** with greeting disabled, `~/.cargo/bin` and `~/.local/bin` in PATH
- **Fastfetch** with custom BITZ ASCII logo, displays system info on terminal start
