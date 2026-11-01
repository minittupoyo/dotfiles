pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// 既定の出力 (シンク) の音量とミュート。PipeWire の既定シンクに追従する。
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property real volume: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false

    // ノードの音量・ミュートを読むには追跡対象にする必要がある
    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    function setVolume(v) {
        if (ready)
            sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function changeVolume(delta) {
        setVolume(volume + delta);
    }

    function toggleMute() {
        if (ready)
            sink.audio.muted = !sink.audio.muted;
    }
}
