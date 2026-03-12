#!/usr/bin/env bash
# WiFi menu — wofi nmcli network switcher

STYLE="$HOME/.config/wofi/style.css"
WOFI_ARGS=(--dmenu --style "$STYLE" --prompt "  WiFi" --width 420 --height 380 --hide-scroll --no-actions --insensitive --location 3 --xoffset -20 --yoffset 46)

ACTIVE=$(nmcli -t -f NAME,TYPE connection show --active | grep wifi | cut -d: -f1 | head -1)

entries=()
if [[ -n "$ACTIVE" ]]; then
  entries+=("󰖩  $ACTIVE  ✓")
  entries+=("󰖪  Disconnect")
else
  entries+=("󰖪  Not connected")
fi
entries+=("─────────────────────")
entries+=("  Scan for networks...")
entries+=("─────────────────────")

while IFS= read -r name; do
  [[ "$name" == "$ACTIVE" ]] && continue
  entries+=("  $name")
done < <(nmcli -t -f NAME,TYPE connection show | grep wifi | cut -d: -f1 | sort)

choice=$(printf '%s\n' "${entries[@]}" | wofi "${WOFI_ARGS[@]}")
[[ -z "$choice" ]] && exit 0

case "$choice" in
  *"Disconnect"*)
    nmcli connection down "$ACTIVE"
    notify-send "WiFi" "Disconnected" --icon=network-wireless-offline -t 2000
    ;;
  *"Scan"*)
    notify-send "WiFi" "Scanning..." --icon=network-wireless -t 1500
    nmcli device wifi rescan 2>/dev/null; sleep 1
    available=$(nmcli -f SSID,SIGNAL device wifi list | tail -n +2 | \
      awk 'NF && $1!="--" {printf "  %-35s %s%%\n", $1, $2}' | sort -t'%' -rn)
    scan_choice=$(echo "$available" | wofi --dmenu --style "$STYLE" \
      --prompt "  Networks" --width 480 --height 420 --hide-scroll --no-actions \
      --location 3 --xoffset -20 --yoffset 46)
    [[ -z "$scan_choice" ]] && exit 0
    ssid=$(echo "$scan_choice" | awk '{print $2}')
    if nmcli connection show "$ssid" &>/dev/null; then
      nmcli connection up "$ssid"
    else
      pass=$(wofi --dmenu --style "$STYLE" --prompt "  Password for $ssid" --width 420 --height 80 --password)
      [[ -z "$pass" ]] && exit 0
      nmcli device wifi connect "$ssid" password "$pass"
    fi
    notify-send "WiFi" "Connected to $ssid" --icon=network-wireless -t 2000
    ;;
  *"─"*) ;;
  *"Not connected"*) ;;
  *)
    name=$(echo "$choice" | sed 's/^[[:space:]]*[^ ]* //' | sed 's/  ✓$//')
    nmcli connection up "$name" && \
      notify-send "WiFi" "Connected to $name" --icon=network-wireless -t 2000
    ;;
esac
