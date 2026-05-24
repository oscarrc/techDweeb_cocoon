#!/bin/bash

# --- Configuration & Constants ---
CLEAN_MODE=false
[[ "$1" == "--clean" ]] && CLEAN_MODE=true

COCOON_INDEX="CocoonFE/platforms/index.json"
TECHDWEEB_DIR="techdweeb-es-de"
SYS_MAPPING="config/systems.json"
FLDR_MAPPING="config/folders.json"
SND_MAPPING="config/sounds.json"
THEME_BASE="theme"
README_FILE="README.md"

# --- Functions ---

# Processes images and generates icons
process_assets() {
    local es_id=$1 target_dir=$2 cocoon_id=$3
    mkdir -p "$target_dir"
    local src_logo="$TECHDWEEB_DIR/_inc/systems/logos/${es_id}.png"
    
    if [ -f "$src_logo" ]; then
        cp -u "$src_logo" "$target_dir/logo.png"
        if [ "$CLEAN_MODE" = true ] || [ ! -f "$target_dir/icon.png" ] || [ "$src_logo" -nt "$target_dir/icon.png" ]; then
            echo "  Generating icon for $cocoon_id..."
            magick "$src_logo" -trim -resize 450x450\> -background none -gravity center -extent 512x512 "$target_dir/icon.png"
        fi
    fi
}

# Generates markdown table rows for a given mapping file
generate_table_section() {
    local mapping_file=$1 path_suffix=$2 title=$3
    echo -e "\n## $title\n"
    echo "| Item | Icon | Logo | Hero |"
    echo "|---|:---:|:---:|:---:|"
    
    for cocoon_id in $(jq -r 'keys[]' "$mapping_file" | sort); do
        local target_dir="$THEME_BASE/$path_suffix/$cocoon_id"
        if [ -d "$target_dir" ]; then
            local i="❌"; local l="❌"; local h="➖"
            [ -f "$target_dir/icon.png" ] && i="✅"
            [ -f "$target_dir/logo.png" ] && l="✅"
            local display_name=$(echo "$cocoon_id" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
            echo "| **$display_name** | $i | $l | $h |"
        fi
    done
}

# --- Main Logic ---

echo "Preparing theme directories..."
mkdir -p "$THEME_BASE/smart_folders/by_platform" "$THEME_BASE/sounds"

echo "Converting Systems..."
for id in $(jq -r 'keys[]' "$SYS_MAPPING"); do
    process_assets "$(jq -r ".\"$id\".esde" "$SYS_MAPPING")" "$THEME_BASE/smart_folders/by_platform/$id" "$id"
done

echo "Converting Folders..."
for id in $(jq -r 'keys[]' "$FLDR_MAPPING"); do
    process_assets "$(jq -r ".\"$id\"" "$FLDR_MAPPING")" "$THEME_BASE/smart_folders/$id" "$id"
done

echo "Copying sounds..."
for snd in $(jq -r 'keys[]' "$SND_MAPPING"); do
    esde_snd=$(jq -r ".\"$snd\"" "$SND_MAPPING")
    [[ -z "$esde_snd" || "$esde_snd" == "null" ]] && continue
    src_snd="$TECHDWEEB_DIR/_inc/sounds/${esde_snd}.wav"
    [[ -f "$src_snd" ]] && cp -u "$src_snd" "$THEME_BASE/sounds/${snd}.wav" || echo "  Warning: $src_snd not found."
done

echo "Copying wallpapers..."
# Ensure the destination directory exists
mkdir -p "$THEME_BASE/wallpapers"

# Use 'cp -u' to update only if the source is newer
for wp in "$TECHDWEEB_DIR/_inc/images/system-view/"*.png; do
    [[ -f "$wp" ]] && cp -u "$wp" "$THEME_BASE/wallpapers/$(basename "$wp")"
done

echo "Updating README.md..."
if [ -f "$README_FILE" ]; then
    sed -i '/^## Systems overview/,$d' "$README_FILE"
    {
        generate_table_section "$SYS_MAPPING" "smart_folders/by_platform" "Systems overview"
        generate_table_section "$FLDR_MAPPING" "smart_folders" "Folders overview"
    } >> "$README_FILE"
    echo "README.md successfully updated!"
fi