pragma Singleton

import QtQuick
import Quickshell
import "."

// OSD (音量・マイクのミュート) を出す合図。Audio の値の変化を見て出すので、
// キー・クイック設定・バーのホイールなど、どこで変えても同じ OSD が出る。
// 起動時・出力デバイスの切り替え時の値の変化は、出さない。
Singleton {
    id: root

    property bool shown: false
    property string kind: "volume"    // "volume" | "mic"

    // 出してよい状況か (ロック中・クイック設定が開いている間は出さない)
    readonly property bool allowed: !Lock.locked && !UiState.quickSettingsOpen

    property bool _quiet: true

    property string _pending: ""

    // 変化の合図。デバイスの切り替えでは、値の変化がデバイスの変化より先に届くことがあるので、
    // 少し待ってから (その間に _mute されなければ) 出す
    function show(k) {
        if (_quiet || !allowed)
            return;
        _pending = k;
        deferTimer.restart();
    }

    // 以降しばらくは変化を無視する (起動直後・デバイスの切り替え)
    function _mute() {
        _quiet = true;
        quietTimer.restart();
    }

    Timer {
        id: deferTimer
        interval: 80
        onTriggered: {
            if (root._quiet || !root.allowed)
                return;
            root.kind = root._pending;
            root.shown = true;
            hideTimer.restart();
        }
    }
    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shown = false
    }
    Timer {
        id: quietTimer
        interval: 800
        onTriggered: root._quiet = false
    }
    Component.onCompleted: quietTimer.start()

    Connections {
        target: Audio
        function onSinkChanged() { root._mute(); }
        function onSourceChanged() { root._mute(); }
        function onVolumeChanged() { root.show("volume"); }
        function onMutedChanged() { root.show("volume"); }
        function onSourceMutedChanged() { root.show("mic"); }
    }
}
