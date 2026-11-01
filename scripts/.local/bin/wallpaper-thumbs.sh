#!/usr/bin/env bash
# 壁紙のサムネイルを生成する (何度実行しても結果は同じ。未生成・更新分だけ作る)。
# usage: wallpaper-thumbs.sh [SRC_DIR] [CACHE_DIR]
#   名前は <元ファイル名>.<mtime>.jpg。元が更新されると別名になり、古いものは掃除される。
#   ffmpeg で JPEG にするので、Qt 側は JPEG だけ読めればよい (WebP 等の原画像でも可)。
set -euo pipefail

src="${1:-$HOME/Pictures/Wallpapers}"
cache="${2:-${XDG_CACHE_HOME:-$HOME/.cache}/shell/wallpaper-thumbs}"
width="${THUMB_WIDTH:-640}"

mkdir -p "$cache"
shopt -s nullglob nocaseglob

declare -A keep
for f in "$src"/*.{png,jpg,jpeg,webp,gif,bmp,avif}; do
    [[ -f "$f" ]] || continue
    name="${f##*/}"
    mtime="$(stat -c %Y -- "$f")"
    out="$cache/$name.$mtime.jpg"
    keep["$out"]=1
    [[ -s "$out" ]] && continue

    tmp="$cache/.tmp.$$.jpg"   # 先頭が . なので下の掃除対象にならない
    if ffmpeg -nostdin -loglevel error -y -i "$f" -frames:v 1 \
        -vf "scale=$width:-2:flags=lanczos" -q:v 3 "$tmp"; then
        mv -f -- "$tmp" "$out"
    else
        rm -f -- "$tmp"
        echo "failed: $f" >&2
    fi
done

# 元が無くなった / 更新されたもののサムネイルを掃除
for t in "$cache"/*.jpg; do
    [[ -n "${keep[$t]:-}" ]] || rm -f -- "$t"
done
