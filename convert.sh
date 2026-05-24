#!/bin/bash

CLEAN_MODE=false
if [[ "$1" == "--clean" ]]; then
    CLEAN_MODE=true
fi

command -v jq >/dev/null 2>&1 || { echo >&2 "Error: 'jq' is required."; exit 1; }
command -v magick >/dev/null 2>&1 || { echo >&2 "Error: 'magick' is required."; exit 1; }

COCOON_INDEX="CocoonFE/platforms/index.json"
TECHDWEEB_DIR="techdweeb-es-de"
SYS_MAPPING="config/systems_mapping.csv"
SND_MAPPING="config/sounds_mapping.csv"
THEME_BASE="theme_base"

TOP_LEVEL_SYSTEMS=("favorites" "recent" "unplayed" "most_played" "newly_added")

if [ "$CLEAN_MODE" = true ]; then
    echo "Cleaning existing theme_base..."
    rm -rf "$THEME_BASE"
fi

echo "Preparing theme_base directories..."
mkdir -p "$THEME_BASE/smart_folders"
mkdir -p "$THEME_BASE/sounds"

echo "Converting logos and icons..."
while IFS=, read -r es_id cocoon_id; do
    es_id=$(echo "$es_id" | xargs); cocoon_id=$(echo "$cocoon_id" | xargs)
    [ -z "$es_id" ] || [ -z "$cocoon_id" ] && continue
    if ! grep -q "\"$cocoon_id\"" "$COCOON_INDEX"; then continue; fi

    IS_TOP=false
    for top in "${TOP_LEVEL_SYSTEMS[@]}"; do [[ "$cocoon_id" == "$top" ]] && IS_TOP=true && break; done

    if [ "$IS_TOP" = true ]; then TARGET_DIR="$THEME_BASE/$cocoon_id"
    else TARGET_DIR="$THEME_BASE/smart_folders/$cocoon_id"; fi

    mkdir -p "$TARGET_DIR"

    SRC_LOGO="$TECHDWEEB_DIR/_inc/systems/logos/${es_id}.png"
    if [ -f "$SRC_LOGO" ]; then
        # cp -u ensures we only copy if the source is newer
        cp -u "$SRC_LOGO" "$TARGET_DIR/logo.png"
        
        # Run magick if:
        # 1. Clean mode is explicitly enabled
        # 2. The icon hasn't been generated yet
        # 3. The upstream source logo is newer than our generated icon
        if [ "$CLEAN_MODE" = true ] || [ ! -f "$TARGET_DIR/icon.png" ] || [ "$SRC_LOGO" -nt "$TARGET_DIR/icon.png" ]; then
            echo "  Generating icon for $cocoon_id..."
            magick "$SRC_LOGO" -trim -resize 450x450\> -background none -gravity center -extent 512x512 "$TARGET_DIR/icon.png"
        fi
    fi
done < "$SYS_MAPPING"

echo "Copying sounds..."
while IFS=, read -r cocoon_snd esde_snd; do
    cocoon_snd=$(echo "$cocoon_snd" | xargs); esde_snd=$(echo "$esde_snd" | xargs)
    [ -z "$cocoon_snd" ] || [ -z "$esde_snd" ] && continue
    
    SRC_SND="$TECHDWEEB_DIR/_inc/sounds/${esde_snd}.wav"
    [ -f "$SRC_SND" ] && cp -u "$SRC_SND" "$THEME_BASE/sounds/${cocoon_snd}.wav"
done < "$SND_MAPPING"

echo "Local asset conversion complete! -> ./$THEME_BASE"