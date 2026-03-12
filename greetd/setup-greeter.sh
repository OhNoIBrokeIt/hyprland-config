#!/bin/bash
# Run this as root to set up greetd + nwg-hello

# Copy configs
cp /etc/greetd/config.toml /etc/greetd/config.toml.bak 2>/dev/null
cp "$(dirname "$0")/config.toml"          /etc/greetd/config.toml
cp "$(dirname "$0")/hyprland-greeter.conf" /etc/greetd/hyprland-greeter.conf
cp "$(dirname "$0")/nwg-hello.json"       /etc/nwg-hello/config.json 2>/dev/null || \
  mkdir -p /etc/nwg-hello && cp "$(dirname "$0")/nwg-hello.json" /etc/nwg-hello/config.json

# greeter user needs to run Hyprland
usermod -aG video,input greeter 2>/dev/null

# Use last swww wallpaper as greeter background if available
LAST_WALL=$(ls ~/Pictures/Wallpapers/ultrawide/*.{jpg,jpeg,png,webp} 2>/dev/null | shuf -n1)
if [[ -n "$LAST_WALL" ]]; then
  cp "$LAST_WALL" /usr/share/pixmaps/greeter-bg.jpg
  sed -i "s|/usr/share/pixmaps/greeter-bg.jpg|/usr/share/pixmaps/greeter-bg.jpg|g" /etc/greetd/hyprland-greeter.conf
else
  # Create a solid dark fallback
  convert -size 5120x1440 xc:#0d0d14 /usr/share/pixmaps/greeter-bg.jpg 2>/dev/null || \
  touch /usr/share/pixmaps/greeter-bg.jpg
fi

systemctl restart greetd
echo "Done — greetd restarted with nwg-hello"
