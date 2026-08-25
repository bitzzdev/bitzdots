# bitzdots

> Lean, performant Hyprland dotfiles with automatic matugen theming — optimized for low-end machines.

## Quick Start

```bash
git clone https://github.com/bitzzdev/bitzdots.git ~/.config/bitzdots
cd ~/.config/bitzdots
chmod +x install.sh

# Link configs only:
./install.sh

# Or link configs + install all system packages:
./install.sh --with-deps
```

## Key Features

- **Auto-coloring** — Pick any wallpaper; matugen generates 25 themed templates automatically across all apps
- **Low-end optimized** — Full desktop stack (Hyprland + waybar + swaync) idles under 300MB RAM
- **Rofi launchers** — App launcher, clipboard manager, power menu, wallpaper picker (grid with thumbnails)
- **Waybar with 15 modules** — Workspaces, runcat, media, clock, CPU, memory, network, bluetooth, recording indicator, power profiles, brightness, notifications, tray, power
- **Screenshot & recording** — Fullscreen and region screenshot (with `wl-copy` clipboard), fullscreen and region recording (with `wf-recorder`)
- **Fish + fastfetch** — Custom BITZ ASCII logo, clean terminal experience
- **Live wallpaper support** — Video wallpapers via `mpvpaper` with automatic palette extraction
- **55+ keybindings** — Fully keyboard-driven, including a resize submode

## Directory Structure

```
~/.config/bitzdots/
├── hypr/              # Hyprland config (9 Lua modules)
├── waybar/            # Bar config, styles, 17 scripts
├── rofi/              # Launcher config, 27 themes, 8 icons, scripts
├── swaync/            # Notification center
├── wlogout/           # Logout screen
├── kitty/             # Terminal config
├── cava/              # Audio visualizer
├── matugen/           # Theming engine (25 Jinja2 templates)
├── fish/              # Fish shell config
├── fastfetch/         # Fastfetch config with BITZ logo
├── scripts/           # 10 utility scripts
├── icons/             # Source SVG icons (linked to rofi)
├── environment.d/     # Qt environment variables
├── gtk/               # GTK3/4 dark theme settings
└── systemd/           # User services (matugen cache daemon)
```

## Performance

| Metric | Value |
|--------|-------|
| Idle RAM (full stack) | ~250-300MB |
| Waybar CPU | ~3.5% idle |
| Hyprland RAM | ~170MB |
| swaync RAM | ~85MB |
| Polling intervals | max 30s |
| Cache daemon priority | Nice=19, idle IO |

## Keybinds

| Key | Action |
|-----|--------|
| `SUPER`+`T` | Terminal (kitty) |
| `SUPER`+`Space` | App launcher (rofi) |
| `SUPER`+`Q` | Close window |
| `SUPER`+`R` | Start fullscreen recording |
| `SUPER`+`SHIFT`+`R` | Start region recording |
| `SUPER`+`S` | Stop recording |
| `Print` | Full screenshot |
| `SUPER`+`SHIFT`+`S` | Selection screenshot |
| `SUPER`+`SHIFT`+`W` | Wallpaper picker |
| `SUPER`+`N` | Toggle notifications |
| `SUPER`+`P` | Power menu |
| `SUPER`+`L` | Lock screen |

See the full [Keybindings](Keybindings) reference for all 55+ binds.

## Links

- [Installation](Installation)
- [Configuration](Configuration)
- [Keybindings](Keybindings)
- [Waybar Modules](Waybar-Modules)
- [Theming](Theming)
- [Scripts](Scripts)
- [FAQ](FAQ)
- [Performance](Performance)
- [Customization](Customization)
