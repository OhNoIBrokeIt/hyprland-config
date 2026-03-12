# hyprland-config

Personal Hyprland desktop configuration for a dual-monitor OLED + 4K setup on CachyOS (Arch-based).

## Hardware

| Component | Detail |
|-----------|--------|
| GPU | NVIDIA RTX 4090 |
| CPU | Intel Core i9-14900K |
| Primary | 49" Microstep MPG491CX OLED — 5120x1440 @ 240Hz (DP-2) |
| Secondary | 32" 32M2V — 3840x2160 @ 144Hz (DP-3, scale 1.25) |
| Compositor | Hyprland 0.54+ |

## Features

- **Per-monitor wallpapers** — ultrawide and 4K rotate independently via `swww`
- **Pywal color theming** — accent colors extracted from OLED wallpaper, propagated to waybar, hyprland borders, kitty, swaync, wofi, and hyprlock automatically
- **HDR + VRR** on both monitors via Hyprland's native color management
- **10-bit color** (XBGR2101010) on both outputs
- **Wofi-based menus** — app launcher, audio switcher, wifi switcher, keybind cheatsheet, wallpaper picker, emoji picker
- **Waybar** with weather, GPU temp, CPU temp, audio, wifi, notifications, clock
- **Swaync** notification center with pywal-matched colors
- **Hyprlock** screen locker with pywal accent
- **SDDM** with sddm-astronaut-theme, synced to current wallpaper and accent color

## Stack

| Role | Tool |
|------|------|
| Compositor | Hyprland |
| Bar | Waybar |
| Launcher / Menus | Wofi |
| Wallpaper | swww |
| Color theming | pywal |
| Notifications | Swaync |
| Locker | Hyprlock |
| Idle | Hypridle |
| Terminal | Kitty |
| File manager | Thunar / yazi |
| Greeter | SDDM + sddm-astronaut-theme |
| GTK theme | Catppuccin Mocha Blue |
| Icon theme | Papirus-Dark |
| Font | JetBrainsMono Nerd Font |

## Fresh Install

```bash
git clone https://github.com/ohnoibrokeit/hyprland-config
cd hyprland-config
bash install.sh
```

`install.sh` will:
1. Install all required packages via pacman + AUR helper (paru or yay)
2. Install pywal via pip
3. Back up your existing configs
4. Deploy all config files
5. Enable systemd user services
6. Apply GTK theme settings

## After Install

1. **Add wallpapers:**
   ```
   ~/Pictures/Wallpapers/ultrawide/   ← 5120x1440 images for OLED
   ~/Pictures/Wallpapers/4k/          ← 3840x2160 images for 4K monitor
   ```

2. **Set weather location** in `~/.config/waybar/scripts/weather.sh`:
   ```bash
   LOCATION="Miami"
   ```

3. **Adjust monitor config** if your outputs differ from DP-2/DP-3 — edit `~/.config/hypr/hyprland.conf`:
   ```
   monitor = DP-2, 5120x1440@240, auto, 1, ...
   monitor = DP-3, 3840x2160@144, auto-left, 1.25, ...
   ```

4. **First wallpaper + colors:**
   ```bash
   ~/.config/hypr/scripts/wallpaper-rotate.sh next
   ```

## Keybinds

| Bind | Action |
|------|--------|
| SUPER+T | Terminal (kitty) |
| SUPER+E | Thunar |
| SUPER+SHIFT+E | yazi |
| SUPER+R | App launcher |
| SUPER+TAB | Window switcher |
| SUPER+SHIFT+R | File browser |
| SUPER+. | Emoji picker |
| SUPER+C | Clipboard history |
| SUPER+B | Browser |
| SUPER+Q | Kill window |
| SUPER+V | Toggle float |
| SUPER+F | Fullscreen (maximize) |
| SUPER+SHIFT+F | True fullscreen |
| SUPER+O | Lock screen |
| SUPER+N | Toggle notifications |
| SUPER+SHIFT+N | Do not disturb |
| SUPER+W | Toggle waybar |
| SUPER+SHIFT+W | Next wallpaper |
| SUPER+SHIFT+P | Wallpaper picker |
| SUPER+/ | Keybind cheatsheet |
| SUPER+S | Scratchpad toggle |
| Print | Screenshot → clipboard |
| SHIFT+Print | Screenshot → annotate |
| CTRL+Print | Full screen → clipboard |
| ALT+Print | Full screen → save file |
| SUPER+SHIFT+CTRL+M | Exit Hyprland |

## Directory Structure

```
.
├── install.sh                        # fresh install script
├── deploy.sh                         # redeploy configs only (no packages)
├── hypr/
│   ├── hyprland.conf
│   ├── hypridle.conf
│   ├── hyprlock.conf
│   └── scripts/
│       ├── wallpaper-rotate.sh       # per-monitor rotation + pywal
│       ├── wallpaper-picker.sh       # wofi wallpaper selector
│       ├── audio-menu.sh             # wofi sink switcher
│       ├── wifi-menu.sh              # wofi network switcher
│       ├── keybind-cheatsheet.sh     # wofi keybind display
│       └── emoji-picker.sh           # wofi emoji picker
├── waybar/
│   ├── config.jsonc
│   ├── style.css
│   └── scripts/
│       └── weather.sh
├── kitty/
│   └── kitty.conf
├── swaync/
│   ├── config.json
│   └── style.css
├── wofi/
│   ├── style.css                     # dropdown menus
│   └── style-launcher.css            # app launcher / pickers
├── gtk/
│   ├── settings.ini
│   ├── gtk4-settings.ini
│   └── apply-gtk.sh
├── systemd/
│   ├── waybar.service
│   └── waybar-resume.service
└── greetd/
    └── setup-sddm.sh
```

## Notes

- pywal colors are always driven by the **OLED (ultrawide) wallpaper**, never the 4K monitor
- Wofi dropdown menus (audio, wifi, keybinds) anchor to the **top-right** of the screen below waybar
- swaync is managed via systemd user service — use `systemctl --user restart swaync` not `pkill`
- Rofi is not used — wofi handles everything
