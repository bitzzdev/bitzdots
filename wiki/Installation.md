# Installation

bitzdots supports Arch Linux, Fedora, Debian/Ubuntu, and NixOS.

## Automated Install (Recommended)

```bash
git clone https://github.com/bitzzdev/bitzdots.git ~/.config/bitzdots
cd ~/.config/bitzdots
chmod +x install.sh

# Link configs only (no system packages):
./install.sh

# Link configs + install all system packages:
./install.sh --with-deps
```

The installer auto-detects your distro and:

1. Installs required packages (repo + AUR via paru/yay where needed)
2. Installs JetBrainsMono Nerd Font
3. Creates screenshot/recording directories and wallpaper directories
4. Links all configs into `~/.config/`
5. Sets up the runcat-text module (venv + font)
6. Installs the `matugen-cache-daemon` systemd user service
7. Generates an initial theme from your default wallpaper

## Manual Install

### 1. Install Packages

Choose your distro:

<details>
<summary><b>Arch Linux</b></summary>

```bash
# Official repos
sudo pacman -S waybar swaync rofi kitty cava hyprpicker wl-clipboard \
  playerctl pavucontrol polkit-kde-agent grim slurp cliphist hyprlock \
  ffmpeg btop pulsemixer wf-recorder python brightnessctl \
  bluez bluez-utils libnotify networkmanager wireplumber \
  pipewire-pulse curl jq imagemagick nautilus wofi \
  papirus-icon-theme power-profiles-daemon breeze inotify-tools \
  fish fastfetch qt5ct qt6ct

# AUR (using paru or yay)
paru -S wlogout matugen bluetui awww impala ttf-jetbrains-mono-nerd
```

</details>

<details>
<summary><b>Fedora</b></summary>

```bash
sudo dnf install waybar swaync wlogout rofi kitty cava awww hyprpicker \
  wl-clipboard playerctl pavucontrol polkit-kde-agent grim slurp \
  cliphist hyprlock ffmpeg inotify-tools ImageMagick fastfetch fish \
  power-profiles-daemon btop pulsemixer wf-recorder python3 impala \
  brightnessctl bluez libnotify NetworkManager wireplumber \
  pipewire-pulseaudio curl jq nautilus wofi papirus-icon-theme \
  qt5ct qt6ct

cargo install matugen bluetui
```

</details>

<details>
<summary><b>Debian/Ubuntu</b></summary>

```bash
sudo apt install waybar swaync wlogout rofi kitty cava awww hyprpicker \
  wl-clipboard playerctl pavucontrol polkit-kde-agent grim slurp \
  cliphist hyprlock ffmpeg inotify-tools imagemagick fastfetch fish \
  btop pulsemixer wf-recorder python3 brightnessctl bluez bluez-utils \
  libnotify-bin network-manager wireplumber pipewire-pulse curl jq \
  nautilus wofi papirus-icon-theme qt5ct qt6ct

cargo install matugen bluetui
```

</details>

<details>
<summary><b>NixOS</b></summary>

```nix
{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    waybar swaync wlogout rofi kitty cava hyprpicker
    wl-clipboard playerctl pavucontrol polkit-kde-agent
    grim slurp cliphist hyprlock ffmpeg btop
    inotify-tools imagemagick fastfetch fish
    matugen python3
  ];
}
```

</details>

### 2. Link Configuration Files

Run `./install.sh` (links everything). Or link manually:

```bash
DOTFILES_DIR="$HOME/.config/bitzdots"
CONFIG_DIR="$HOME/.config"

# Hyprland
mkdir -p "$CONFIG_DIR/hypr"
for f in "$DOTFILES_DIR/hypr"/*.lua; do
  ln -sf "$f" "$CONFIG_DIR/hypr/$(basename "$f")"
done

# Waybar
mkdir -p "$CONFIG_DIR/waybar/scripts" "$CONFIG_DIR/waybar/colors"
ln -sf "$DOTFILES_DIR/waybar/config.jsonc" "$CONFIG_DIR/waybar/config.jsonc"
ln -sf "$DOTFILES_DIR/waybar/style.css" "$CONFIG_DIR/waybar/style.css"
for s in "$DOTFILES_DIR/waybar/scripts"/*.sh; do
  ln -sf "$s" "$CONFIG_DIR/waybar/scripts/$(basename "$s")"
done

# Rofi (config, themes, colors, launchers, scripts, icons)
for d in themes colors launchers scripts icons; do
  mkdir -p "$CONFIG_DIR/rofi/$d"
  for f in "$DOTFILES_DIR/rofi/$d"/*; do
    [ -e "$f" ] && ln -sf "$f" "$CONFIG_DIR/rofi/$d/$(basename "$f")"
  done
done
ln -sf "$DOTFILES_DIR/rofi/config.rasi" "$CONFIG_DIR/rofi/config.rasi"

# Icons (linked into rofi/icons)
mkdir -p "$CONFIG_DIR/rofi/icons"
for f in "$DOTFILES_DIR/icons"/*.svg; do
  ln -sf "$f" "$CONFIG_DIR/rofi/icons/$(basename "$f")"
done

# SwayNC, kitty, cava, wlogout
ln -sf "$DOTFILES_DIR/swaync/config.json" "$CONFIG_DIR/swaync/config.json"
ln -sf "$DOTFILES_DIR/swaync/style.css" "$CONFIG_DIR/swaync/style.css"
ln -sf "$DOTFILES_DIR/kitty/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf"
ln -sf "$DOTFILES_DIR/cava/config" "$CONFIG_DIR/cava/config"
ln -sf "$DOTFILES_DIR/wlogout/style.css" "$CONFIG_DIR/wlogout/style.css"
ln -sf "$DOTFILES_DIR/wlogout/layout" "$CONFIG_DIR/wlogout/layout"

# Matugen (config + templates + scripts)
mkdir -p "$CONFIG_DIR/matugen/templates"
ln -sf "$DOTFILES_DIR/matugen/config.toml" "$CONFIG_DIR/matugen/config.toml"
for t in "$DOTFILES_DIR/matugen/templates"/*; do
  ln -sf "$t" "$CONFIG_DIR/matugen/templates/"
done
for s in "$DOTFILES_DIR/scripts"/*.sh; do
  ln -sf "$s" "$CONFIG_DIR/matugen/$(basename "$s")"
done

# GTK / Qt / fish / fastfetch
ln -sf "$DOTFILES_DIR/gtk/gtk-3.0/settings.ini" "$CONFIG_DIR/gtk-3.0/settings.ini"
ln -sf "$DOTFILES_DIR/gtk/gtk-4.0/settings.ini" "$CONFIG_DIR/gtk-4.0/settings.ini"
ln -sf "$DOTFILES_DIR/environment.d/qt.conf" "$CONFIG_DIR/environment.d/qt.conf"
ln -sf "$DOTFILES_DIR/fish/config.fish" "$CONFIG_DIR/fish/config.fish"
ln -sf "$DOTFILES_DIR/fastfetch/config.jsonc" "$CONFIG_DIR/fastfetch/config.jsonc"
ln -sf "$DOTFILES_DIR/fastfetch/bitz.txt" "$CONFIG_DIR/fastfetch/bitz.txt"
```

### 3. Systemd Service

```bash
mkdir -p "$CONFIG_DIR/systemd/user"
cp "$DOTFILES_DIR/systemd/user/matugen-cache-daemon.service" \
   "$CONFIG_DIR/systemd/user/matugen-cache-daemon.service"
systemctl --user daemon-reload
systemctl --user enable --now matugen-cache-daemon.service
```

### 4. Install Font

```bash
# Arch (AUR)
paru -S ttf-jetbrains-mono-nerd

# Or download manually from https://www.nerdfonts.com/
```

### 5. Generate Initial Theme

```bash
matugen image ~/Pictures/Wallpapers/your-wallpaper.jpg --config ~/.config/matugen/config.toml \
  --config-dir ~/.config/matugen
```

## Post-Installation Checklist

- [ ] Waybar is visible at the top of the screen
- [ ] `SUPER + T` opens kitty
- [ ] `SUPER + Space` opens rofi launcher
- [ ] `Print` saves a screenshot
- [ ] `SUPER + SHIFT + W` opens the wallpaper picker
- [ ] Changing the wallpaper updates all colors
- [ ] Notifications appear; control center opens with `SUPER + N`
- [ ] `systemctl --user status matugen-cache-daemon.service` shows running
- [ ] All apps default to dark theme (GTK, Qt, kitty, etc.)

## Troubleshooting

See the [FAQ](FAQ) for common issues.
