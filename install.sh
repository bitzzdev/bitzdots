#!/bin/bash
# ============================================================
# bitzdots — Automated Installer with wallust theming
# ============================================================
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
WALL_DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${CYAN}[bitzdots]${NC} $1"; }
ok()   { echo -e "${GREEN}[  ok  ]${NC} $1"; }
warn() { echo -e "${YELLOW}[ warn ]${NC} $1"; }
fail() { echo -e "${RED}[ fail ]${NC} $1"; exit 1; }

detect_distro() {
    if [ -f /etc/arch-release ]; then
        echo "arch"
    elif [ -f /etc/debian_version ]; then
        echo "debian"
    elif [ -f /etc/fedora-release ]; then
        echo "fedora"
    elif command -v nix-env &>/dev/null; then
        echo "nixos"
    else
        echo "unknown"
    fi
}

install_deps() {
    local distro
    distro=$(detect_distro)
    log "Detected distro: $distro"

    case "$distro" in
        arch)
            log "Installing packages (Arch)..."

            # Stage 1: guaranteed repo packages (core + extra) via pacman
            local repo_pkgs=(
                hyprland waybar swaync rofi kitty cava
                hyprpicker wl-clipboard playerctl pavucontrol
                polkit-kde-agent grim slurp cliphist hyprlock ffmpeg
                btop pulsemixer wf-recorder python
                power-profiles-daemon breeze inotify-tools fish fastfetch
                brightnessctl bluez bluez-utils libnotify networkmanager
                wireplumber pipewire-pulse curl jq imagemagick
                nautilus wofi papirus-icon-theme rust
                qt5ct qt6ct
            )
            sudo pacman -S --needed --noconfirm "${repo_pkgs[@]}" || \
                warn "Some repo packages failed — the rest were likely installed"
            ok "Repo packages installed"

            # Stage 2: packages that may be in community or AUR
            # Install individually so a single failure doesn't block the rest
            install_aur_pkg() {
                local pkg=$1
                if command -v paru &>/dev/null; then
                    paru -S --needed --noconfirm "$pkg" 2>&1 || return 1
                elif command -v yay &>/dev/null; then
                    yay -S --needed --noconfirm "$pkg" 2>&1 || return 1
                else
                    return 1
                fi
            }

            for pkg in wlogout wallust bluetui awww impala; do
                if command -v "$pkg" &>/dev/null; then
                    continue
                fi
                log "Installing $pkg..."
                if install_aur_pkg "$pkg"; then
                    ok "  $pkg installed"
                elif [ "$pkg" = wallust ] && command -v cargo &>/dev/null; then
                    warn "  $pkg AUR build failed — trying cargo..."
                    cargo install wallust && ok "  wallust installed via cargo" || warn "  wallust install failed"
                elif [ "$pkg" = bluetui ] && command -v cargo &>/dev/null; then
                    warn "  $pkg AUR build failed — trying cargo..."
                    cargo install bluetui && ok "  bluetui installed via cargo" || warn "  bluetui install failed"
                elif [ "$pkg" = impala ] && command -v cargo &>/dev/null; then
                    warn "  $pkg AUR build failed — trying cargo..."
                    cargo install impala && ok "  impala installed via cargo" || warn "  impala install failed"
                else
                    warn "  $pkg not installed — install manually if needed"
                fi
            done

            # Try to replace xdg-desktop-portal-hyprland with git version (fixes CPU loop)
            if pacman -Q xdg-desktop-portal-hyprland 2>/dev/null | grep -q "1.4" && \
               ! pacman -Q xdg-desktop-portal-hyprland-git 2>/dev/null; then
                log "Installing xdg-desktop-portal-hyprland-git (fixes CPU loop)..."
                install_aur_pkg xdg-desktop-portal-hyprland-git || \
                    warn "  Could not replace portal — will use autostart workaround instead"
            fi
            ;;
        fedora)
            log "Installing packages (Fedora)..."
            sudo dnf install -y \
                hyprland waybar swaync wlogout rofi kitty cava \
                awww hyprpicker wl-clipboard playerctl pavucontrol \
                polkit-kde-agent grim slurp cliphist hyprlock ffmpeg \
                inotify-tools fish fastfetch btop pulsemixer \
                wf-recorder python3 impala \
                brightnessctl bluez libnotify \
                NetworkManager wireplumber pipewire-pulseaudio \
                curl jq ImageMagick nautilus wofi papirus-icon-theme \
                qt5ct qt6ct
            ;;
        debian)
            log "Installing packages (Debian/Ubuntu)..."
            sudo apt install -y \
                hyprland waybar swaync wlogout rofi kitty cava \
                awww hyprpicker wl-clipboard playerctl pavucontrol \
                polkit-kde-agent grim slurp cliphist hyprlock ffmpeg \
                inotify-tools fish fastfetch btop pulsemixer \
                wf-recorder python3 \
                brightnessctl bluez bluez-utils libnotify-bin \
                network-manager wireplumber pipewire-pulse \
                curl jq imagemagick nautilus wofi papirus-icon-theme \
                qt5ct qt6ct
            ;;
        nixos)
            log "NixOS detected — add these to your configuration.nix:"
            echo "  services.awww.enable = true;"
            echo "  programs.waybar.enable = true;"
            echo "  programs.rofi.enable = true;"
            echo "  programs.hyprland.enable = true;"
            echo "  environment.systemPackages = with pkgs; ["
            echo "    hyprland wallust swaync wlogout kitty cava inotify-tools"
            echo "    hyprpicker wl-clipboard playerctl pavucontrol"
            echo "    polkit-kde-agent grim slurp cliphist hyprlock ffmpeg"
            echo "    fish fastfetch btop pulsemixer wf-recorder python3"
            echo "    brightnessctl bluez bluez-utils libnotify"
            echo "    networkmanager wireplumber pipewire-pulse"
            echo "    curl jq imagemagick nautilus wofi papirus-icon-theme"
            echo "    qt5ct qt6ct"
            echo "  ];"
            echo "  services.bluetooth.enable = true;"
            ;;
        *)
            warn "Unknown distro. Please install manually:"
            echo "  - hyprland (window manager)"
            echo "  - wallust (https://github.com/explosion-mental/wallust)"
            echo "  - waybar, swaync, wlogout, rofi, kitty, cava"
            echo "  - awww, hyprpicker, wl-clipboard, playerctl"
            echo "  - pavucontrol, polkit-kde-agent, grim, slurp, cliphist"
            echo "  - hyprlock, ffmpeg, inotify-tools"
            echo "  - fish, fastfetch, btop, pulsemixer, wf-recorder, python3"
            echo "  - brightnessctl, bluez, bluez-utils, libnotify"
            echo "  - networkmanager, wireplumber, pipewire-pulse, curl, jq"
            echo "  - imagemagick, nautilus, wofi, papirus-icon-theme"
            echo "  - chromium (dark mode policy will be created)"
            echo "  - qt5ct, qt6ct, kvantum (for Qt dark theme)"
            ;;
    esac
}

install_nerd_font() {
    if fc-list :family 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
        ok "JetBrainsMono Nerd Font already installed"
        return
    fi

    log "Installing JetBrainsMono Nerd Font..."

    if command -v paru &>/dev/null; then
        paru -S --needed --noconfirm ttf-jetbrains-mono-nerd && return
    fi

    if command -v yay &>/dev/null; then
        yay -S --needed --noconfirm ttf-jetbrains-mono-nerd && return
    fi

    warn "No AUR helper found. Install manually: paru -S ttf-jetbrains-mono-nerd"
}

link_config() {
    local src="$1"
    local dest="$2"
    local name="$3"

    [ -e "$src" ] || return

    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
        warn "$name config exists at $dest — backing up to ${dest}.bak"
        mv "$dest" "${dest}.bak"
    fi

    if [ -L "$dest" ]; then
        return
    fi

    ln -sf "$src" "$dest"
}

setup_wallpapers() {
    mkdir -p "$WALL_DIR" "$WALL_DIR/live"
    for f in "$DOTFILES_DIR/hypr/wallpapers"/* "$DOTFILES_DIR/Wallpapers"/*; do
        [ -f "$f" ] || continue
        cp -n "$f" "$WALL_DIR/" 2>/dev/null || true
    done
    ok "Wallpapers ready: $WALL_DIR/"
}

setup_cache() {
    mkdir -p "$CACHE_DIR"
}

setup_runcat() {
    local module_dir="$CONFIG_DIR/waybar/modules/runcat-text"
    [ -d "$DOTFILES_DIR/waybar/modules/runcat-text" ] || return

    mkdir -p "$module_dir"
    cp "$DOTFILES_DIR/waybar/modules/runcat-text"/* "$module_dir/"

    local font_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
    mkdir -p "$font_dir"
    if [ -f "$module_dir/runcat.ttf" ] && ! fc-list :family 2>/dev/null | grep -qi "runcat"; then
        cp "$module_dir/runcat.ttf" "$font_dir/"
        fc-cache -f 2>/dev/null || true
    fi

    if [ ! -f "$module_dir/.venv/bin/python" ] && command -v python &>/dev/null; then
        python -m venv "$module_dir/.venv"
        "$module_dir/.venv/bin/pip" install -q "$module_dir/requirements.txt" 2>/dev/null || \
            "$module_dir/.venv/bin/pip" install -q pyjson5 2>/dev/null || true
    fi
    ok "runcat-text setup complete"
}

install_scripts() {
    local scripts_dir="$CONFIG_DIR/wallust"
    mkdir -p "$scripts_dir/templates"

    for s in reload-theme.sh wallpaper-select.sh cache-wallpapers.sh wallust-cache-daemon.sh record-fullscreen.sh record-region.sh recording-indicator.sh wifi-fix.sh; do
        ln -sf "$DOTFILES_DIR/scripts/$s" "$scripts_dir/$s"
    done

    ln -sf "$DOTFILES_DIR/wallust/wallust.toml" "$scripts_dir/wallust.toml"

    for t in "$DOTFILES_DIR/wallust/templates"/*; do
        ln -sf "$t" "$scripts_dir/templates/"
    done

    mkdir -p "$HOME/.local/bin"
    ln -sf "$DOTFILES_DIR/scripts/hyprlogout" "$HOME/.local/bin/hyprlogout"

    ok "Wallust scripts and templates linked"
}

make_executable() {
    for d in "$CONFIG_DIR/waybar/scripts" "$CONFIG_DIR/rofi/scripts" "$CONFIG_DIR/wallust"; do
        for s in "$d"/*.sh; do
            chmod +x "$s" 2>/dev/null || true
        done
    done
    chmod +x "$HOME/.local/bin/hyprlogout" 2>/dev/null || true
    ok "Scripts made executable"
}

install_waybar_config() {
    mkdir -p "$CONFIG_DIR/waybar/scripts" "$CONFIG_DIR/waybar/colors"
    link_config "$DOTFILES_DIR/waybar/config.jsonc" "$CONFIG_DIR/waybar/config.jsonc" "waybar"
    link_config "$DOTFILES_DIR/waybar/style.css" "$CONFIG_DIR/waybar/style.css" "waybar"
    link_config "$DOTFILES_DIR/waybar/colors/teto.css" "$CONFIG_DIR/waybar/colors/teto.css" "waybar"
    link_config "$DOTFILES_DIR/waybar/scripts/launch.sh" "$CONFIG_DIR/waybar/scripts/launch.sh" "waybar"
    link_config "$DOTFILES_DIR/waybar/scripts/media.sh" "$CONFIG_DIR/waybar/scripts/media.sh" "waybar"
    link_config "$DOTFILES_DIR/waybar/scripts/weather.sh" "$CONFIG_DIR/waybar/scripts/weather.sh" "waybar"
    for s in brightness.sh brightness-adjust.sh notification.sh power-profile.sh power-profile-switch.sh system-power.sh workspaces.sh workspace-click.sh workspace-next.sh workspace-prev.sh tui-wifi.sh tui-bluetooth.sh tui-audio.sh tui-cpu.sh; do
        link_config "$DOTFILES_DIR/waybar/scripts/$s" "$CONFIG_DIR/waybar/scripts/$s" "waybar"
    done
    for s in "$DOTFILES_DIR/scripts"/record*.sh; do
        link_config "$s" "$CONFIG_DIR/waybar/scripts/$(basename "$s")" "waybar"
    done
    link_config "$DOTFILES_DIR/scripts/workspace-monitor.sh" "$CONFIG_DIR/waybar/scripts/workspace-monitor.sh" "waybar"
}

install_hypr_config() {
    mkdir -p "$CONFIG_DIR/hypr"
    for f in "$DOTFILES_DIR/hypr"/*.lua; do
        link_config "$f" "$CONFIG_DIR/hypr/$(basename "$f")" "hyprland"
    done
}

install_swaync_config() {
    mkdir -p "$CONFIG_DIR/swaync"
    link_config "$DOTFILES_DIR/swaync/config.json" "$CONFIG_DIR/swaync/config.json" "swaync"
    link_config "$DOTFILES_DIR/swaync/style.css" "$CONFIG_DIR/swaync/style.css" "swaync"
    link_config "$DOTFILES_DIR/swaync/media-swaync.sh" "$CONFIG_DIR/swaync/media-swaync.sh" "swaync"
    link_config "$DOTFILES_DIR/swaync/bt-status.sh" "$CONFIG_DIR/swaync/bt-status.sh" "swaync"
}

install_gtk_config() {
    mkdir -p "$CONFIG_DIR/gtk-3.0" "$CONFIG_DIR/gtk-4.0"
    link_config "$DOTFILES_DIR/gtk/gtk-3.0/settings.ini" "$CONFIG_DIR/gtk-3.0/settings.ini" "gtk3"
    link_config "$DOTFILES_DIR/gtk/gtk-4.0/settings.ini" "$CONFIG_DIR/gtk-4.0/settings.ini" "gtk4"
}

install_qt_config() {
    mkdir -p "$CONFIG_DIR/qt5ct"
    link_config "$DOTFILES_DIR/qt5ct/qt5ct.conf" "$CONFIG_DIR/qt5ct/qt5ct.conf" "qt5ct"
    # qt6ct config is auto-generated by wallust from template
    ok "Dark theme enabled for GTK + Qt apps"
}

install_wlogout_config() {
    mkdir -p "$CONFIG_DIR/wlogout/assets" "$CONFIG_DIR/wlogout/icons" "$CONFIG_DIR/wlogout/actions"
    link_config "$DOTFILES_DIR/wlogout/style.css" "$CONFIG_DIR/wlogout/style.css" "wlogout"
    link_config "$DOTFILES_DIR/wlogout/layout" "$CONFIG_DIR/wlogout/layout" "wlogout"
    for d in assets icons actions; do
        for f in "$DOTFILES_DIR/wlogout/$d"/*; do
            link_config "$f" "$CONFIG_DIR/wlogout/$d/$(basename "$f")" "wlogout"
        done
    done
}

install_rofi_config() {
    mkdir -p "$CONFIG_DIR/rofi/themes" "$CONFIG_DIR/rofi/colors" "$CONFIG_DIR/rofi/launchers" "$CONFIG_DIR/rofi/scripts" "$CONFIG_DIR/rofi/icons"
    link_config "$DOTFILES_DIR/rofi/config.rasi" "$CONFIG_DIR/rofi/config.rasi" "rofi"
    for d in colors themes; do
        for f in "$DOTFILES_DIR/rofi/$d"/*.rasi; do
            link_config "$f" "$CONFIG_DIR/rofi/$d/$(basename "$f")" "rofi"
        done
    done
    for f in "$DOTFILES_DIR/rofi/launchers"/*; do
        [ -f "$f" ] && link_config "$f" "$CONFIG_DIR/rofi/launchers/$(basename "$f")" "rofi"
    done
    link_config "$DOTFILES_DIR/rofi/scripts/script_wallpaper.sh" "$CONFIG_DIR/rofi/scripts/script_wallpaper.sh" "rofi"
    link_config "$DOTFILES_DIR/rofi/scripts/system-power.sh" "$CONFIG_DIR/rofi/scripts/system-power.sh" "rofi"
    link_config "$DOTFILES_DIR/rofi/scripts/clipboard.sh" "$CONFIG_DIR/rofi/scripts/clipboard.sh" "rofi"
    link_config "$DOTFILES_DIR/rofi/scripts/spotlight.sh" "$CONFIG_DIR/rofi/scripts/spotlight.sh" "rofi"
    # Icons
    link_config "$DOTFILES_DIR/icons/lock-outline-sharp.svg" "$CONFIG_DIR/rofi/icons/lock.svg" "rofi"
    link_config "$DOTFILES_DIR/icons/logout-sharp.svg" "$CONFIG_DIR/rofi/icons/logout.svg" "rofi"
    link_config "$DOTFILES_DIR/icons/sleep.svg" "$CONFIG_DIR/rofi/icons/sleep.svg" "rofi"
    link_config "$DOTFILES_DIR/icons/reboot.svg" "$CONFIG_DIR/rofi/icons/reboot.svg" "rofi"
    link_config "$DOTFILES_DIR/icons/shutdown.svg" "$CONFIG_DIR/rofi/icons/shutdown.svg" "rofi"
    link_config "$DOTFILES_DIR/icons/cancel-outline.svg" "$CONFIG_DIR/rofi/icons/cancel.svg" "rofi"
    link_config "$DOTFILES_DIR/icons/static.svg" "$CONFIG_DIR/rofi/icons/static.svg" "rofi"
    link_config "$DOTFILES_DIR/icons/live.svg" "$CONFIG_DIR/rofi/icons/live.svg" "rofi"
}

install_cava_config() {
    mkdir -p "$CONFIG_DIR/cava/themes" "$CONFIG_DIR/cava/shaders"
    link_config "$DOTFILES_DIR/cava/config" "$CONFIG_DIR/cava/config" "cava"
    for f in "$DOTFILES_DIR/cava/shaders"/*; do
        link_config "$f" "$CONFIG_DIR/cava/shaders/$(basename "$f")" "cava"
    done
}

link_dotfiles() {
    log "Linking dotfiles..."
    install_waybar_config
    install_hypr_config
    install_swaync_config
    install_gtk_config
    install_qt_config
    install_wlogout_config
    install_rofi_config
    install_cava_config
    mkdir -p "$CONFIG_DIR/kitty"
    link_config "$DOTFILES_DIR/kitty/kitty.conf" "$CONFIG_DIR/kitty/kitty.conf" "kitty"
    mkdir -p "$CONFIG_DIR/environment.d"
    link_config "$DOTFILES_DIR/environment.d/qt.conf" "$CONFIG_DIR/environment.d/qt.conf" "qt"
    mkdir -p "$CONFIG_DIR/fish"
    link_config "$DOTFILES_DIR/fish/config.fish" "$CONFIG_DIR/fish/config.fish" "fish"
    mkdir -p "$CONFIG_DIR/fastfetch"
    link_config "$DOTFILES_DIR/fastfetch/config.jsonc" "$CONFIG_DIR/fastfetch/config.jsonc" "fastfetch"
    link_config "$DOTFILES_DIR/fastfetch/bitz.txt" "$CONFIG_DIR/fastfetch/bitz.txt" "fastfetch"
}

fix_paths() {
    log "Fixing hardcoded paths..."
    local files=(
        "$DOTFILES_DIR/rofi/config.rasi"
        "$DOTFILES_DIR/rofi/scripts/script_wallpaper.sh"
        "$DOTFILES_DIR/rofi/launchers/type-6/style-4.rasi"
        "$DOTFILES_DIR/rofi/themes/wallpaper-grid.rasi"
    )
    for file in "${files[@]}"; do
        [ -f "$file" ] && sed -i "s|/home/lucario|$HOME|g; s|/home/bitz|$HOME|g" "$file" 2>/dev/null || true
    done
    ok "Paths fixed"
}

add_keybind() {
    local keybind_file="$CONFIG_DIR/hypr/keybinds.lua"
    [ -f "$keybind_file" ] || return
    grep -q "wallpaper-select" "$keybind_file" 2>/dev/null && return
    echo "" >> "$keybind_file"
    echo "-- Wallpaper selector" >> "$keybind_file"
    echo 'hl.bind("SUPER + SHIFT + W", hl.dsp.exec_cmd("~/.config/wallust/wallpaper-select.sh"))' >> "$keybind_file"
    ok "Keybind added: SUPER+SHIFT+W = wallpaper picker"
}

generate_initial_theme() {
    command -v wallust &>/dev/null || { warn "wallust not installed — skipping theme generation"; return; }

    local initial_wall=""
    local img
    for img in $(find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort); do
        if timeout 20 wallust run "$img" --config-dir "$CONFIG_DIR/wallust" -q 2>/dev/null; then
            initial_wall="$img"
            break
        fi
    done

    [ -n "$initial_wall" ] || { warn "No suitable wallpaper found — skipping theme generation"; return; }

    log "Generating theme from: $(basename "$initial_wall")"
    echo "$initial_wall" > "$CACHE_DIR/current_wallpaper.txt" 2>/dev/null || true
    ln -sf "$initial_wall" "$CACHE_DIR/current_wallpaper.png" 2>/dev/null || true

    if command -v awww &>/dev/null; then
        pgrep -x awww-daemon > /dev/null 2>&1 || { awww-daemon & sleep 0.5; }
        awww img "$initial_wall" --transition-type grow --transition-duration 1 2>/dev/null || true
    fi

    # Verify key outputs exist
    local key_outputs=("$CONFIG_DIR/waybar/style.css" "$CONFIG_DIR/hypr/colors.lua" "$CONFIG_DIR/swaync/style.css")
    local all_exist=true
    for f in "${key_outputs[@]}"; do
        if [ ! -f "$f" ]; then
            warn "  Missing: $f"
            all_exist=false
        fi
    done

    if [ "$all_exist" = true ]; then
        ok "Theme generated from $(basename "$initial_wall")"
    else
        warn "Theme generation had issues - some output files missing"
        warn "Run manually: wallust run \"$initial_wall\" --config-dir \"$CONFIG_DIR/wallust\""
    fi
}

install_systemd_services() {
    log "Installing systemd services..."
    mkdir -p "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    cp "$DOTFILES_DIR/systemd/user/wallust-cache-daemon.service" \
       "${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/wallust-cache-daemon.service"
    systemctl --user daemon-reload 2>/dev/null || true
    systemctl --user enable --now wallust-cache-daemon.service 2>/dev/null || true
    ok "wallust-cache-daemon service started"

    if command -v bluetoothctl &>/dev/null; then
        sudo rfkill unblock bluetooth 2>/dev/null || true
        sudo systemctl daemon-reload 2>/dev/null || true
        if systemctl list-unit-files bluetooth.service &>/dev/null; then
            sudo systemctl enable --now bluetooth.service || warn "Could not enable bluetooth.service"
            ok "Bluetooth service enabled"
        else
            warn "bluetooth.service unit not found — try reinstalling bluez"
        fi
    fi

    # Enable NetworkManager so WiFi reliably auto-connects on boot
    if systemctl list-unit-files NetworkManager.service &>/dev/null; then
        sudo systemctl enable --now NetworkManager.service 2>/dev/null || \
            warn "Could not enable NetworkManager.service — WiFi may not auto-connect"
        sudo systemctl start NetworkManager.service 2>/dev/null || true
        ok "NetworkManager service enabled"
    else
        warn "NetworkManager.service unit not found — WiFi TUI (impala) requires it"
    fi
}

install_cargo_tools() {
    command -v cargo &>/dev/null || { warn "cargo not found, install rust to enable cargo-based tool installation"; return 0; }

    if ! command -v bluetui &>/dev/null; then
        log "Installing bluetui via cargo..."
        cargo install bluetui && ok "  bluetui installed" || warn "  bluetui install failed"
    fi

    if ! command -v impala &>/dev/null; then
        log "Installing impala via cargo..."
        cargo install impala && ok "  impala installed" || warn "  impala install failed"
    fi

    if ! command -v wallust &>/dev/null; then
        log "Installing wallust via cargo..."
        cargo install wallust && ok "  wallust installed" || warn "  wallust install failed"
    fi
}

verify_critical_tools() {
    log "Verifying critical tools..."
    local missing=()
    local tools=(
        "brightnessctl:brightnessctl:for display backlight control"
        "wallust:wallust:for theme generation from wallpapers"
        "swaync:swaync:notification daemon"
        "notify-send:libnotify:for desktop notifications"
        "bluetoothctl:bluez-utils:Bluetooth control"
        "playerctl:playerctl:media player control"
        "rofi:rofi:application launcher and menus"
        "waybar:waybar:status bar"
        "kitty:kitty:terminal emulator"
    )

    for entry in "${tools[@]}"; do
        local bin="${entry%%:*}"
        local pkg="${entry#*:}"; pkg="${pkg%%:*}"
        local desc="${entry##*:}"
        if ! command -v "$bin" &>/dev/null; then
            missing+=("$pkg ($desc)")
        fi
    done

    if command -v bluetui &>/dev/null; then
        ok "  bluetui found - Bluetooth TUI available"
    else
        warn "  bluetui not found - tui-bluetooth.sh will fall back to bluetoothctl"
        warn "    Install: paru -S bluetui (Arch) or cargo install bluetui"
    fi

    if command -v impala &>/dev/null; then
        ok "  impala found - WiFi TUI available"
    else
        warn "  impala not found - tui-wifi.sh will fall back to nmtui"
        warn "    Install: paru -S impala (Arch) or cargo install impala"
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        warn "Missing critical tools:"
        for m in "${missing[@]}"; do
            warn "  - $m"
        done
        warn "Install missing packages manually for full functionality."
    else
        ok "All critical tools present"
    fi
}

verify_swaync_running() {
    log "Verifying notification daemon..."

    if pgrep -x swaync > /dev/null 2>&1; then
        ok "swaync is running"
    else
        warn "swaync is not running. Attempting to start..."
        swaync &>/dev/null &
        sleep 1
        if pgrep -x swaync > /dev/null 2>&1; then
            ok "swaync started successfully"
        else
            warn "Could not start swaync. Notifications will not work."
            warn "After logging into Hyprland, run: swaync &"
            warn "Or add 'swaync' to your Hyprland autostart."
        fi
    fi

    local dbus_running=false
    if command -v busctl &>/dev/null; then
        if busctl list 2>/dev/null | grep -q "org.freedesktop.Notifications"; then
            dbus_running=true
        fi
    elif command -v dbus-send &>/dev/null; then
        if dbus-send --session --dest=org.freedesktop.DBus --type=method_call --print-reply \
            /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>/dev/null | \
            grep -q "org.freedesktop.Notifications"; then
            dbus_running=true
        fi
    fi

    if [ "$dbus_running" = true ]; then
        ok "Notification D-Bus service is registered"
    else
        warn "No notification daemon registered on D-Bus"
        warn "After swaync starts, run: notify-send test"
    fi
}

verify_theme_outputs() {
    log "Verifying theme output files..."
    local outputs=(
        "waybar/style.css"
        "waybar/config.jsonc"
        "swaync/style.css"
        "hypr/colors.lua"
    )
    local all_ok=true
    for f in "${outputs[@]}"; do
        if [ -f "$CONFIG_DIR/$f" ]; then
            ok "  $f exists"
        else
            warn "  $f missing - theme may not be applied"
            all_ok=false
        fi
    done

    if [ "$all_ok" = false ]; then
        warn "Some theme files are missing. Run: wallust run ~/Pictures/Wallpapers/<image> --config-dir $CONFIG_DIR/wallust"
    fi
}

# ═══════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════

echo ""
echo -e "${CYAN}╔══════════════════════════════════╗${NC}"
echo -e "${CYAN}║     bitzdots — Auto Installer     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════╝${NC}"
echo ""

SKIP_DEPS=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skip-deps)
            SKIP_DEPS=true
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "  --skip-deps    Skip installation of dependencies"
            echo "  --help, -h     Show this help"
            exit 0
            ;;
        *)
            warn "Unknown option: $1"
            ;;
    esac
    shift
done

if $SKIP_DEPS; then
    log "Skipping dependency installation (--skip-deps set)"
else
    install_deps
fi

setup_wallpapers
setup_cache
mkdir -p "$HOME/Pictures/Screenshots/Fullscreen" "$HOME/Pictures/Screenshots/Freeform" 2>/dev/null || true
install_nerd_font
install_scripts
link_dotfiles
make_executable
setup_runcat
fix_paths
add_keybind
generate_initial_theme
install_systemd_services

# Add user to video group for backlight access
if command -v brightnessctl &>/dev/null; then
    if ! groups "$USER" | grep -q video; then
        sudo usermod -aG video "$USER" 2>/dev/null || true
        warn "Added $USER to 'video' group — log out and back in for brightnessctl to work"
    fi
fi

if ! $SKIP_DEPS; then
    install_cargo_tools
fi

# Force dark theme for GTK4 apps (Nautilus, etc.)
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
fi

# Prepare Chromium policy directories for BrowserThemeColor enterprise policy
log "Setting up Chromium browser theme policy directories..."
for policy_dir in /etc/brave/policies/managed \
                 /etc/opt/chrome/policies/managed \
                 /etc/chromium/policies/managed \
                 /etc/opt/edge/policies/managed \
                 /etc/vivaldi/policies/managed \
                 /etc/thorium/policies/managed; do
    sudo mkdir -p "$policy_dir" 2>/dev/null || true
    sudo chmod 777 "$policy_dir" 2>/dev/null || true
done
rm -f "$HOME/.local/share/applications/brave-browser.desktop" \
      "$HOME/.local/share/applications/chromium.desktop" \
      "$HOME/.local/share/applications/google-chrome.desktop" 2>/dev/null || true

# Restart xdg-desktop-portal-hyprland to prevent CPU loop (known 1.4.x issue)
if systemctl --user is-active xdg-desktop-portal-hyprland &>/dev/null; then
    systemctl --user restart xdg-desktop-portal-hyprland 2>/dev/null || true
    ok "xdg-desktop-portal-hyprland restarted (fixes CPU loop)"
fi

verify_critical_tools
verify_swaync_running
verify_theme_outputs

# Restart waybar and swaync to pick up new configs
if pgrep -x waybar > /dev/null 2>&1; then
    log "Restarting waybar..."
    pkill -x waybar 2>/dev/null || true
    sleep 0.3
    waybar &>/dev/null &
fi
if pgrep -x swaync > /dev/null 2>&1; then
    log "Reloading swaync config..."
    swaync-client -R 2>/dev/null || true
    swaync-client --reload-css 2>/dev/null || true
fi

# Start workspace monitor if Hyprland is running
if pgrep -x Hyprland > /dev/null 2>&1; then
    if ! pgrep -f workspace-monitor > /dev/null 2>&1; then
        "$CONFIG_DIR/waybar/scripts/workspace-monitor.sh" &
    fi
fi

echo ""
echo -e "${GREEN}╔══════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Installation complete!       ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════╝${NC}"
echo ""
echo -e "  ${YELLOW}Usage:${NC}"
echo "    SUPER+SHIFT+W    — Open wallpaper picker"
echo ""
echo -e "  ${YELLOW}Or run manually:${NC}"
echo "    ~/.config/wallust/wallpaper-select.sh"
echo ""
echo -e "  ${YELLOW}Notes:${NC}"
echo "    • Add wallpapers to $WALL_DIR/"
echo "    • Add live wallpapers (.mp4/.webm/.gif) to $WALL_DIR/live/"
echo "    • To manually generate theme: wallust run <wallpaper>"
echo "    • Install mpvpaper for live wallpaper support"
echo ""
