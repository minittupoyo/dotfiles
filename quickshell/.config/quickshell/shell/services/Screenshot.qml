pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// スクリーンショットの設定 (保存するか・ディレイ) と、撮影の実行。設定は状態ファイルに保存して、次回も使う。
// 撮影は scripts の screenshot.sh に任せる (メニューが消えるのを待つ処理もスクリプト側)。
Singleton {
    id: root

    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell/screenshot.json"

    property bool saveToFile: true
    property int delay: 0              // 秒 (0 / 3 / 5)
    readonly property var delays: [0, 3, 5]

    function setSaveToFile(v) {
        saveToFile = v;
        _persist();
    }
    function setDelay(s) {
        delay = s;
        _persist();
    }

    // mode: "region" | "window" | "screen" | "all"
    function take(mode) {
        const cmd = [Quickshell.env("HOME") + "/.local/bin/screenshot.sh", mode];
        if (!saveToFile)
            cmd.push("--clipboard-only");
        if (delay > 0)
            cmd.push("--delay", String(delay));
        Quickshell.execDetached(cmd);
    }

    function _persist() {
        file.setText(JSON.stringify({ saveToFile: saveToFile, delay: delay }) + "\n");
    }

    FileView {
        id: file
        path: root.stateFile
        printErrors: false    // 初回は状態ファイルが無いのが正常
        onLoaded: {
            try {
                const j = JSON.parse(text());
                if (typeof j.saveToFile === "boolean")
                    root.saveToFile = j.saveToFile;
                if (root.delays.indexOf(j.delay) >= 0)
                    root.delay = j.delay;
            } catch (e) {
                console.warn("Screenshot: bad state file", e);
            }
        }
    }
}
