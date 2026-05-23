#!/bin/bash

# Ensure a color argument is provided
if [ -z "$1" ]; then
    echo "Usage: ./convert_techdweeb.sh [orange|purple|cyan|green|pink|blue|red|grey|dmg|black]"
    exit 1
fi

VERSION=${THEME_VERSION:-$(cat VERSION)}
COLOR_ARG=$(echo "$1" | tr '[:upper:]' '[:lower:]')
SYSTEMS_MAPPING_FILE="systems_mapping.csv"
SOUNDS_MAPPING_FILE="sounds_mapping.csv"
TOP_LEVEL_SYSTEMS=("favorites" "recent" "unplayed" "most_played" "newly_added")

# Map colors
case $COLOR_ARG in
    orange) PRIMARY_HEX="#9e4700"; DARK_HEX="#482100"; BG_HEX="#0a0a0a"; SURFACE_HEX="#171717"; SELECTOR_HEX="#4d4b4b" ;;
    purple) PRIMARY_HEX="#9D0090"; DARK_HEX="#490042"; BG_HEX="#0a0a0a"; SURFACE_HEX="#171717"; SELECTOR_HEX="#4d4b4b" ;;
    cyan)   PRIMARY_HEX="#009D7F"; DARK_HEX="#00493C"; BG_HEX="#0a0a0a"; SURFACE_HEX="#171717"; SELECTOR_HEX="#4d4b4b" ;;
    green)  PRIMARY_HEX="#859E00"; DARK_HEX="#3C4800"; BG_HEX="#0a0a0a"; SURFACE_HEX="#171717"; SELECTOR_HEX="#4d4b4b" ;;
    pink)   PRIMARY_HEX="#EF4E5E"; DARK_HEX="#9D2A36"; BG_HEX="#0a0a0a"; SURFACE_HEX="#171717"; SELECTOR_HEX="#4d4b4b" ;;
    blue)   PRIMARY_HEX="#003B9E"; DARK_HEX="#001A48"; BG_HEX="#0a0a0a"; SURFACE_HEX="#171717"; SELECTOR_HEX="#4d4b4b" ;;
    red)    PRIMARY_HEX="#9E0021"; DARK_HEX="#48000E"; BG_HEX="#0a0a0a"; SURFACE_HEX="#171717"; SELECTOR_HEX="#4d4b4b" ;;
    grey)   PRIMARY_HEX="#686868"; DARK_HEX="#303030"; BG_HEX="#0a0a0a"; SURFACE_HEX="#171717"; SELECTOR_HEX="#4d4b4b" ;;
    dmg)    PRIMARY_HEX="#988A4C"; DARK_HEX="#414A31"; BG_HEX="#0a0a0a"; SURFACE_HEX="#171717"; SELECTOR_HEX="#4d4b4b" ;;
    black)  PRIMARY_HEX="#909090"; DARK_HEX="#151515"; BG_HEX="#000000"; SURFACE_HEX="#0a0a0a"; SELECTOR_HEX="#2a2a2a" ;;
    *) echo "Error: Invalid color."; exit 1 ;;
esac

REPO_URL="https://github.com/anthonycaccese/techdweeb-es-de.git"
TMP_DIR="/tmp/techdweeb_es_tmp"

# Directory Setup
OUT_DIR="./out"
THEME_NAME="techdweeb-${COLOR_ARG}"
THEME_DIR="$OUT_DIR/$THEME_NAME"
WALLPAPERS_DIR="$THEME_DIR/wallpapers"
SOUNDS_DIR="$THEME_DIR/sounds"

echo "Cleaning up..."
rm -rf "$TMP_DIR" "$THEME_DIR" "$OUT_DIR/$THEME_NAME.zip"
mkdir -p "$THEME_DIR/smart_folders/by_platform" "$WALLPAPERS_DIR" "$SOUNDS_DIR"

echo "Cloning TechDweeb..."
git clone --depth 1 "$REPO_URL" "$TMP_DIR" &> /dev/null

echo "Processing systems..."
while IFS=, read -r es_id cocoon_id; do
    es_id=$(echo "$es_id" | xargs); cocoon_id=$(echo "$cocoon_id" | xargs)
    [ -z "$es_id" ] && [ -z "$cocoon_id" ] && continue

    IS_TOP=false
    for top in "${TOP_LEVEL_SYSTEMS[@]}"; do [[ "$cocoon_id" == "$top" ]] && IS_TOP=true; done

    if [ "$IS_TOP" = true ]; then
        TARGET_DIR="$THEME_DIR/smart_folders/$cocoon_id"
    else
        TARGET_DIR="$THEME_DIR/smart_folders/by_platform/$cocoon_id"
    fi

    mkdir -p "$TARGET_DIR"
    
    if [ -n "$es_id" ] && [ -f "$TMP_DIR/_inc/systems/logos/${es_id}.png" ]; then
        cp "$TMP_DIR/_inc/systems/logos/${es_id}.png" "$TARGET_DIR/logo.png"
        magick "$TMP_DIR/_inc/systems/logos/${es_id}.png" -trim -resize 450x450\> -background none -gravity center -extent 512x512 "$TARGET_DIR/icon.png"
    fi
done < "$SYSTEMS_MAPPING_FILE"

echo "Processing sounds and wallpapers..."
while IFS=, read -r cocoon_snd esde_snd; do
    cocoon_snd=$(echo "$cocoon_snd" | xargs); esde_snd=$(echo "$esde_snd" | xargs)
    [ -n "$cocoon_snd" ] && [ -n "$esde_snd" ] && [ -f "$TMP_DIR/_inc/sounds/${esde_snd}.wav" ] && cp "$TMP_DIR/_inc/sounds/${esde_snd}.wav" "$SOUNDS_DIR/${cocoon_snd}.wav"
done < "$SOUNDS_MAPPING_FILE"

[ -f "$TMP_DIR/_inc/images/system-view/${COLOR_ARG}.png" ] && cp "$TMP_DIR/_inc/images/system-view/${COLOR_ARG}.png" "$WALLPAPERS_DIR/main.png"
[ -f "$TMP_DIR/_inc/images/system-view/black.png" ] && cp "$TMP_DIR/_inc/images/system-view/black.png" "$WALLPAPERS_DIR/external.png"

echo "Generating theme.json..."
cat <<EOF > "$THEME_DIR/theme.json"
{
  "name": "TechDweeb (${COLOR_ARG^})",
  "author": "Anthony Caccese (Ported by Oscar R.C.)",
  "version": "${THEME_VERSION}",
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
  "wallpaper_main": "main.png",
  "wallpaper_external": "external.png"
}
EOF

echo "Zipping..."
cd "$OUT_DIR"
7z a -tzip "${THEME_NAME}.zip" "$THEME_NAME" > /dev/null
rm -rf "$THEME_NAME"
cd ..

rm -rf "$TMP_DIR"
echo "Done! ${THEME_NAME}.zip created inside ./out/"