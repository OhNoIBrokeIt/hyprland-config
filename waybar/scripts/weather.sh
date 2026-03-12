#!/usr/bin/env bash
# =========================================================
# Weather module for waybar
# Uses wttr.in — no API key needed
# Set your location below
# =========================================================

LOCATION="Miami"   # Change this to your city

DATA=$(curl -sf "https://wttr.in/${LOCATION}?format=j1" 2>/dev/null)

if [[ -z "$DATA" ]]; then
  echo '{"text":"󰖔  --","tooltip":"Weather unavailable","class":"offline"}'
  exit 0
fi

TEMP_C=$(echo "$DATA" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['current_condition'][0]['temp_C'])" 2>/dev/null)
FEELS=$(echo "$DATA"  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['current_condition'][0]['FeelsLikeC'])" 2>/dev/null)
DESC=$(echo "$DATA"   | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['current_condition'][0]['weatherDesc'][0]['value'])" 2>/dev/null)
HUMID=$(echo "$DATA"  | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['current_condition'][0]['humidity'])" 2>/dev/null)
WIND=$(echo "$DATA"   | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['current_condition'][0]['windspeedKmph'])" 2>/dev/null)

# Map condition to icon
get_icon() {
  local desc="$1"
  case "$desc" in
    *Sunny*|*Clear*)      echo "󰖙" ;;
    *Partly*cloud*)       echo "󰖕" ;;
    *Cloud*|*Overcast*)   echo "󰖔" ;;
    *Rain*|*Drizzle*)     echo "󰖗" ;;
    *Thunder*|*Storm*)    echo "󰖙" ;;
    *Snow*|*Blizzard*)    echo "󰖘" ;;
    *Mist*|*Fog*)         echo "󰖑" ;;
    *)                    echo "󰖐" ;;
  esac
}

ICON=$(get_icon "$DESC")
TEMP_F=$(( (TEMP_C * 9 / 5) + 32 ))
FEELS_F=$(( (FEELS * 9 / 5) + 32 ))

TEXT="${ICON}  ${TEMP_F}°F"
TOOLTIP="${DESC}\nFeels like: ${FEELS_F}°F\nHumidity: ${HUMID}%\nWind: ${WIND} km/h\nLocation: ${LOCATION}"

printf '{"text":"%s","tooltip":"%s","class":"weather"}\n' "$TEXT" "$TOOLTIP"
