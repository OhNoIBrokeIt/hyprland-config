#!/usr/bin/env bash
# =========================================================
# wallpaper-rotate.sh
# Per-monitor wallpaper rotation with swww + pywal
#
# Directory structure:
#   ~/Pictures/Wallpapers/ultrawide/   → DP-2 (5120x1440 OLED)
#   ~/Pictures/Wallpapers/4k/          → DP-3 (3840x2160)
#
# Usage:
#   wallpaper-rotate.sh              — start daemon loop
#   wallpaper-rotate.sh next         — rotate both monitors
#   wallpaper-rotate.sh next dp-2    — rotate only DP-2
#   wallpaper-rotate.sh next dp-3    — rotate only DP-3
#   wallpaper-rotate.sh check        — verify directories
# =========================================================

WALLPAPER_BASE="/home/ohnoibrokeit/Pictures/Wallpapers"
DIR_ULTRAWIDE="$WALLPAPER_BASE/ultrawide"
DIR_4K="$WALLPAPER_BASE/4k"

MONITOR_ULTRAWIDE="DP-2"
MONITOR_4K="DP-3"

INTERVAL=300   # seconds between rotations (5 min)

TRANSITION_FLAGS=(
  --transition-type     fade
  --transition-duration 2
  --transition-fps      144
)

# ---- Pywal output paths ----------------------------------
WAYBAR_COLORS="$HOME/.config/waybar/colors-waybar.css"
HYPR_COLORS="$HOME/.config/wal/colors-hyprland.conf"
KITTY_COLORS="$HOME/.config/kitty/colors-wal.conf"
SWAYNC_COLORS="$HOME/.config/swaync/colors-wal.css"

# ---- State tracking — avoids repeating last wallpaper ----
STATE_DIR="$HOME/.cache/wallpaper-rotate"
mkdir -p "$STATE_DIR"

# ----------------------------------------------------------
# Pick a random wallpaper from a dir, avoid last used
# ----------------------------------------------------------
get_random() {
  local dir="$1"
  local last_file="$STATE_DIR/last_$(basename "$dir")"
  local last=""
  [[ -f "$last_file" ]] && last=$(cat "$last_file")

  mapfile -t candidates < <(
    find "$dir" -maxdepth 1 -type f \
      \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
      | grep -Fxv "$last"
  )

  # If only one file exists, allow repeat
  if [[ ${#candidates[@]} -eq 0 ]]; then
    find "$dir" -maxdepth 1 -type f \
      \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
      | shuf -n 1
    return
  fi

  local chosen="${candidates[RANDOM % ${#candidates[@]}]}"
  echo "$chosen" > "$last_file"
  echo "$chosen"
}

# ----------------------------------------------------------
# Set wallpaper on a specific monitor output
# ----------------------------------------------------------
set_monitor_wallpaper() {
  local monitor="$1"
  local wall="$2"

  if [[ -z "$wall" || ! -f "$wall" ]]; then
    echo "[$monitor] No wallpaper found — skipping"
    return 1
  fi

  swww img "$wall" --outputs "$monitor" "${TRANSITION_FLAGS[@]}"
  echo "[$monitor] → $(basename "$wall")"
}

# ----------------------------------------------------------
# Run pywal from primary (OLED) wallpaper
# Writes color files for waybar, hyprland, kitty, swaync
# ----------------------------------------------------------
apply_pywal() {
  local wall="$1"
  [[ -z "$wall" || ! -f "$wall" ]] && return 1

  wal -i "$wall" -n --saturate 0.9 -q
  # shellcheck source=/dev/null
  source "$HOME/.cache/wal/colors.sh" 2>/dev/null || return 1

  # ---- Perceived brightness of a hex color (0-255) ----
  brightness_of() {
    local hex="${1/\#/}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    echo $(( (r*299 + g*587 + b*114) / 1000 ))
  }

  # ---- Boost a hex color to minimum brightness ----
  brighten_color() {
    local hex="${1/\#/}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    local brightness=$(( (r*299 + g*587 + b*114) / 1000 ))
    local min_brightness=130
    if (( brightness < min_brightness && brightness > 0 )); then
      local scale=$(( min_brightness * 100 / brightness ))
      r=$(( r * scale / 100 ))
      g=$(( g * scale / 100 ))
      b=$(( b * scale / 100 ))
      (( r > 255 )) && r=255
      (( g > 255 )) && g=255
      (( b > 255 )) && b=255
    fi
    printf '%02x%02x%02x' $r $g $b
  }

  # ---- Pick most saturated+bright color across all pywal colors ----
  # score = saturation * brightness — avoids dull or dark colors winning
  saturation_score() {
    local hex="${1/\#/}"
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    local max=$r
    (( g > max )) && max=$g
    (( b > max )) && max=$b
    local min=$r
    (( g < min )) && min=$g
    (( b < min )) && min=$b
    if (( max == 0 )); then echo 0; return; fi
    local sat=$(( (max - min) * 255 / max ))
    local bri=$(( (r*299 + g*587 + b*114) / 1000 ))
    echo $(( sat * bri / 255 ))
  }

  local best_hex="${color1/\#/}"
  local best_score
  best_score=$(saturation_score "$color1")
  for c in "$color2" "$color3" "$color4" "$color5" "$color6" \
            "$color9" "$color10" "$color11" "$color12" "$color13" "$color14"; do
    [[ -z "$c" ]] && continue
    local cs
    cs=$(saturation_score "$c")
    if (( cs > best_score )); then
      best_score=$cs
      best_hex="${c/\#/}"
    fi
  done

  local c2
  c2=$(brighten_color "$best_hex")
  local c4="${color4/\#/}"
  local accent="#${c2}"

  # Waybar GTK @define-color format
  cat > "$WAYBAR_COLORS" << EOF
/* Auto-generated by wallpaper-rotate.sh — do not hand-edit */
@define-color accent       ${accent};
@define-color accent_alpha alpha(${accent}, 0.80);
@define-color accent_dim   alpha(${accent}, 0.12);
@define-color accent_glow  alpha(${accent}, 0.25);
@define-color bg           ${background};
@define-color fg           ${foreground};
@define-color color1       ${color1};
@define-color color3       ${color3};
@define-color color4       ${color4};
EOF

  # Hyprland border colors
  cat > "$HYPR_COLORS" << EOF
# Auto-generated by wallpaper-rotate.sh — do not hand-edit
\$wal_accent   = rgba(${c2}ee)
\$wal_accent2  = rgba(${c4}aa)
\$wal_inactive = rgba(1a1a2a55)

general {
    col.active_border   = \$wal_accent \$wal_accent2 45deg
    col.inactive_border = \$wal_inactive
}
EOF

  # Hyprlock accent colors
  local c2fade="${c2}44"
  local c2glow="${c2}22"
  sed -i \
    -e "s/^\$accent     = .*$/\$accent     = rgba(${c2}ff)/" \
    -e "s/^\$accentFade = .*$/\$accentFade = rgba(${c2fade})/" \
    -e "s/^\$accentGlow = .*$/\$accentGlow = rgba(${c2glow})/" \
    "$HOME/.config/hypr/hyprlock.conf" 2>/dev/null

  # (rofi removed — wofi only)

  # Kitty colors
  cat > "$KITTY_COLORS" << EOF
# Auto-generated by wallpaper-rotate.sh — do not hand-edit
foreground            ${foreground}
background            ${background}
selection_foreground  ${background}
selection_background  ${accent}
cursor                ${accent}
cursor_text_color     ${background}
url_color             ${color4}
active_border_color   ${accent}
inactive_border_color ${color8}
active_tab_foreground   ${background}
active_tab_background   ${accent}
inactive_tab_foreground ${color7}
inactive_tab_background ${color0}
tab_bar_background      ${background}
color0  ${color0}
color1  ${color1}
color2  ${color2}
color3  ${color3}
color4  ${color4}
color5  ${color5}
color6  ${color6}
color7  ${color7}
color8  ${color8}
color9  ${color9}
color10 ${color10}
color11 ${color11}
color12 ${color12}
color13 ${color13}
color14 ${color14}
color15 ${color15}
EOF

  # Swaync — write colors directly into style.css header (no @import, avoids GTK cache issues)
  local swaync_style="$HOME/.config/swaync/style.css"
  if [[ -f "$swaync_style" ]]; then
    # Strip any existing auto-generated color block at the top
    sed -i '/^\/\* COLORS:START \*\//,/^\/\* COLORS:END \*\//d' "$swaync_style"
    # Prepend fresh colors
    local color_block
    color_block="/* COLORS:START */
@define-color accent     ${accent};
@define-color accent_dim alpha(${accent}, 0.15);
@define-color accent_mid alpha(${accent}, 0.55);
@define-color bg         alpha(${background}, 0.92);
@define-color fg         ${foreground};
/* COLORS:END */"
    echo "${color_block}" | cat - "$swaync_style" > /tmp/swaync-style-new.css && mv /tmp/swaync-style-new.css "$swaync_style"
  fi

  # Wofi style — sed replace accent colors in both stylesheets
  for wofi_style in "$HOME/.config/wofi/style.css" "$HOME/.config/wofi/style-launcher.css"; do
    [[ -f "$wofi_style" ]] || continue
    sed -i \
      -e "s|border: 1px solid #[0-9a-fA-F]\{6\}4D;|border: 1px solid #${c2}4D;|g" \
      -e "s|background-color: #[0-9a-fA-F]\{6\}26;|background-color: #${c2}26;|g" \
      -e "s|border: 1px solid #[0-9a-fA-F]\{6\}4D[^;]|border: 1px solid #${c2}4D|g" \
      "$wofi_style"
  done

  # Starship prompt — rewrite accent color
  local starship_conf="$HOME/.config/starship.toml"
  if [[ -f "$starship_conf" ]]; then
    sed -i \
      -e "s|style = \"bold #[0-9a-fA-F]*\"|style = \"bold ${accent}\"|g" \
      -e "s|style = \"#[0-9a-fA-F]*\"|style = \"${accent}\"|g" \
      "$starship_conf"
    # Keep error symbol red
    sed -i "s|error_symbol = \"\[❯\](bold ${accent})\"|error_symbol = \"[❯](bold #ff4c4c)\"|g" "$starship_conf"
  fi

  # Reload live processes — only if Hyprland is actually running
  if [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
    pkill -SIGUSR2 waybar 2>/dev/null
    hyprctl reload        2>/dev/null
    pkill -SIGUSR1 kitty  2>/dev/null
    sleep 0.3 && systemctl --user restart swaync 2>/dev/null &
  fi

  # Keep SDDM greeter background and colors in sync
  sudo cp "$wall" /usr/share/pixmaps/greeter-bg.jpg 2>/dev/null
  local sddm_theme="/usr/share/sddm/themes/sddm-astronaut-theme/Themes/william.conf"
  local dark_bg="#0d0d1a"
  sudo sed -i \
    -e "s|^Background=.*|Background=\"/usr/share/pixmaps/greeter-bg.jpg\"|" \
    -e "s|^HeaderTextColor=.*|HeaderTextColor=\"${accent}\"|" \
    -e "s|^TimeTextColor=.*|TimeTextColor=\"${accent}\"|" \
    -e "s|^UserIconColor=.*|UserIconColor=\"${accent}\"|" \
    -e "s|^PasswordIconColor=.*|PasswordIconColor=\"${accent}\"|" \
    -e "s|^LoginButtonBackgroundColor=.*|LoginButtonBackgroundColor=\"${accent}\"|" \
    -e "s|^SystemButtonsIconsColor=.*|SystemButtonsIconsColor=\"${accent}\"|" \
    -e "s|^SessionButtonTextColor=.*|SessionButtonTextColor=\"${accent}\"|" \
    -e "s|^DropdownSelectedBackgroundColor=.*|DropdownSelectedBackgroundColor=\"${accent}\"|" \
    -e "s|^HighlightBackgroundColor=.*|HighlightBackgroundColor=\"${accent}\"|" \
    "$sddm_theme" 2>/dev/null

  echo "[pywal] Colors updated from $(basename "$wall") — accent: ${accent}"
}

# ----------------------------------------------------------
# Rotate one or both monitors
# ----------------------------------------------------------
rotate() {
  # Bail out if Hyprland is not running
  if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
    echo "[wallpaper] Hyprland not running, skipping rotation"
    return 0
  fi
  if ! swww query &>/dev/null; then
    echo "[wallpaper] swww-daemon not running, skipping rotation"
    return 0
  fi

  local target="${1:-both}"

  case "$target" in
    dp-2|ultrawide)
      local wall_uw
      wall_uw=$(get_random "$DIR_ULTRAWIDE")
      set_monitor_wallpaper "$MONITOR_ULTRAWIDE" "$wall_uw"
      apply_pywal "$wall_uw"
      ;;
    dp-3|4k)
      local wall_4k
      wall_4k=$(get_random "$DIR_4K")
      set_monitor_wallpaper "$MONITOR_4K" "$wall_4k"
      ;;
    both|*)
      local wall_uw wall_4k
      wall_uw=$(get_random "$DIR_ULTRAWIDE")
      wall_4k=$(get_random "$DIR_4K")
      # Set both monitors — swww handles them independently
      set_monitor_wallpaper "$MONITOR_ULTRAWIDE" "$wall_uw"
      set_monitor_wallpaper "$MONITOR_4K"        "$wall_4k"
      # Pywal always driven by the primary OLED wallpaper
      apply_pywal "$wall_uw"
      ;;
  esac
}

# ----------------------------------------------------------
# Validate wallpaper directories
# ----------------------------------------------------------
check_dirs() {
  echo "Checking wallpaper directories..."
  for dir in "$DIR_ULTRAWIDE" "$DIR_4K"; do
    if [[ ! -d "$dir" ]]; then
      echo "  MISSING: $dir"
    else
      local count
      count=$(find "$dir" -maxdepth 1 -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
        | wc -l)
      echo "  OK: $dir ($count wallpaper(s))"
    fi
  done
}

# ----------------------------------------------------------
# Entry point
# ----------------------------------------------------------
case "$1" in
  next)
    rotate "${2:-both}"
    ;;
  set)
    # Set a specific wallpaper (used by wallpaper-picker.sh)
    # Usage: wallpaper-rotate.sh set /path/to/image.jpg
    wall="$2"
    if [[ -z "$wall" || ! -f "$wall" ]]; then
      echo "Usage: $(basename "$0") set /path/to/wallpaper"
      exit 1
    fi
    if ! swww query &>/dev/null; then
      echo "[wallpaper] swww-daemon not running"
      exit 1
    fi
    # Apply to both monitors
    set_monitor_wallpaper "$MONITOR_ULTRAWIDE" "$wall"
    set_monitor_wallpaper "$MONITOR_4K" "$wall"
    apply_pywal "$wall"
    ;;
  check)
    check_dirs
    ;;
  "")
    echo "Starting wallpaper rotation daemon (interval: ${INTERVAL}s)"
    check_dirs
    # Give swww daemon a moment if it just started
    swww query &>/dev/null || sleep 3
    rotate both
    while true; do
      sleep "$INTERVAL"
      rotate both
    done
    ;;
  *)
    echo "Usage: $(basename "$0") [next [dp-2|dp-3|both]] | [check]"
    exit 1
    ;;
esac
