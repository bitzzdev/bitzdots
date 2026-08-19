# Theming

How the automatic color theming pipeline works in bitzdots.

## Overview

```
Wallpaper image
    ↓ wallust (fastresize backend, saliencedark16 palette, salience colorspace)
16-color palette (background, foreground, 8 accent colors, 8 terminal colors)
    ↓ 25 Jinja2 templates
Config files for every component
    ↓ reload-theme.sh
All running apps pick up new colors
```

## The Pipeline in Detail

### 1. Color Extraction

**wallust** analyzes your wallpaper image using the `fastresize` backend and `salience` colorspace to extract a `saliencedark16` palette — extracting from highest available salient/contrasting color to lowest:

| Index | Usage |
|-------|-------|
| `background` / `color0` | Base backgrounds |
| `foreground` / `color15` | Primary text |
| `color1`-`color9` | Accent colors (active borders, highlights) |
| `color8`-`color15` | Terminal ANSI colors |

Contrast checking is enabled — wallust ensures text remains readable.

### 2. Template Rendering

25 Jinja2 templates in `wallust/templates/` use wallust color variables:

```jinja2
{{background}}       → #1a1218
{{foreground}}       → #f2dde4
{{color1}}           → #f4a0b8
{{color0}}           → #1a1218
{{color8}}           → #3d2838
```

Templates render into component config files:

```toml
# wallust.toml snippet
[waybar-css]
template = "waybar.css.j2"
target = "~/.config/waybar/style.css"

[kitty-colors]
template = "kitty-colors.conf.j2"
target = "~/.config/kitty/colors.conf"
```

### 3. Cache Daemon

The `wallust-cache-daemon.service` runs at low priority (Nice=19) and:

1. **Watches** `~/Pictures/Wallpapers/` and `~/Pictures/Wallpapers/live/` via `inotifywait`
2. **Debounces** file changes (waits for stability)
3. **Pre-generates** color palettes for every wallpaper in the background
4. **Skips** problematic images with a 24-hour cooldown to avoid repeating failures
5. **Uses file locking** to prevent concurrent runs

This means when you select a wallpaper from the picker, the theme applies instantly — no waiting for wallust to run.

### 4. Theme Reload

When a wallpaper is changed, `reload-theme.sh`:

1. Runs wallust to generate new configs from templates
2. Reloads swaync CSS (notifies swaync to re-read style.css)
3. Updates Hyprland border colors from `colors.lua`
4. Restarts waybar so all module colors refresh

## Backup/Restore Safety

Before every theme generation, the system:

1. **Backs up** all current generated config files to a timestamped directory
2. **Runs wallust** to generate new configs
3. **On failure**: restores the previous backup, logs the error
4. **On success**: keeps the backup for manual rollback

This means a bad wallpaper or failed wallust run never breaks your theme.

## Template Reference

All 25 templates in `wallust/templates/`:

| Template | Target | Purpose |
|---|---|---|
| `waybar.css.j2` | `waybar/style.css` | Bar CSS |
| `waybar-config.jsonc.j2` | `waybar/config.jsonc` | Bar module layout |
| `swaync.css.j2` | `swaync/style.css` | Notification CSS |
| `wlogout.css.j2` | `wlogout/style.css` | Logout screen CSS |
| `hypr-colors.lua.j2` | `hypr/colors.lua` | Border colors |
| `kitty-colors.conf.j2` | `kitty/colors.conf` | Terminal colors |
| `cava-colors.j2` | `cava/themes/generated` | Audio visualizer |
| `rofi-colors.rasi.j2` | `rofi/theme-generated.rasi` | Launcher theme |
| `wallust-env.j2` | `wallust/env` | Color env vars |
| `browser-colors.css.j2` | `wallust/browser-colors.css` | Browser CSS |
| `hyprlock.conf.j2` | `hypr/hyprlock.conf` | Lock screen |
| `kdeglobals.j2` | `kdeglobals` | KDE colors |
| `qt6ct.conf.j2` | `qt6ct/qt6ct.conf` | Qt6 theme |
| `bitzdots.colors.j2` | `color-schemes/bitzdots.colors` | KDE scheme |
| `launcher.rasi.j2` | `rofi/themes/launcher.rasi` | Launcher theme |
| `power.rasi.j2` | `rofi/themes/power.rasi` | Power menu theme |
| `wallpaper-grid.rasi.j2` | `rofi/themes/wallpaper-grid.rasi` | Wallpaper picker |
| `lock.svg.j2` | `rofi/icons/lock.svg` | Lock icon |
| `logout.svg.j2` | `rofi/icons/logout.svg` | Logout icon |
| `reboot.svg.j2` | `rofi/icons/reboot.svg` | Reboot icon |
| `shutdown.svg.j2` | `rofi/icons/shutdown.svg` | Shutdown icon |
| `sleep.svg.j2` | `rofi/icons/sleep.svg` | Sleep icon |
| `cancel.svg.j2` | `rofi/icons/cancel.svg` | Cancel icon |
| `static.svg.j2` | `rofi/icons/static.svg` | Static wallpaper icon |
| `live.svg.j2` | `rofi/icons/live.svg` | Live wallpaper icon |

## Adding a New Themed Component

See [Customization](customization.md) for the step-by-step guide.

## Manual Theme Regeneration

```bash
# Regenerate from current wallpaper
wallust run ~/.cache/current_wallpaper.png --config-dir ~/.config/wallust

# Regenerate from a specific image
wallust run ~/Pictures/Wallpapers/image.jpg --config-dir ~/.config/wallust

# Apply the new theme
~/.config/wallust/reload-theme.sh
```
