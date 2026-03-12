#!/bin/bash
# Run with sudo

# Set theme
mkdir -p /etc/sddm.conf.d
cat > /etc/sddm.conf.d/theme.conf << CONF
[Theme]
Current=sddm-astronaut-theme
CONF

# Copy our custom theme config
cp "$(dirname "$0")/sddm-astronaut.conf" \
  /usr/share/sddm/themes/sddm-astronaut-theme/Themes/william.conf

# Set it as the active theme config
sed -i 's|^Background=.*|Background="Backgrounds/hyprland_kath.mp4"|' \
  /usr/share/sddm/themes/sddm-astronaut-theme/Themes/william.conf

# Point theme to our config
cat >> /etc/sddm.conf.d/theme.conf << CONF

[General]
ThemeConfig=/usr/share/sddm/themes/sddm-astronaut-theme/Themes/william.conf
CONF

# Copy current wallpaper as SDDM background
WALL=$(ls ~/Pictures/Wallpapers/ultrawide/*.{jpg,jpeg,png,webp} 2>/dev/null | shuf -n1)
if [[ -n "$WALL" ]]; then
    cp "$WALL" /usr/share/pixmaps/greeter-bg.jpg
    # Update theme conf to use it
    sed -i 's|^Background=.*|Background="/usr/share/pixmaps/greeter-bg.jpg"|' \
        /usr/share/sddm/themes/sddm-astronaut-theme/Themes/william.conf
fi

echo "Done — restart SDDM to apply: sudo systemctl restart sddm"
