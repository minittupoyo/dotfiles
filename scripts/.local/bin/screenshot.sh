#!/bin/sh
# スクリーンショットを撮る (quickshell の screenshot メニューから呼ばれる。単独でも使える)。
#   screenshot.sh <region|window|screen|all> [--clipboard-only] [--delay 秒]
#     region : slurp で範囲を選ぶ
#     window : slurp でウィンドウを選ぶ (いま見えているウィンドウだけが候補)
#     screen : フォーカス中のモニター全体
#     all    : すべてのモニター
# 保存先は ${XDG_PICTURES_DIR:-~/Pictures}/Screenshots。撮れたらクリップボードに入れ、通知を出す。
# 範囲・ウィンドウの選択をキャンセルしたら、何もせずに終わる。

mode=${1:-screen}
[ $# -gt 0 ] && shift
save=1
delay=0
while [ $# -gt 0 ]; do
    case "$1" in
        --clipboard-only) save=0 ;;
        --delay) delay=${2:-0}; shift ;;
    esac
    shift
done

dir=${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots
if [ "$save" = 1 ]; then
    mkdir -p "$dir" || exit 1
    file="$dir/screenshot_$(date +%Y%m%d_%H%M%S).png"
else
    file="${XDG_RUNTIME_DIR:-/tmp}/screenshot-last.png"
fi

notify() {
    # $1 = 見出し、$2 = 本文、$3 = 画像 (サムネイル)。有効期限は ms (負の値は gdbus がオプションと解釈するので使わない)
    gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify "screenshot" 0 "${3:-}" "$1" "$2" '[]' '{}' 5000 >/dev/null 2>&1
}

# メニューが閉じて、画面から消えるのを待つ (メニュー自身が写り込まないように)
sleep 0.35

geometry=""
output=""
case "$mode" in
    region)
        geometry=$(slurp -d) || exit 0
        ;;
    window)
        rects=$(python3 - "$(hyprctl -j monitors)" "$(hyprctl -j clients)" <<'PY'
import json, sys
monitors = json.loads(sys.argv[1])
clients = json.loads(sys.argv[2])
active = {m["activeWorkspace"]["id"] for m in monitors}
for c in clients:
    if c.get("mapped") and not c.get("hidden") and c["workspace"]["id"] in active:
        x, y = c["at"]
        w, h = c["size"]
        print(f"{x},{y} {w}x{h}")
PY
)
        [ -n "$rects" ] || exit 0
        geometry=$(printf '%s\n' "$rects" | slurp -r -d) || exit 0
        ;;
    screen)
        output=$(python3 -c 'import json,sys
for m in json.loads(sys.argv[1]):
    if m.get("focused"): print(m["name"])' "$(hyprctl -j monitors)")
        ;;
    all) ;;
    *)
        echo "usage: screenshot.sh <region|window|screen|all> [--clipboard-only] [--delay 秒]" >&2
        exit 2
        ;;
esac

# 選択の枠 (slurp) が消えるのを待ってから、ディレイを置く
[ -n "$geometry" ] && sleep 0.15
[ "$delay" -gt 0 ] 2>/dev/null && sleep "$delay"

if [ -n "$geometry" ]; then
    grim -g "$geometry" "$file" || { notify "スクリーンショットに失敗しました" "grim がエラーを返しました"; exit 1; }
elif [ -n "$output" ]; then
    grim -o "$output" "$file" || { notify "スクリーンショットに失敗しました" "grim がエラーを返しました"; exit 1; }
else
    grim "$file" || { notify "スクリーンショットに失敗しました" "grim がエラーを返しました"; exit 1; }
fi

wl-copy --type image/png < "$file"

if [ "$save" = 1 ]; then
    notify "スクリーンショットを撮りました" "$(basename "$file") (クリップボードにもコピー)" "$file"
else
    notify "スクリーンショットを撮りました" "クリップボードにコピー" "$file"
fi
echo "$file"
