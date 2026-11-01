pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// システムの状態 (CPU・メモリ・GPU・温度)。scripts の sysstats.sh を active の間だけ定期的に呼ぶ。
// CPU 使用率は /proc/stat の累積値の差から出す (最初の 1 回は差が取れないので 0)。
Singleton {
    id: root

    // 取得するか (ダッシュボードが開いている間だけ true にする)
    property bool active: false
    readonly property int interval: 1500

    property real cpuUsage: 0          // 0〜1
    property real cpuTemp: 0           // ℃
    property real memTotal: 0          // GiB
    property real memUsed: 0           // GiB
    readonly property real memFraction: memTotal > 0 ? memUsed / memTotal : 0
    property bool hasGpu: false
    property real gpuUsage: 0          // 0〜1
    property real gpuTemp: 0
    property real vramTotal: 0         // GiB
    property real vramUsed: 0
    readonly property real vramFraction: vramTotal > 0 ? vramUsed / vramTotal : 0
    property real gpuPower: 0          // W
    property real gpuPowerLimit: 0
    property real nvmeTemp: 0          // 最も熱いドライブ

    property var _prev: null           // 前回の [total, idle]

    function _parse(text) {
        let nvme = 0;
        for (const line of text.trim().split("\n")) {
            const i = line.indexOf("=");
            if (i < 0)
                continue;
            const k = line.slice(0, i);
            const v = line.slice(i + 1);
            switch (k) {
            case "cpu": {
                const n = v.split(" ").map(Number);
                const idle = n[3] + (n[4] || 0);
                const total = n.reduce((a, b) => a + b, 0);
                if (_prev && total > _prev[0])
                    cpuUsage = Math.max(0, Math.min(1, 1 - (idle - _prev[1]) / (total - _prev[0])));
                _prev = [total, idle];
                break;
            }
            case "cpu_temp": cpuTemp = parseFloat(v); break;
            case "mem_total_kb": memTotal = parseFloat(v) / 1048576; break;
            case "mem_avail_kb": memUsed = memTotal - parseFloat(v) / 1048576; break;
            case "nvme": nvme = Math.max(nvme, parseFloat(v)); break;
            case "gpu": {
                const g = v.split(",").map(parseFloat);
                if (g.length >= 6 && !g.some(isNaN)) {
                    hasGpu = true;
                    gpuUsage = g[0] / 100;
                    gpuTemp = g[1];
                    vramUsed = g[2] / 1024;
                    vramTotal = g[3] / 1024;
                    gpuPower = g[4];
                    gpuPowerLimit = g[5];
                }
                break;
            }
            }
        }
        nvmeTemp = nvme;
    }

    Process {
        id: proc
        command: [Quickshell.env("HOME") + "/.local/bin/sysstats.sh"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(text)
        }
    }

    Timer {
        interval: root.interval
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!proc.running) proc.running = true
    }

    // 閉じたら、次に開いたときに古い差分を使わない
    onActiveChanged: if (!active) _prev = null
}
