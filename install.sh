#!/usr/bin/env bash
# =========================================================
# install.sh — fresh system install for ohnoibrokeit's
#              Hyprland config (CachyOS / Arch-based)
#
# Run once on a new install:
#   bash install.sh
#
# What it does:
#   1. Installs all required packages via pacman + paru
#   2. Installs pywal via pip
#   3. Deploys all config files to correct locations
#   4. Enables systemd user services
#   5. Applies GTK theme settings
# =========================================================

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- Colors for output -----------------------------------
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info()  { echo -e "${GREEN}[install]${NC} $*"; }
warn()  { echo -e "${YELLOW}[warn]${NC}   $*"; }
error() { echo -e "${RED}[error]${NC}  $*"; }

# =========================================================
# 1. PACKAGES
# =========================================================
info "Installing packages via pacman..."

PACMAN_PKGS=(
  # Hyprland ecosystem
  hyprland hyprlock hypridle hyprpaper
  xdg-desktop-portal-hyprland
  xdg-desktop-portal-gtk

  # Wayland essentials
  waybar
  swww                      # wallpaper daemon
  swaync                    # notification center
  wofi                      # launcher / menus
  wl-clipboard              # wl-copy / wl-paste
  cliphist                  # clipboard manager
  wtype                     # keyboard input for emoji picker
  grim slurp swappy         # screenshots

  # Terminal & shell
  kitty
  zsh

  # Fonts
  ttf-jetbrains-mono-nerd
  noto-fonts noto-fonts-emoji

  # Theming
  catppuccin-gtk-theme-mocha
  papirus-icon-theme
  qt6ct kvantum

  # System tray / applets
  network-manager-applet
  kdeconnect
  polkit-gnome

  # Audio
  pipewire pipewire-alsa pipewire-pulse wireplumber
  pavucontrol

  # Utilities
  thunar                    # file manager
  yazi                      # terminal file manager
  brightnessctl
  playerctl
  nm-connection-editor
  imagemagick               # optional: wallpaper picker thumbnails
)

sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" || warn "Some pacman packages failed — check output above"

# AUR packages (requires paru or yay)
if command -v paru &>/dev/null; then
  AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
  AUR_HELPER="yay"
else
  warn "No AUR helper found (paru/yay) — skipping AUR packages"
  AUR_HELPER=""
fi

if [[ -n "$AUR_HELPER" ]]; then
  info "Installing AUR packages via $AUR_HELPER..."
  AUR_PKGS=(
    hyprshot                  # screenshot helper
    sddm-astronaut-theme      # greeter theme
  )
  $AUR_HELPER -S --needed --noconfirm "${AUR_PKGS[@]}" || warn "Some AUR packages failed"
fi

# =========================================================
# 2. PYWAL
# =========================================================
info "Installing pywal..."
pip install pywal --break-system-packages || warn "pywal install failed — try manually: pip install pywal --break-system-packages"

# =========================================================
# 3. BACKUP EXISTING CONFIGS
# =========================================================
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d_%H%M%S)"
info "Backing up existing configs to $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
for dir in hypr waybar kitty swaync wofi; do
  [[ -d "$HOME/.config/$dir" ]] && cp -r "$HOME/.config/$dir" "$BACKUP_DIR/" && info "  Backed up: $dir"
done

# =========================================================
# 4. CREATE DIRECTORIES
# =========================================================
info "Creating config directories..."
mkdir -p ~/.config/hypr/scripts
mkdir -p ~/.config/waybar/scripts
mkdir -p ~/.config/kitty
mkdir -p ~/.config/swaync
mkdir -p ~/.config/wofi
mkdir -p ~/.config/systemd/user
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0
mkdir -p ~/Pictures/Wallpapers/ultrawide
mkdir -p ~/Pictures/Wallpapers/4k
mkdir -p ~/Pictures/Screenshots

# =========================================================
# 5. DEPLOY CONFIG FILES
# =========================================================
info "Deploying Hyprland configs..."
cp "$SCRIPT_DIR/hypr/hyprland.conf"   ~/.config/hypr/hyprland.conf
cp "$SCRIPT_DIR/hypr/hypridle.conf"   ~/.config/hypr/hypridle.conf
cp "$SCRIPT_DIR/hypr/hyprlock.conf"   ~/.config/hypr/hyprlock.conf

info "Deploying scripts..."
cp "$SCRIPT_DIR/hypr/scripts/wallpaper-rotate.sh"    ~/.config/hypr/scripts/wallpaper-rotate.sh
cp "$SCRIPT_DIR/hypr/scripts/audio-menu.sh"          ~/.config/hypr/scripts/audio-menu.sh
cp "$SCRIPT_DIR/hypr/scripts/wifi-menu.sh"           ~/.config/hypr/scripts/wifi-menu.sh
cp "$SCRIPT_DIR/hypr/scripts/keybind-cheatsheet.sh"  ~/.config/hypr/scripts/keybind-cheatsheet.sh
cp "$SCRIPT_DIR/hypr/scripts/wallpaper-picker.sh"    ~/.config/hypr/scripts/wallpaper-picker.sh
cp "$SCRIPT_DIR/hypr/scripts/emoji-picker.sh"        ~/.config/hypr/scripts/emoji-picker.sh
chmod +x ~/.config/hypr/scripts/*.sh

info "Deploying Waybar..."
cp "$SCRIPT_DIR/waybar/config.jsonc"        ~/.config/waybar/config.jsonc
cp "$SCRIPT_DIR/waybar/style.css"           ~/.config/waybar/style.css
cp "$SCRIPT_DIR/waybar/scripts/weather.sh"  ~/.config/waybar/scripts/weather.sh
chmod +x ~/.config/waybar/scripts/weather.sh

info "Deploying Kitty..."
cp "$SCRIPT_DIR/kitty/kitty.conf"  ~/.config/kitty/kitty.conf

info "Deploying Swaync..."
cp "$SCRIPT_DIR/swaync/style.css"    ~/.config/swaync/style.css
cp "$SCRIPT_DIR/swaync/config.json"  ~/.config/swaync/config.json

info "Deploying Wofi..."
cp "$SCRIPT_DIR/wofi/style.css"           ~/.config/wofi/style.css
cp "$SCRIPT_DIR/wofi/style-launcher.css"  ~/.config/wofi/style-launcher.css

info "Deploying GTK settings..."
cp "$SCRIPT_DIR/gtk/settings.ini"      ~/.config/gtk-3.0/settings.ini
cp "$SCRIPT_DIR/gtk/gtk4-settings.ini" ~/.config/gtk-4.0/settings.ini
bash "$SCRIPT_DIR/gtk/apply-gtk.sh"

info "Deploying systemd user services..."
cp "$SCRIPT_DIR/systemd/waybar.service"        ~/.config/systemd/user/waybar.service
cp "$SCRIPT_DIR/systemd/waybar-resume.service" ~/.config/systemd/user/waybar-resume.service

# =========================================================
# 6. PYWAL FALLBACK FILES
# =========================================================
info "Creating pywal fallback color files..."
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

if ! grep -q "wal_accent" ~/.config/wal/colors-hyprland.conf 2>/dev/null; then
  mkdir -p ~/.config/wal
  cat > ~/.config/wal/colors-hyprland.conf << 'EOF'
# Fallback — replaced by pywal on first wallpaper change
$wal_accent   = rgba(00f5ffee)
$wal_accent2  = rgba(00b4d8aa)
$wal_inactive = rgba(1a1a2a55)

general {
    col.active_border   = $wal_accent $wal_accent2 45deg
    col.inactive_border = $wal_inactive
}
EOF
fi

# =========================================================
# 7. SYSTEMD SERVICES
# =========================================================
info "Enabling systemd user services..."
systemctl --user daemon-reload
systemctl --user enable --now waybar.service
systemctl --user enable waybar-resume.service

# =========================================================
# 8. SDDM GREETER (optional)
# =========================================================
if [[ -d /usr/share/sddm/themes/sddm-astronaut-theme ]]; then
  info "Setting up SDDM greeter..."
  bash "$SCRIPT_DIR/greetd/setup-sddm.sh" || warn "SDDM setup failed — run manually"
else
  warn "sddm-astronaut-theme not found — skipping greeter setup"
fi

# =========================================================
# DONE
# =========================================================
echo ""
info "=== Install complete! ==="
echo ""
echo "  Next steps:"
echo ""
echo "  1. Add wallpapers:"
echo "       ~/Pictures/Wallpapers/ultrawide/   (5120x1440 — OLED primary)"
echo "       ~/Pictures/Wallpapers/4k/           (3840x2160 — secondary)"
echo ""
echo "  2. Set your city in ~/.config/waybar/scripts/weather.sh"
echo "       LOCATION=\"your city\""
echo ""
echo "  3. NOTE: hyprland.conf has monitor settings hardcoded for:"
echo "       DP-2 — 5120x1440@240 OLED (primary)"
echo "       DP-3 — 3840x2160@144 4K   (secondary, scale 1.25)"
echo "     Edit ~/.config/hypr/hyprland.conf if your setup differs."
echo ""
echo "  4. Log out and start Hyprland, then run:"
echo "       ~/.config/hypr/scripts/wallpaper-rotate.sh next"
echo "     to trigger first pywal color generation."
echo ""
