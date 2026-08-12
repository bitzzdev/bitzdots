# Getting Started

Quick start guide for first-time bitzdots users.

## Prerequisites

- A working Hyprland installation
- Git
- `~/.config/` directory exists
- Basic familiarity with the terminal

## One-Command Install

```bash
git clone https://github.com/bitzzdev/bitzdots.git ~/.config/bitzdots
cd ~/.config/bitzdots
chmod +x install.sh
./install.sh --with-deps
```

This will:
1. Detect your distro (Arch, Fedora, Debian, NixOS)
2. Install all required packages
3. Link all config files to `~/.config/`
4. Install JetBrainsMono Nerd Font
5. Enable the wallpaper cache systemd service
6. Set fish as your default shell
7. Create screenshot directories
8. Generate an initial theme from your first wallpaper

## After Installation

### 1. Log Out and Back In

After running the installer, log out of your current Hyprland session and log back in. The `autostart.lua` script will launch:

- Waybar (status bar)
- SwayNC (notification center)
- Polkit authentication agent
- Cliphist (clipboard history)
- Awww daemon (animated wallpapers)
- Your last wallpaper

### 2. Set Your First Wallpaper

Press `SUPER + SHIFT + W` to open the wallpaper picker, or run:

```bash
~/.config/wallust/wallpaper-select.sh
```

Select an image — the theme generates automatically and all components update.

### 3. Learn the Keybindings

Essential shortcuts:

| Key | Action |
|-----|--------|
| `SUPER + T` | Open terminal (kitty) |
| `SUPER + Space` | App launcher (rofi) |
| `ALT + Space` | Spotlight search (files + folders + web) |
| `SUPER + Q` | Close window |
| `SUPER + V` | Clipboard history |
| `SUPER + SHIFT + S` | Selection screenshot |
| `Print` | Fullscreen screenshot |
| `SUPER + N` | Toggle notifications |
| `SUPER + SHIFT + W` | Wallpaper picker |

Full list: [Keybindings](keybindings.md)

### 4. Customize

- **Change colors**: Just change the wallpaper. Everything follows
- **Modify templates**: Edit files in `~/.config/wallust/templates/`
- **Add new components**: See [Customization](customization.md)

## First-Time Tweaks

### Power Profiles

If your system supports it, cycle power profiles via the waybar power icon, or:

```bash
~/.config/waybar/scripts/power-profile-switch.sh
```

### Screenshots

- `Print` → saves to `~/Pictures/Screenshots/Fullscreen/` + clipboard
- `SUPER + SHIFT + S` → select region, saves to `~/Pictures/Screenshots/Freeform/` + clipboard

### Screen Recording

- `SUPER + R` → toggle fullscreen recording
- `SUPER + SHIFT + R` → toggle region recording

Saved to `~/Videos/Recordings/Fullscreen/` and `~/Videos/Recordings/Region/`.

## What's Next?

- Read the [Features](features.md) overview
- Explore the [Waybar Modules](waybar-modules.md)
- Learn how [Theming](theming.md) works
- Check [Performance](performance.md) optimization tips
