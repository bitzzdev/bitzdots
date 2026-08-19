# Theming

## Auto-Coloring Pipeline

bitzdots uses **wallust** to generate a complete color scheme from any wallpaper. The theming pipeline is fully automatic.

### How It Works

```
Select wallpaper
      ↓
wallust run wallpaper.jpg
      ↓
Generates 16-color palette (fastresize backend, saliencedark16 palette, salience colorspace)
      ↓
25 Jinja2 templates processed
      ↓
Configs written to 20+ files:
  ├── waybar/style.css + config.jsonc
  ├── swaync/style.css
  ├── wlogout/style.css
  ├── rofi/theme-generated.rasi + launcher/power/wallpaper-grid themes
  ├── rofi/icons/*.svg (8 icons)
  ├── hypr/colors.lua (borders)
  ├── kitty/colors.conf
  ├── cava/themes/generated
  ├── hypr/hyprlock.conf
  ├── qt6ct/qt6ct.conf, kdeglobals, bitzdots.colors
  └── wallust/env + browser-colors.css
      ↓
reload-theme.sh
      ↓
All apps pick up new colors instantly
```

## The 25 Templates

The `wallust/templates/` directory contains a Jinja2 template for every themed component:

| Template | Target | Purpose |
|----------|--------|---------|
| `waybar.css.j2` | `waybar/style.css` | Bar CSS |
| `waybar-config.jsonc.j2` | `waybar/config.jsonc` | Module layout |
| `swaync.css.j2` | `swaync/style.css` | Notification CSS |
| `wlogout.css.j2` | `wlogout/style.css` | Logout screen CSS |
| `hypr-colors.lua.j2` | `hypr/colors.lua` | Border colors |
| `kitty-colors.conf.j2` | `kitty/colors.conf` | Terminal palette |
| `cava-colors.j2` | `cava/themes/generated` | Audio visualizer |
| `rofi-colors.rasi.j2` | `rofi/theme-generated.rasi` | Rofi base theme |
| `launcher.rasi.j2` | `rofi/themes/launcher.rasi` | App launcher theme |
| `power.rasi.j2` | `rofi/themes/power.rasi` | Power menu theme |
| `wallpaper-grid.rasi.j2` | `rofi/themes/wallpaper-grid.rasi` | Wallpaper picker theme |
| `lock.svg.j2` | `rofi/icons/lock.svg` | Lock icon |
| `logout.svg.j2` | `rofi/icons/logout.svg` | Logout icon |
| `sleep.svg.j2` | `rofi/icons/sleep.svg` | Sleep icon |
| `reboot.svg.j2` | `rofi/icons/reboot.svg` | Reboot icon |
| `shutdown.svg.j2` | `rofi/icons/shutdown.svg` | Shutdown icon |
| `cancel.svg.j2` | `rofi/icons/cancel.svg` | Cancel icon |
| `static.svg.j2` | `rofi/icons/static.svg` | Static wallpaper icon |
| `live.svg.j2` | `rofi/icons/live.svg` | Live wallpaper icon |
| `hyprlock.conf.j2` | `hypr/hyprlock.conf` | Lock screen |
| `kdeglobals.j2` | `kdeglobals` | KDE colors |
| `qt6ct.conf.j2` | `qt6ct/qt6ct.conf` | Qt6 theme |
| `bitzdots.colors.j2` | `~/.local/share/color-schemes/bitzdots.colors` | KDE scheme |
| `wallust-env.j2` | `wallust/env` | Color environment variables |
| `browser-colors.css.j2` | `wallust/browser-colors.css` | Browser CSS |

## Template Variables

Templates use wallust's Jinja2 syntax with 16 colors:

```jinja
{{background}}    ← Main background
{{foreground}}    ← Primary text
{{color0}}        ← Background (terminal black)
{{color1}}        ← Red / primary accent
{{color2}}        ← Green
{{color3}}        ← Yellow
{{color4}}        ← Blue
{{color5}}        ← Magenta
{{color6}}        ← Cyan
{{color7}}        ← Foreground (terminal white)
{{color8-15}}     ← Bright / light variants
```

## Cache Daemon

`wallust-cache-daemon.service` (systemd user service):

1. **Watches** `~/Pictures/Wallpapers/` and `~/Pictures/Wallpapers/live/` via `inotifywait`
2. **Debounces** rapid file changes
3. **Pre-generates** palettes for every wallpaper in the background (Nice=19, idle IO)
4. **Skips** problematic images with a 24-hour failure cooldown
5. **Uses file locking** to prevent concurrent runs

This makes wallpaper switching instant — no waiting for wallust to run.

## Changing Theme

Simply run:

```bash
wallust run /path/to/new-wallpaper.jpg --config-dir ~/.config/wallust
~/.config/wallust/reload-theme.sh
```

Or use the picker: `SUPER + SHIFT + W` (or `~/.config/wallust/wallpaper-select.sh`).

## Backup/Restore Safety

Before every theme generation, the current configs are backed up. If wallust fails, the previous theme is restored automatically — a bad wallpaper never breaks your setup.

## Wallpapers

- Static wallpapers → `~/Pictures/Wallpapers/`
- Live wallpapers (`.mp4`, `.webm`, `.mkv`, `.gif`) → `~/Pictures/Wallpapers/live/`

Displayed with `awww` (animated transitions) or `mpvpaper` (video wallpapers). Live wallpapers extract a frame with ffmpeg for palette generation.
