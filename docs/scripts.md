# Scripts

Reference for all scripts in bitzdots.

## Waybar Scripts (`waybar/scripts/`)

17 scripts powering the waybar custom modules.

| Script | Purpose | Used By |
|--------|---------|---------|
| `brightness.sh` | Outputs current brightness % with 4-tier icon as JSON | `custom/brightness` |
| `launch.sh` | Ensures waybar + swaync are running | Autostart |
| `media.sh` | playerctl metadata follower (artist/title/album/status) | `custom/media` |
| `notification.sh` | Bell icon with DnD/notification count | `custom/notification` |
| `power-profile.sh` | Queries UPower via D-Bus for active profile icon | `custom/power-profiles` |
| `power-profile-switch.sh` | Cycles to next available power profile via D-Bus | Click handler |
| `system-power.sh` | Rofi power menu (Lock/Logout/Sleep/Reboot/Shutdown) | `custom/power` |
| `tui-audio.sh` | Opens pulsemixer in floating kitty | Audio click (waybar) |
| `tui-bluetooth.sh` | Opens bluetui in floating kitty | Bluetooth click (waybar) |
| `tui-wifi.sh` | Waits for NetworkManager, then opens impala in floating kitty | Network click (waybar) |
| `tui-cpu.sh` | Opens btop in floating kitty | CPU click (waybar) |
| `weather.sh` | Fetches weather from wttr.in (30-min cache) | Optional module |
| `workspaces.sh` | Batch workspace display (5 at a time) | `custom/workspaces` |
| `workspace-click.sh` | Determines clicked workspace from pixel offset | Workspace click |
| `workspace-next.sh` | Focus next workspace | Scroll up |
| `workspace-prev.sh` | Focus previous workspace | Scroll down |

## Utility Scripts (`scripts/`)

10 core scripts for theming and recording.

### `reload-theme.sh`

Applies the generated theme to all running components.

```bash
~/.config/matugen/reload-theme.sh
```

**What it does:**
1. Reloads swaync CSS (`swaync-client --reload-css`)
2. Updates Hyprland border colors from `colors.lua`
3. Fixes qt6ct config path if needed
4. Restarts waybar for full refresh

### `wallpaper-select.sh`

Rofi-based wallpaper picker with grid thumbnails.

```bash
~/.config/matugen/wallpaper-select.sh                    # Open picker UI
~/.config/matugen/wallpaper-select.sh /path/to/image.jpg  # Direct set
```

**Features:**
- Grid display of all wallpapers with ImageMagick thumbnails
- Separate sections for static wallpapers and live wallpapers
- Cached theme switching — uses pre-generated palettes when available
- Backup/restore safety on all theme generations
- Restarts waybar after theme change

### `cache-wallpapers.sh`

One-shot pre-cache all wallpapers.

```bash
~/.config/matugen/cache-wallpapers.sh
```

Generates matugen palettes and ImageMagick thumbnails for every wallpaper in the directories.

### `matugen-cache-daemon.sh`

Event-driven background cache daemon.

```bash
~/.config/matugen/matugen-cache-daemon.sh
```

**Features:**
- Watches wallpaper directories with `inotifywait`
- Debounces rapid file changes
- Pre-generates palettes in background
- 24-hour failure cooldown for problematic images
- File locking for single-instance safety
- Runs at idle priority (Nice=19)

### `record-fullscreen.sh`

Toggle fullscreen screen recording.
```bash
~/.config/matugen/record-fullscreen.sh
```

- Uses `wf-recorder` with audio (pulse audio)
- Toggles: first call starts, second call stops
- Saves to `~/Videos/Recordings/Fullscreen/` with timestamped filename
- Shows start/stop notifications

### `record-region.sh`

Toggle region screen recording.

```bash
~/.config/matugen/record-region.sh
```

- Uses `slurp` for region selection + `wf-recorder` with audio
- Same toggle behavior as fullscreen
- Saves to `~/Videos/Recordings/Region/`

### `recording-indicator.sh`

Blinking indicator for waybar recording module.

- Called by waybar polling (10s interval)
- Outputs empty JSON when not recording
- Alternates between empty and icon JSON when recording (creates blink effect)

### `hyprlock-setup.sh`

Generates a basic `hyprlock.conf` from current wallpaper.

```bash
~/.config/matugen/hyprlock-setup.sh
```

- Uses current wallpaper as lock screen background
- Sets JetBrainsMono font for the clock/date

### `wifi-fix.sh`

Boot-time WiFi stabilizer. Called from `hypr/autostart.lua` a few seconds after login.

```bash
~/.config/matugen/wifi-fix.sh
```

**What it does:**
1. Waits for NetworkManager to appear on D-Bus (up to 30s)
2. Unblocks the WiFi radio (`rfkill unblock wifi`, `nmcli radio wifi on`)
3. Waits for an active connection (up to 45s)
4. If still offline, reactivates every saved connection
5. Retries with a radio toggle (off/on) if needed

Fixes the boot-time "strikethrough WiFi" waybar icon and impala crashes caused by NetworkManager not being ready.

## Rofi Scripts (`rofi/scripts/`)

### `clipboard.sh`

Clipboard history manager.

```bash
~/.config/rofi/scripts/clipboard.sh              # copy mode
~/.config/rofi/scripts/clipboard.sh --delete      # delete mode
```

- Lists recent clipboard entries from cliphist
- Default mode (`SUPER+V`): decodes and copies selected entry back to clipboard
- Delete mode (`SUPER+SHIFT+V`): removes selected entry from clipboard history
- Starts cliphist store daemon if not running
- Keyboard navigable via rofi

### `spotlight.sh`

Spotlight-style search (`ALT+SPACE`). One rofi prompt that searches installed
applications, files, folders and the web — live suggestions as you type, each
with its icon (app logo, folder icon, or browser logo). On-demand only: rofi
exits when the menu closes, no background daemon.

```bash
~/.config/rofi/scripts/spotlight.sh
```

- Type to filter apps / folders / files under `$HOME` live
- `Search the web` (always visible at the top) opens the default browser with
  the typed query; pressing Enter with no matching row also does a web search
- Apps launch via their `.desktop` entry; files/folders open in the default
  file explorer (`$FILE_EXPLORER`)
- Uses the same matugen-generated rofi template theme as the launcher
  (`launcher.rasi`); defaults are read from `hypr/defaults.lua`
  (`BROWSER`, `FILE_EXPLORER`)

### `system-power.sh`

Power management menu.

```bash
~/.config/rofi/scripts/system-power.sh
```

Options:
- **Lock** — `hyprlock`
- **Logout** — `hyprctl dispatch exit`
- **Sleep** — `systemctl suspend`
- **Reboot** — `systemctl reboot`
- **Shutdown** — `systemctl poweroff`
- **Cancel** — Close menu

Uses themed SVG icons from rofi icons directory.
