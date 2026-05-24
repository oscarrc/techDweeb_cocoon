#!/bin/bash

command -v jq >/dev/null 2>&1 || { echo >&2 "Error: 'jq' is required."; exit 1; }
command -v 7z >/dev/null 2>&1 || { echo >&2 "Error: '7z' (p7zip-full) is required."; exit 1; }

VERSION=${THEME_VERSION:-$(cat VERSION)}
COLORS_FILE="config/colors.json"
THEME_BASE="theme"
OUT_DIR="out"

mkdir -p "$OUT_DIR"

for color in $(jq -r 'keys[]' "$COLORS_FILE"); do
    echo "Packaging: $color..."

    PRIMARY_HEX=$(jq -r ".\"$color\".primary" "$COLORS_FILE")
    DARK_HEX=$(jq -r ".\"$color\".dark" "$COLORS_FILE")
    BG_HEX=$(jq -r ".\"$color\".bg" "$COLORS_FILE")
    SURFACE_HEX=$(jq -r ".\"$color\".surface" "$COLORS_FILE")
    SELECTOR_HEX=$(jq -r ".\"$color\".selector" "$COLORS_FILE")

    THEME_NAME="techdweeb-${color}"
    TARGET_DIR="$OUT_DIR/$THEME_NAME"
    WALLPAPERS_DIR="$TARGET_DIR/wallpapers"

    rm -rf "$TARGET_DIR"
    cp -r "$THEME_BASE" "$TARGET_DIR"

    cat <<EOF > "$TARGET_DIR/theme.json"
{
  "name": "TechDweeb (${color^})",
  "author": "Anthony Caccese (Ported by Oscar R.C.)",
  "version": "${VERSION}",
  "description": "TechDweeb ES-DE port for Cocoon",
  "theme_mode": "OLED",
  "color_scheme": {
    "background_gradient_start": "${BG_HEX}",
    "background_gradient_end": "${BG_HEX}",
    "card_gradient_start": "${SURFACE_HEX}",
    "card_gradient_end": "${BG_HEX}",
    "text_primary": "${PRIMARY_HEX}",
    "text_secondary": "${SELECTOR_HEX}",
    "icon_tint": "${PRIMARY_HEX}",
    "tile_background": "${SURFACE_HEX}",
    "tile_border": "${SELECTOR_HEX}",
    "toggle_off_gradient_start": "${DARK_HEX}",
    "toggle_off_gradient_end": "${DARK_HEX}",
    "toggle_thumb_gradient_start": "${DARK_HEX}",
    "toggle_thumb_gradient_end": "${SELECTOR_HEX}",
    "drop_shadow": "rgba(0,0,0,0.5)",
    "inner_shadow_light": "rgba(255,255,255,0.05)",
    "inner_shadow_dark": "rgba(0,0,0,0.5)",
    "success": "#27ae60",
    "warning": "#f39c12",
    "divider": "#1E1E1E",
    "accent_gradient_start": "${PRIMARY_HEX}",
    "accent_gradient_end": "${PRIMARY_HEX}",
    "accent_glow": "rgba(0,0,0,0.3)"
  },
  "settings": {
    "icon_roundness": 0.2,
    "hero_display_style": "NONE",
    "hero_logo_scale": 0.6,
    "hero_folder_logo_scale": 0.6,
    "hero_gradient_style": "NONE",
    "icon_scale": 0.9,
    "hover_scale": 1
  },
  "wallpaper_main": "${color}.png",
  "wallpaper_external": "black.png"
}
EOF

    (cd "$OUT_DIR" && 7z a -tzip "${THEME_NAME}.zip" "$THEME_NAME" > /dev/null && rm -rf "$THEME_NAME")
done

echo "All themes generated in ./out/"