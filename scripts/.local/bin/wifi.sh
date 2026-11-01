#!/bin/sh
# iwd (iwctl) の薄いラッパー。quickshell のクイック設定 (WiFi) から呼ばれる。単独でも使える。
#   wifi.sh status                       状態を機械可読で出す (下記)
#   wifi.sh scan                         スキャンを始める
#   wifi.sh power <on|off>               WiFi アダプターの電源
#   wifi.sh connect <SSID> [パスフレーズ]  接続 (保存済みならパスフレーズ不要)
#   wifi.sh disconnect
#   wifi.sh forget <SSID>                保存済みネットワークを削除
# status の出力:
#   dev|<デバイス名>|<on|off>|<状態>|<接続中の SSID>|<scanning: yes|no>
#   net|<SSID>|<セキュリティ>|<電波 0-4>|<接続中 1|0>|<保存済み 1|0>
# 失敗したら、iwctl のメッセージを stderr に出して非 0 で終わる。

strip() { sed 's/\x1b\[[0-9;]*[A-Za-z]//g'; }

dev=$(iwctl device list | strip | awk 'NR>4 && $1!="" {print $1; exit}')
[ -n "$dev" ] || { echo "WiFi デバイスが見つかりません" >&2; exit 1; }

case "${1:-}" in
    status)
        powered=$(iwctl device list | strip | awk -v d="$dev" '$1==d {print $3}')
        info=$(iwctl station "$dev" show 2>/dev/null | strip)
        known=$(iwctl known-networks list 2>/dev/null | strip)
        nets=$(iwctl station "$dev" get-networks 2>/dev/null | strip)
        python3 - "$dev" "${powered:-off}" "$info" "$known" "$nets" <<'PY'
import sys
dev, powered, info, known, nets = sys.argv[1:6]
state = scanning = ssid = ""
for l in info.splitlines():
    k, v = l[:34].strip(), l[34:].strip()
    if k == "State": state = v
    elif k == "Scanning": scanning = v
    elif k == "Connected network": ssid = v
print(f"dev|{dev}|{powered}|{state}|{ssid}|{scanning or 'no'}")
saved = {l[2:36].strip() for l in known.splitlines()[4:] if l.strip()}
for l in nets.splitlines()[4:]:
    if not l.strip():
        continue
    name, sec, sig = l[6:40].strip(), l[40:60].strip(), l[60:].strip()
    if not name:
        continue
    print(f"net|{name}|{sec}|{sig.count('*')}|{1 if '>' in l[:6] else 0}|{1 if name in saved else 0}")
PY
        ;;
    scan) iwctl station "$dev" scan ;;
    power) iwctl device "$dev" set-property Powered "${2:-on}" ;;
    connect)
        if [ -n "${3:-}" ]; then
            iwctl --passphrase "$3" station "$dev" connect "$2"
        else
            iwctl station "$dev" connect "$2"
        fi
        ;;
    disconnect) iwctl station "$dev" disconnect ;;
    forget) iwctl known-networks "$2" forget ;;
    *)
        echo "usage: wifi.sh <status|scan|power on|off|connect SSID [pass]|disconnect|forget SSID>" >&2
        exit 2
        ;;
esac
