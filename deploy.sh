#!/usr/bin/env bash
# =========================================================
# deploy.sh — redeploy config files only (no package install)
# Use install.sh for a fresh system setup.
# =========================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Deploying Hyprland config suite ==="

BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"
echo "Backing up existing configs to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
for dir in hypr waybar kitty swaync wofi; do
  [[ -d "$HOME/.config/$dir" ]] && cp -r "$HOME/.config/$dir" "$BACKUP_DIR/" && echo "  Backed up: $dir"
done

mkdir -p ~/.config/hypr/scripts ~/.config/waybar/scripts ~/.config/kitty
mkdir -p ~/.config/swaync ~/.config/wofi ~/.config/systemd/user
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
mkdir -p ~/Pictures/Wallpapers/ultrawide ~/Pictures/Wallpapers/4k ~/Pictures/Screenshots

cp "$SCRIPT_DIR/hypr/hyprland.conf"  ~/.config/hypr/hyprland.conf
cp "$SCRIPT_DIR/hypr/hypridle.conf"  ~/.config/hypr/hypridle.conf
cp "$SCRIPT_DIR/hypr/hyprlock.conf"  ~/.config/hypr/hyprlock.conf

cp "$SCRIPT_DIR/hypr/scripts/wallpaper-rotate.sh"   ~/.config/hypr/scripts/
cp "$SCRIPT_DIR/hypr/scripts/audio-menu.sh"         ~/.config/hypr/scripts/
cp "$SCRIPT_DIR/hypr/scripts/wifi-menu.sh"          ~/.config/hypr/scripts/
cp "$SCRIPT_DIR/hypr/scripts/keybind-cheatsheet.sh" ~/.config/hypr/scripts/
cp "$SCRIPT_DIR/hypr/scripts/wallpaper-picker.sh"   ~/.config/hypr/scripts/
cp "$SCRIPT_DIR/hypr/scripts/emoji-picker.sh"       ~/.config/hypr/scripts/
chmod +x ~/.config/hypr/scripts/*.sh

cp "$SCRIPT_DIR/waybar/config.jsonc"       ~/.config/waybar/config.jsonc
cp "$SCRIPT_DIR/waybar/style.css"          ~/.config/waybar/style.css
cp "$SCRIPT_DIR/waybar/scripts/weather.sh" ~/.config/waybar/scripts/weather.sh
chmod +x ~/.config/waybar/scripts/weather.sh

cp "$SCRIPT_DIR/kitty/kitty.conf"         ~/.config/kitty/kitty.conf
cp "$SCRIPT_DIR/swaync/style.css"         ~/.config/swaync/style.css
cp "$SCRIPT_DIR/swaync/config.json"       ~/.config/swaync/config.json
cp "$SCRIPT_DIR/wofi/style.css"           ~/.config/wofi/style.css
cp "$SCRIPT_DIR/wofi/style-launcher.css"  ~/.config/wofi/style-launcher.css
cp "$SCRIPT_DIR/gtk/settings.ini"         ~/.config/gtk-3.0/settings.ini
cp "$SCRIPT_DIR/gtk/gtk4-settings.ini"    ~/.config/gtk-4.0/settings.ini
bash "$SCRIPT_DIR/gtk/apply-gtk.sh"
cp "$SCRIPT_DIR/systemd/waybar.service"        ~/.config/systemd/user/waybar.service
cp "$SCRIPT_DIR/systemd/waybar-resume.service" ~/.config/systemd/user/waybar-resume.service

touch ~/.config/kitty/colors-wal.conf
touch ~/.config/swaync/colors-wal.css

if ! grep -q "@define-color accent" ~/.config/waybar/colors-waybar.css 2>/dev/null; then
  cat > ~/.config/waybar/colors-waybar.css << 'EOF'
/* Fallback colors — replaced by pywal on first wallpaper change */
@define-color accent       #00f5ff;
@define-color accent_alpha alpha(#00f5ff, 0.80);
@define-color accent_dim   alpha(#00f5ff, 0.12);
@define-color accent_glow  alpha(#00f5ff, 0.25);
@define-color bg           #06060c;
@define-color fg           #d0d0d8;
@define-color color1       #ff3c6f;
@define-color color3       #f7c948;
@define-color color4       #00b4d8;
EOF
fi

systemctl --user daemon-reload
systemctl --user enable --now waybar.service
systemctl --user enable waybar-resume.service

echo ""
echo "=== Done! Run: hyprctl reload ==="
