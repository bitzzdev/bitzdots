#!/bin/bash
# Terminal previewer for fzf wallpaper selection
# Previews image files using chafa, kitty icat, timg, or file metadata

TARGET="$1"
[ -z "$TARGET" ] && exit 0

COLS="${FZF_PREVIEW_COLUMNS:-50}"
LINES="${FZF_PREVIEW_LINES:-30}"

if command -v chafa &>/dev/null; then
    chafa -f kitty --size "${COLS}x${LINES}" "$TARGET" 2>/dev/null || \
    chafa --size "${COLS}x${LINES}" "$TARGET" 2>/dev/null
elif command -v timg &>/dev/null; then
    timg -pV --width="$COLS" --height="$LINES" "$TARGET" 2>/dev/null
elif command -v kitty &>/dev/null && [ -n "$KITTY_WINDOW_ID" ]; then
    kitty +kitten icat --clear --transfer-mode=stream --place "${COLS}x${LINES}@0x0" "$TARGET" 2>/dev/null
elif command -v identify &>/dev/null; then
    echo -e "\033[1;36mImage File:\033[0m $(basename "$TARGET")"
    echo -e "\033[1;33mPath:\033[0m $TARGET"
    identify "$TARGET" 2>/dev/null | awk '{print "Dimensions: " $3 "\nFormat: " $2}'
else
    echo -e "\033[1;36mWallpaper:\033[0m $(basename "$TARGET")"
    echo -e "\033[1;33mPath:\033[0m $TARGET"
    ls -lh "$TARGET" 2>/dev/null | awk '{print "Size: " $5}'
fi
