#!/usr/bin/env bash
# Audio menu — wofi sink switcher + volume control

STYLE="$HOME/.config/wofi/style.css"
WOFI_ARGS=(--dmenu --style "$STYLE" --prompt "  Audio" --width 420 --height 340 --hide-scroll --no-actions --insensitive --location 3 --xoffset -20 --yoffset 46)

get_sinks() {
  pactl list sinks | awk '
    /^Sink #/ { id=substr($2,2) }
    /^\s+Name:/ { name=$2 }
    /device.description/ {
      gsub(/"/, "", $0)
      desc=substr($0, index($0,"=")+1)
      gsub(/^ +| +$/, "", desc)
      print id "|" name "|" desc
    }
  '
}

DEFAULT=$(pactl get-default-sink)
VOLUME=$(pactl get-sink-volume @DEFAULT_AUDIO_SINK@ | grep -oP '\d+%' | head -1)
MUTE=$(pactl get-sink-mute @DEFAULT_AUDIO_SINK@ | grep -c "yes")

entries=()
if [[ "$MUTE" -eq 1 ]]; then
  entries+=("󰝟  Muted — click to unmute")
else
  entries+=("  Volume: $VOLUME")
fi
entries+=("  Volume +5%")
entries+=("  Volume -5%")
entries+=("─────────────────────")

while IFS='|' read -r id name desc; do
  if [[ "$name" == "$DEFAULT" ]]; then
    entries+=("  $desc  ✓")
  else
    entries+=("  $desc")
  fi
done < <(get_sinks)

choice=$(printf '%s\n' "${entries[@]}" | wofi "${WOFI_ARGS[@]}")
[[ -z "$choice" ]] && exit 0

case "$choice" in
  *"Volume +5%"*)  pactl set-sink-volume @DEFAULT_AUDIO_SINK@ +5% ;;
  *"Volume -5%"*)  pactl set-sink-volume @DEFAULT_AUDIO_SINK@ -5% ;;
  *"Muted"*)       pactl set-sink-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  *"Volume:"*)     ;;
  *"─"*)           ;;
  *)
    desc_chosen=$(echo "$choice" | sed 's/^[[:space:]]*[^ ]* //' | sed 's/  ✓$//')
    while IFS='|' read -r id name desc; do
      if [[ "$desc" == "$desc_chosen" ]]; then
        pactl set-default-sink "$name"
        notify-send "Audio" "Output: $desc" --icon=audio-speakers -t 2000
        break
      fi
    done < <(get_sinks)
    ;;
esac
