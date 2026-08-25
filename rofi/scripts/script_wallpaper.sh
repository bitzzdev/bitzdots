#!/bin/bash

# --- Configuración de Rutas ---
WALL_DIR="$HOME/wallpapers"
THEME_GRID="$HOME/.config/rofi/themes/wallpaper-grid.rasi"

# RUTA ESPECÍFICA SOLICITADA
STYLE_TETO="/home/dev/.config/rofi/launchers/type-6/style-4.rasi"

# 1. Verificar si awww-daemon está activo
if ! pgrep -x "awww-daemon" > /dev/null; then
    awww-daemon &
    sleep 0.5
fi

# 2. Generar la lista de archivos para el menú
entries=""
while IFS= read -r file; do
    entries+="${file}\0icon\x1f${WALL_DIR}/${file}\n"
done < <(ls "$WALL_DIR" | grep -E ".jpg$|.jpeg$|.png$|.webp$")

# 3. Lanzar Rofi (Menú de cuadrícula)
selected=$(echo -e "$entries" | rofi \
    -dmenu \
    -i \
    -theme "$THEME_GRID" \
    -p " " \
    -show-icons)

# 4. Aplicar y Vincular
if [ -n "$selected" ]; then
    FULL_PATH="$WALL_DIR/$selected"

    # Cambiar fondo de pantalla
    awww img "$FULL_PATH" \
        --transition-type grow \
        --transition-pos center \
        --transition-duration 2 \
        --transition-fps 60

    ln -sf "$FULL_PATH" /home/dev/.cache/current_wallpaper.png

    # Vincular con style-4.rasi inyectando la nueva ruta en la línea de background-image
    # Esto modifica la línea 56 del archivo proporcionado 
    sed -i "s|background-image:.*url(\".*\",|background-image: url(\"$FULL_PATH\",|" "$STYLE_TETO"
fi
