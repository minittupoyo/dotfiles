pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// 画面録画の開始・停止と、録画中かどうか。実体は scripts の record.sh (wf-recorder)。
// 録画中かは wf-recorder のプロセスの有無で見る (qs を再読み込みしても追従できる)。
Singleton {
    id: root

    property bool active: false

    // mode: "screen" | "region"
    function start(mode) {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/record.sh", "start", mode]);
        check.restart();
    }
    function stop() {
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/record.sh", "stop"]);
    }
    function toggle(mode) {
        active ? stop() : start(mode);
    }

    Process {
        id: probe
        command: ["pgrep", "-x", "wf-recorder"]
        onExited: code => root.active = code === 0
    }

    Timer {
        id: check
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!probe.running) probe.running = true
    }
}
