#!/bin/bash

# --- Setup & Configuration ---
COLORS_FILE="config/colors.json"
THEME_BASE="theme"
OUT_DIR="out"
VERSION=${THEME_VERSION:-$(cat VERSION)}

# --- Functions ---

# 1. Dependency Check
check_dependencies() {
    for cmd in jq 7z; do
        command -v "$cmd" >/dev/null 2>&1 || { echo "Error: '$cmd' is required."; exit 1; }
    done
}

# 2. Template Generation
create_theme_json() {
    local target_file=$1 color=$2
    # Load colors from file in a single pass to minimize subshell calls
    local data=$(jq -r ".\"$color\"" "$COLORS_FILE")
    
    cat <<EOF > "$target_file"
{
  "name": "TechDweeb (${color^})",
  "author": "Anthony Caccese (Ported by Oscar R.C.)",
  "version": "${VERSION}",
  "theme_mode": "OLED",
  "color_scheme": {
    "background_gradient_start": "$(echo $data | jq -r .bg)",
    "background_gradient_end": "$(echo $data | jq -r .bg)",
    "card_gradient_start": "$(echo $data | jq -r .surface)",
    "card_gradient_end": "$(echo $data | jq -r .bg)",
    "text_primary": "$(echo $data | jq -r .primary)",
    "text_secondary": "$(echo $data | jq -r .selector)",
    "icon_tint": "$(echo $data | jq -r .primary)",
    "tile_background": "$(echo $data | jq -r .surface)",
    "tile_border": "$(echo $data | jq -r .selector)",
    "toggle_off_gradient_start": "$(echo $data | jq -r .dark)",
    "toggle_off_gradient_end": "$(echo $data | jq -r .dark)",
    "toggle_thumb_gradient_start": "$(echo $data | jq -r .dark)",
    "toggle_thumb_gradient_end": "$(echo $data | jq -r .selector)",
    "accent_gradient_start": "$(echo $data | jq -r .primary)",
    "accent_gradient_end": "$(echo $data | jq -r .primary)"
  },
  "settings": {
    "icon_roundness": 0.2,
    "hero_display_style": "VIGNETTE",
    "icon_scale": 0.9
  }
}
EOF
}

# 3. Packaging Process
package_theme() {
    local color=$1
    local theme_name="techdweeb-${color}"
    local target_dir="$OUT_DIR/$theme_name"

    echo "Packaging: $color..."
    rm -rf "$target_dir"
    cp -a "$THEME_BASE" "$target_dir"
    
    create_theme_json "$target_dir/theme.json" "$color"
    
    (cd "$OUT_DIR" && 7z a -tzip "${theme_name}.zip" "$theme_name" > /dev/null && rm -rf "$theme_name")
}

# --- Main Execution ---

check_dependencies

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

for color in $(jq -r 'keys[]' "$COLORS_FILE"); do
    package_theme "$color"
done

echo "All themes generated in ./out/"