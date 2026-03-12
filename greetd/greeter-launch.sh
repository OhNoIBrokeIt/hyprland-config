#!/bin/bash

# Kill any leftover mpv instances
pkill -x mpv 2>/dev/null
sleep 0.3

# Video wallpaper — plays on DP-2 (ultrawide) fullscreen, looping
VIDEO="/home/ohnoibrokeit/Downloads/Wallpapers/heartbroken-aemeath-wuthering-waves-moewalls-com.mp4"

mpv \
  --fullscreen \
  --loop \
  --no-audio \
  --vo=gpu \
  --gpu-api=vulkan \
  --no-osc \
  --no-input-default-bindings \
  --screen=0 \
  --input-ipc-server=/tmp/mpv-greeter.sock \
  "$VIDEO" &

MPV_PID=$!
sleep 1.5

# Launch tuigreet centered on ultrawide
tuigreet \
  --cmd start-hyprland \
  --time \
  --remember \
  --remember-session \
  --asterisks \
  --greet-align center \
  --width 80 \
  --theme "border=cyan;text=white;prompt=cyan;time=white;action=white;button=cyan;container=black;input=white"

# On logout/login kill mpv
kill $MPV_PID 2>/dev/null
pkill -x mpv 2>/dev/null
