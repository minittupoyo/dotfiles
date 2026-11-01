pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// 接続状態 (有線 / 無線 / なし)。NetworkManager 前提の Quickshell.Networking は使わず、
// sysfs の operstate を定期的に読む (この環境は systemd-networkd の有線)。
Singleton {
    id: root

    property bool connected: false
    property string kind: ""      // "wired" | "wireless" | ""
    property string iface: ""

    function _parse(text) {
        let found = null;
        for (const line of text.trim().split("\n")) {
            const [name, state, kind] = line.split(" ");
            if (!name || state !== "up")
                continue;
            // 仮想インタフェース (コンテナ・ブリッジ等) は除く
            if (/^(veth|docker|br-|virbr|tailscale|wg)/.test(name))
                continue;
            found = { name: name, kind: kind };
            break;
        }
        connected = found !== null;
        iface = found ? found.name : "";
        kind = found ? found.kind : "";
    }

    Process {
        id: proc
        command: ["sh", "-c", 'for d in /sys/class/net/*; do n=${d##*/}; [ "$n" = lo ] && continue; s=$(cat "$d/operstate" 2>/dev/null); k=wired; [ -d "$d/wireless" ] && k=wireless; echo "$n $s $k"; done']
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
