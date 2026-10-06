#!/bin/sh
umask 077
export FONTCONFIG_FILE="$(dirname "$0")/fonts.conf"
export MATERIAL_SHELL_INDEPENDENT=1
"$HOME/.local/bin/material-wallpaper-backend" || exit 1
"$HOME/.local/bin/material-stats" --once || exit 1
systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE || exit 1
systemctl --user daemon-reload || exit 1
systemctl --user start material-shell-services.service material-shell-stats.service material-shell-palette.service || exit 1
exec quickshell -c material-shell --no-duplicate --daemonize
