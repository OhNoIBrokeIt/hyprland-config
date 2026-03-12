#!/usr/bin/env bash
# Keybind cheatsheet — wofi display of all hyprland binds

STYLE="$HOME/.config/wofi/style.css"
CONF="$HOME/.config/hypr/hyprland.conf"

binds=$(grep -E '^\s*bind\s*=' "$CONF" | \
  sed 's/^\s*bind\s*[rl]*\s*=\s*//' | \
  awk -F',' '{
    mod=$1; key=$2; act=$3; arg=$4
    gsub(/^ +| +$/, "", mod)
    gsub(/^ +| +$/, "", key)
    gsub(/^ +| +$/, "", act)
    gsub(/^ +| +$/, "", arg)
    gsub(/\$mainMod/, "SUPER", mod)
    label = mod " + " key
    if (arg != "") act = act " " arg
    printf "%-28s  %s\n", label, act
  }')

echo "$binds" | wofi --dmenu \
  --style "$STYLE" \
  --prompt "  Keybinds" \
  --width 700 \
  --height 580 \
  --hide-scroll \
  --no-actions \
  --insensitive \
  --location 3 \
  --xoffset -20 \
  --yoffset 46
