#!/bin/sh
umask 077
export FONTCONFIG_FILE="$(dirname "$0")/fonts.conf"
export MATERIAL_SHELL_INDEPENDENT=1
python3 "$(dirname "$0")/wallpaper_backend.py" || exit 1
exec quickshell -c material-shell --no-duplicate --daemonize
