#!/usr/bin/env bash
# Wallpaper picker — wofi list selector
# Searches both ultrawide and 4k wallpaper dirs, lets you pick one,
# applies it to both monitors and triggers pywal

WALLPAPER_BASE="$HOME/Pictures/Wallpapers"
ROTATE_SCRIPT="$HOME/.config/hypr/scripts/wallpaper-rotate.sh"
STYLE="$HOME/.config/wofi/style-launcher.css"

declare -A path_map

while IFS= read -r img; do
  name=$(basename "$img")
  dir=$(basename "$(dirname "$img")")
  label="[$dir] $name"
  path_map["$label"]="$img"
done < <(find "$WALLPAPER_BASE" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort)

[[ ${#path_map[@]} -eq 0 ]] && notify-send "Wallpaper Picker" "No wallpapers found in $WALLPAPER_BASE" && exit 1

selected=$(printf '%s\n' "${!path_map[@]}" | sort | wofi \
  --dmenu \
  --style "$STYLE" \
  --prompt "  Wallpaper" \
  --width 700 \
  --height 500 \
  --insensitive \
  --hide-scroll \
  --no-actions)

[[ -z "$selected" ]] && exit 0

full="${path_map[$selected]}"
[[ -z "$full" || ! -f "$full" ]] && exit 0

exec "$ROTATE_SCRIPT" set "$full"
