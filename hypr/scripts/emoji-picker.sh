#!/usr/bin/env bash
# Emoji picker — wofi dmenu, types selected emoji via wtype

STYLE="$HOME/.config/wofi/style-launcher.css"

# Use a unicode emoji list — wofi dmenu with search
choice=$(cat /usr/share/unicode/emoji-sequences.txt 2>/dev/null \
  || python3 -c "
import unicodedata
emojis = []
for cp in range(0x1F300, 0x1FAFF):
    try:
        name = unicodedata.name(chr(cp))
        emojis.append(f'{chr(cp)}  {name.lower()}')
    except ValueError:
        pass
print('\n'.join(emojis))
" | wofi --dmenu \
    --style "$STYLE" \
    --width 500 \
    --height 500 \
    --prompt "  Emoji" \
    --insensitive \
    --hide-scroll)

[[ -z "$choice" ]] && exit 0

# Extract just the emoji character
emoji=$(echo "$choice" | awk '{print $1}')
wtype "$emoji"
