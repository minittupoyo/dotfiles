#!/usr/bin/env bash
# 壁紙適用 → matugen(expressive) → 各アプリへ反映
# usage: apply-wallpaper.sh <image> [dark|light]
set -euo pipefail

img="${1:?usage: apply-wallpaper.sh <image> [dark|light]}"
mode="${2:-dark}"
[[ -f "$img" ]] || { echo "not a file: $img" >&2; exit 1; }
img="$(realpath "$img")"

# 壁紙 (全モニター共通)。遷移は背景で走らせ、その間に配色を生成する。
awww img "$img" --transition-type grow --transition-duration 0.6 --transition-fps 144 &
awww_pid=$!

# --prefer は非対話実行で必須 (候補色が複数ある画像で停止するため)
matugen -t scheme-expressive -m "$mode" --prefer saturation -q image "$img"

# 現在の壁紙を記録 (壁紙セレクターが「現在」の印に使う)
state="${XDG_STATE_HOME:-$HOME/.local/state}/quickshell"
mkdir -p "$state"
printf '%s\n' "$img" > "$state/wallpaper"

# 反映 (起動していないものは黙って無視)
pkill -USR1 -x kitty 2>/dev/null || true                 # kitty: 設定再読込
[[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && hyprctl reload >/dev/null || true

wait "$awww_pid"
