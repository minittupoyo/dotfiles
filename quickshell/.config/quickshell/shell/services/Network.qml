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

    // ---- 詳細 (ネットワークのタブが開いている間だけ 2 秒ごとに更新) ----
    property bool detailsActive: false
    // [{ name, up, kind, virtual, mac, speed (Mbps, -1 = 不明), ip, gateway, rxRate, txRate (bytes/s), rxTotal, txTotal }]
    property var links: []
    property var _prev: ({})    // 前回の { name: { rx, tx, t } } (速度の計算用)

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

    function _parseDetails(text) {
        const now = Date.now();
        const prev = _prev;
        const next = {};
        const gw = {};
        const out = [];
        for (const line of text.trim().split("\n")) {
            const f = line.split("|");
            if (f[0] === "gw") {
                gw[f[1]] = f[2];
                continue;
            }
            const [name, state, kind, mac, speed, rx, tx, ip] = f;
            if (!name)
                continue;
            const rxN = Number(rx) || 0;
            const txN = Number(tx) || 0;
            const p = prev[name];
            let rxRate = 0;
            let txRate = 0;
            if (p && now > p.t) {
                const dt = (now - p.t) / 1000;
                rxRate = Math.max(0, (rxN - p.rx) / dt);
                txRate = Math.max(0, (txN - p.tx) / dt);
            }
            next[name] = { rx: rxN, tx: txN, t: now };
            out.push({
                name: name,
                up: state === "up" || state === "unknown",
                kind: kind,
                virtual: /^(veth|docker|br-|virbr|tailscale|wg)/.test(name),
                mac: mac,
                speed: speed ? Number(speed) : -1,
                ip: ip || "",
                gateway: "",
                rxRate: rxRate,
                txRate: txRate,
                rxTotal: rxN,
                txTotal: txN
            });
        }
        for (const l of out)
            l.gateway = gw[l.name] || "";
        _prev = next;
        links = out;
    }

    Process {
        id: detailProc
        command: ["sh", "-c", 'for d in /sys/class/net/*; do n=${d##*/}; [ "$n" = lo ] && continue; s=$(cat "$d/operstate" 2>/dev/null); k=wired; [ -d "$d/wireless" ] && k=wireless; m=$(cat "$d/address" 2>/dev/null); sp=$(cat "$d/speed" 2>/dev/null); [ "${sp:-0}" -lt 0 ] 2>/dev/null && sp=; rx=$(cat "$d/statistics/rx_bytes" 2>/dev/null); tx=$(cat "$d/statistics/tx_bytes" 2>/dev/null); a=$(ip -o -4 addr show dev "$n" 2>/dev/null | awk \'{print $4; exit}\'); echo "$n|$s|$k|$m|$sp|$rx|$tx|$a"; done; ip -4 route show default 2>/dev/null | awk \'{for(i=1;i<NF;i++) if($i=="via") g=$(i+1); for(i=1;i<NF;i++) if($i=="dev") print "gw|" $(i+1) "|" g}\'']
        stdout: StdioCollector {
            onStreamFinished: root._parseDetails(text)
        }
    }

    Timer {
        interval: 2000
        running: root.detailsActive
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!detailProc.running) detailProc.running = true
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
