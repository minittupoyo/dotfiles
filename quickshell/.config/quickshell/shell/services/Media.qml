pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// メディア (MPRIS) の共有状態。どのプレーヤーを表示するかを、クイック設定のカードとメディア画面で揃える。
// 既定は「再生中のものを優先、なければ先頭」。メディア画面で選んだものは、そのプレーヤーが居る間は優先する。
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property string selectedId: ""

    readonly property var player: {
        const list = players;
        return list.find(p => p.uniqueId === selectedId) || list.find(p => p.isPlaying) || list[0] || null;
    }

    function select(p) {
        selectedId = p ? p.uniqueId : "";
    }

    // 秒 → "m:ss" / "h:mm:ss"
    function formatTime(sec) {
        const s = Math.max(0, Math.floor(sec || 0));
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const ss = String(s % 60).padStart(2, "0");
        return h > 0 ? h + ":" + String(m).padStart(2, "0") + ":" + ss : m + ":" + ss;
    }
}
