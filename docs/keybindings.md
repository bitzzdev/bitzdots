# Keybindings

All keyboard shortcuts for bitzdots. Modifiers:
- `SUPER` = Windows/Command key
- `SHIFT` = Shift key
- `CTRL` = Control key
- `ALT` = Alt key

## Window Management

| Keybinding | Action |
|---|---|
| `SUPER + Q` | Close active window |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + H` | Toggle window float |
| `SUPER + CTRL + F` | Toggle window float (alternate) |
| `SUPER + mouse:272` | Move window (mouse drag) |
| `SUPER + mouse:273` | Resize window (mouse drag) |

## Workspaces

| Keybinding | Action |
|---|---|
| `SUPER + 1-9` | Focus workspace 1-9 |
| `SUPER + 0` | Focus workspace 10 |
| `SUPER + SHIFT + 1-9` | Move window to workspace 1-9 |
| `SUPER + SHIFT + 0` | Move window to workspace 10 |
| `SUPER + mouse_down` | Previous workspace |
| `SUPER + mouse_up` | Next workspace |
| `SUPER + ALT + mouse_down` | Move window to adjacent workspace |
| `SUPER + ALT + mouse_up` | Move window to adjacent workspace |
| `SUPER + SHIFT + mouse_down` | Move window to adjacent workspace |
| `SUPER + SHIFT + mouse_up` | Move window to adjacent workspace |

## Applications

| Keybinding | Action |
|---|---|
| `SUPER + T` | Open terminal (kitty) |
| `SUPER + E` | Open file manager (nautilus) |
| `SUPER + W` | Open browser (Brave) |
| `SUPER + C` | Open Chromium |
| `SUPER + Space` | App launcher (rofi) |
| `ALT + Space` | Spotlight search (files + folders + web, rofi) |
| `SUPER + SHIFT + Space` | Alternate launcher (wofi) |

## Screenshots & Recording

| Keybinding | Action |
|---|---|
| `Print` | Fullscreen screenshot (save + clipboard) |
| `SUPER + SHIFT + S` | Selection screenshot (save + clipboard) |
| `SUPER + SHIFT + T` | OCR screenshot (eink-ocr) |
| `SUPER + R` | Toggle fullscreen recording |
| `SUPER + SHIFT + R` | Toggle region recording |

## System

| Keybinding | Action |
|---|---|
| `SUPER + L` | Lock screen (hyprlock) |
| `SUPER + P` | Power menu (rofi) |
| `SUPER + N` | Toggle notification panel |
| `SUPER + V` | Clipboard history — pick to copy (rofi + cliphist) |
| `SUPER + SHIFT + V` | Clipboard history — pick to delete |
| `SUPER + ALT + V` | Wipe clipboard history |
| `SUPER + CTRL + C` | Color picker (hyprpicker + copy) |
| `SUPER + SHIFT + W` | Wallpaper picker |
| `SUPER + CTRL + Q` | Exit Hyprland |

## Resize Submode

Activate with `SUPER + CTRL + R`, then:

| Keybinding | Action |
|---|---|
| `Left` | Resize window left by 10px |
| `Right` | Resize window right by 10px |
| `Up` | Resize window up by 10px |
| `Down` | Resize window down by 10px |
| `Escape` | Exit resize mode |
| `SUPER + CTRL + R` | Exit resize mode |

## Waybar Click Actions

| Module | Left Click | Right Click | Scroll |
|--------|-----------|-------------|--------|
| **Workspaces** | Focus workspace | — | Cycle workspaces |
| **Media** | Play/Pause | Stop | Next/Previous |
| **Network** | Open impala (WiFi TUI) | — | — |
| **Bluetooth** | Open bluetui | — | — |
| **Audio** | Open pulsemixer | — | Volume up/down |
| **Brightness** | — | — | Brightness up/down |
| **CPU** | Open btop | — | — |
| **Memory** | Open btop | — | — |
| **Power Profile** | Cycle profile | — | — |
| **Notification** | Toggle panel | Toggle DnD | — |
| **Power** | Power menu | — | — |
