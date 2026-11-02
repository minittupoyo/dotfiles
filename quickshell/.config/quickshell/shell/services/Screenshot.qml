pragma Singleton

import QtQuick
import Quickshell

// スクリーンショットの設定 (保存するか・ディレイ。実体は Settings) と、撮影の実行。
// 撮影は scripts の screenshot.sh に任せる (メニューが消えるのを待つ処理もスクリプト側)。
Singleton {
    id: root

    // 設定は Settings (settings.json) が持つ。ここは読み書きの窓口
    readonly property bool saveToFile: Settings.screenshotSave
    readonly property int delay: Settings.screenshotDelay    // 秒 (0 / 3 / 5)
    readonly property var delays: [0, 3, 5]

    function setSaveToFile(v) {
        Settings.set("screenshotSave", v);
    }
    function setDelay(s) {
        Settings.set("screenshotDelay", s);
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
}
