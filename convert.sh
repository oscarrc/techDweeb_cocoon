#!/bin/bash
CLEAN_MODE=false
if [[ "$1" == "--clean" ]]; then
    CLEAN_MODE=true
fi

command -v jq >/dev/null 2>&1 || { echo >&2 "Error: 'jq' is required."; exit 1; }
command -v magick >/dev/null 2>&1 || { echo >&2 "Error: 'magick' is required."; exit 1; }

COCOON_INDEX="CocoonFE/platforms/index.json"
TECHDWEEB_DIR="techdweeb-es-de"
SYS_MAPPING="config/systems.json"
SND_MAPPING="config/sounds.json"
THEME_BASE="theme"
README_FILE="README.md"

TOP_LEVEL_SYSTEMS=("favorites" "recent" "unplayed" "most_played" "newly_added")

if [ "$CLEAN_MODE" = true ]; then
    echo "Cleaning existing theme..."
    rm -rf "$THEME_BASE"
fi

echo "Preparing theme directories..."
mkdir -p "$THEME_BASE/smart_folders"
mkdir -p "$THEME_BASE/sounds"

echo "Converting logos and icons..."
for cocoon_id in $(jq -r 'keys[]' "$SYS_MAPPING"); do
    # Extract es_id and cocoon string
    es_id=$(jq -r ".\"$cocoon_id\".esde" "$SYS_MAPPING")
    cocoon_val=$(jq -r ".\"$cocoon_id\".cocoon" "$SYS_MAPPING")

    # Verify the platform exists in CocoonFE index
    if ! grep -q "\"$cocoon_id\"" "$COCOON_INDEX"; then
        continue
    fi

    # Determine Top Level or Standard Platform
    IS_TOP=false
    for top in "${TOP_LEVEL_SYSTEMS[@]}"; do
        if [[ "$cocoon_id" == "$top" ]]; then
            IS_TOP=true
            break
        fi
    done

    if [ "$IS_TOP" = true ]; then
        TARGET_DIR="$THEME_BASE/$cocoon_id"
    else
        TARGET_DIR="$THEME_BASE/smart_folders/$cocoon_id"
    fi

    mkdir -p "$TARGET_DIR"

    SRC_LOGO="$TECHDWEEB_DIR/_inc/systems/logos/${es_id}.png"
    
    if [ -f "$SRC_LOGO" ]; then
        # Copy original logo (only if newer)
        cp -u "$SRC_LOGO" "$TARGET_DIR/logo.png"
        
        # Run magick if: Clean mode is true, icon is missing, or source logo is newer than the icon
        if [ "$CLEAN_MODE" = true ] || [ ! -f "$TARGET_DIR/icon.png" ] || [ "$SRC_LOGO" -nt "$TARGET_DIR/icon.png" ]; then
            echo "  Generating icon for $cocoon_id..."
            magick "$SRC_LOGO" -trim -resize 450x450\> -background none -gravity center -extent 512x512 "$TARGET_DIR/icon.png"
        fi
    fi
  done

echo "Copying sounds..."
for cocoon_snd in $(jq -r 'keys[]' "$SND_MAPPING"); do
    esde_snd=$(jq -r ".\"$cocoon_snd\"" "$SND_MAPPING")
    
    if [ -z "$esde_snd" ] || [ "$esde_snd" == "null" ]; then
        continue
    fi
    
    SRC_SND="$TECHDWEEB_DIR/_inc/sounds/${esde_snd}.wav"
    
    if [ -f "$SRC_SND" ]; then
        cp -u "$SRC_SND" "$THEME_BASE/sounds/${cocoon_snd}.wav"
    else
        echo "  Warning: Expected sound '$SRC_SND' not found in ES-DE repository."
    fi
done

echo "Local asset conversion complete! -> ./$THEME_BASE"


echo "Updating README.md.."

TABLE_TMP=$(mktemp)

# Build the table header
echo "| System | Icon | Logo | Hero |" > "$TABLE_TMP"
echo "|---|:---:|:---:|:---:|" >> "$TABLE_TMP"

# Read keys alphabetically to keep the table sorted
for cocoon_id in $(jq -r 'keys[]' "$SYS_MAPPING" | sort); do
    IS_TOP=false
    for top in "${TOP_LEVEL_SYSTEMS[@]}"; do [[ "$cocoon_id" == "$top" ]] && IS_TOP=true && break; done

    if [ "$IS_TOP" = true ]; then TARGET_DIR="$THEME_BASE/$cocoon_id"
    else TARGET_DIR="$THEME_BASE/smart_folders/$cocoon_id"; fi

    # Check if the folder exists (meaning we processed it or attempted to)
    if [ -d "$TARGET_DIR" ]; then
        ICON_TAG="❌"
        LOGO_TAG="❌"
        HERO_TAG="➖"
        
        # Swap to checkmark if the file is found
        [ -f "$TARGET_DIR/icon.png" ] && ICON_TAG="✅"
        [ -f "$TARGET_DIR/logo.png" ] && LOGO_TAG="✅"

        # Capitalize system name for display
        DISPLAY_NAME=$(echo "$cocoon_id" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
        echo "| **$DISPLAY_NAME** | $ICON_TAG | $LOGO_TAG | $HERO_TAG |" >> "$TABLE_TMP"
    fi
done

# Check if README exists
if [ -f "$README_FILE" ]; then
    # If the "## Systems overview" header exists, delete it and everything below it
    if grep -q "^## Systems overview" "$README_FILE"; then
        sed -i '/^## Systems overview/,$d' "$README_FILE"
    fi

    # Append the new section and table to the end of the file
    echo "## Systems overview" >> "$README_FILE"
    echo "" >> "$README_FILE"
    cat "$TABLE_TMP" >> "$README_FILE"
    
    echo "README.md successfully updated!"
else
    echo "Warning: $README_FILE not found. Skipping table injection."
fi

rm -f "$TABLE_TMP"