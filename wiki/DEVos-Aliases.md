# DEVos System Aliases

Quick reference for **DEVos** system commands and Pacman shortcuts built into `fish` shell on Arch Linux.

## Overview

The `dev` helper command provides concise, intuitive shortcuts for package management, AUR operations, and system administration on Arch Linux.

> [!NOTE]
> These aliases are loaded exclusively on Arch Linux systems (checked via `/etc/arch-release`).

---

## Package Management (Pacman)

| Command | Alias | Full Command | Description |
| :--- | :--- | :--- | :--- |
| `dev u` | `dev-u` | `sudo pacman -Syu` | Perform full system upgrade |
| `dev s <term>` | `dev-s <term>` | `pacman -Ss <term>` | Search for packages in official repos |
| `dev i <pkg>` | `dev-i <pkg>` | `sudo pacman -S <pkg>` | Install a package from official repos |
| `dev r <pkg>` | `dev-r <pkg>` | `sudo pacman -Rns <pkg>` | Remove a package and its unneeded dependencies |
| `dev q <pkg>` | `dev-q <pkg>` | `pacman -Qi <pkg>` | View detailed package information |
| `dev l <pkg>` | `dev-l <pkg>` | `pacman -Ql <pkg>` | List all files installed by a package |
| `dev c` | `dev-c` | `sudo pacman -Sc` | Clean uninstalled packages from cache |
| `dev orphans` | `dev-orphans` | `sudo pacman -Rns (pacman -Qtdq)` | Remove all orphaned/unused packages |

---

## AUR Helper Shortcuts (paru / yay)

Auto-detects whether `paru` or `yay` is installed on your system.

| Command | Alias | Equivalent Command | Description |
| :--- | :--- | :--- | :--- |
| `dev aur` | `dev-aur` | `paru` / `yay` | Launch AUR helper interactively |
| `dev au` | `dev-au` | `paru -Syu` / `yay -Syu` | Upgrade repo and AUR packages |
| `dev as <term>` | `dev-as <term>` | `paru -Ss <term>` / `yay -Ss <term>` | Search both official repos and AUR |
| `dev ai <pkg>` | `dev-ai <pkg>` | `paru -S <pkg>` / `yay -S <pkg>` | Install package from repo or AUR |

---

## System Utilities

| Command | Alias | Full Command | Description |
| :--- | :--- | :--- | :--- |
| `dev sys` | `dev-info` | `fastfetch` | Display system summary & specs |
| `dev top` | `dev-top` | `btop` | Launch interactive resource monitor |
| `dev log` | `dev-log` | `journalctl -xe` | View recent system logs with explanation |
| `dev services` | `dev-services` | `systemctl list-units --type=service` | List active systemd services |
| `dev reboot` | — | `systemctl reboot` | Restart the computer |
| `dev poweroff` | — | `systemctl poweroff` | Power off the computer |

---

## Usage Examples

```fish
# Update all system packages
dev u

# Search for a package
dev s firefox

# Install a package
dev i neovim

# Search AUR packages
dev as hyprland

# View system information
dev sys
```
