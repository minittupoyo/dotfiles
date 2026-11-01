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

    // 入力 (マイク)
    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool sourceReady: source !== null && source.audio !== null
    readonly property real sourceVolume: sourceReady ? source.audio.volume : 0
    readonly property bool sourceMuted: sourceReady ? source.audio.muted : false

    // 出力デバイス一覧 (ハードウェアのシンクのみ。アプリのストリームは除く)
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)

    function sinkLabel(node) {
        return node ? (node.nickname || node.description || node.name) : "";
    }

    function volumeIcon(vol, muted) {
        return muted ? "volume_off" : vol <= 0 ? "volume_mute" : vol < 0.5 ? "volume_down" : "volume_up";
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

    function setSourceVolume(v) {
        if (sourceReady)
            source.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleSourceMute() {
        if (sourceReady)
            source.audio.muted = !source.audio.muted;
    }

    // ノードの音量・ミュートを読むには追跡対象にする必要がある
    PwObjectTracker {
        objects: {
            const o = [];
            if (root.sink) o.push(root.sink);
            if (root.source) o.push(root.source);
            return o;
        }
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
