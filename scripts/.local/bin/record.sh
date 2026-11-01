#!/bin/sh
# 画面録画 (wf-recorder)。quickshell のクイック設定から呼ばれる。単独でも使える。
#   record.sh start <screen|region>   screen: フォーカス中のモニター / region: slurp で範囲を選ぶ
#   record.sh stop                    録画を止める (SIGINT。ファイルが正しく閉じられる)
# 保存先は ${XDG_VIDEOS_DIR:-~/Videos}/Recordings。終わったら通知を出す。範囲選択をキャンセルしたら何もしない。

notify() {
    gdbus call --session --dest org.freedesktop.Notifications --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify "recording" 0 "" "$1" "$2" '[]' '{}' 5000 >/dev/null 2>&1
}

case "${1:-}" in
    stop)
        pkill -INT -x wf-recorder
        exit 0
        ;;
    start) ;;
    *)
        echo "usage: record.sh <start <screen|region>|stop>" >&2
        exit 2
        ;;
esac

pgrep -x wf-recorder >/dev/null && exit 0    # すでに録画中

mode=${2:-screen}
dir=${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings
mkdir -p "$dir" || exit 1
file="$dir/recording_$(date +%Y%m%d_%H%M%S).mp4"

# クイック設定が消えるのを待つ (写り込まないように)
sleep 0.35

case "$mode" in
    region)
        geometry=$(slurp -d) || exit 0
        sleep 0.15
        set -- -g "$geometry"
        ;;
    screen)
        output=$(python3 -c 'import json,sys
for m in json.loads(sys.argv[1]):
    if m.get("focused"): print(m["name"])' "$(hyprctl -j monitors)")
        set -- -o "$output"
        ;;
    *)
        exit 2
        ;;
esac

notify "録画を始めました" "止めるにはクイック設定のタイルを押します"
if wf-recorder "$@" -f "$file" >/dev/null 2>&1 || [ -s "$file" ]; then
    notify "録画を保存しました" "$(basename "$file")"
else
    rm -f "$file"
    notify "録画に失敗しました" "wf-recorder がエラーを返しました"
    exit 1
fi
echo "$file"
