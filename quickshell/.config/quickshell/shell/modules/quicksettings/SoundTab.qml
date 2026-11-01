import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"
import "../../tokens"

// 「サウンド」タブ: 出力・入力デバイスの切り替えと音量、アプリごとの音量。
Item {
    id: root

    implicitHeight: col.implicitHeight

    component Section: Label {
        Layout.topMargin: 4
        role: Typography.titleSmall
        color: Colors.m3Primary
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 8

        // ---- 出力 ----
        Section { text: "出力" }
        Repeater {
            model: ScriptModel {
                values: Audio.sinks
            }
            ChoiceRow {
                required property var modelData    // PwNode
                Layout.fillWidth: true
                icon: "speaker"
                text: Audio.sinkLabel(modelData)
                checked: Audio.sink !== null && modelData.id === Audio.sink.id
                onClicked: Audio.setDefaultSink(modelData)
            }
        }
        VolumeRow {
            Layout.fillWidth: true
            icon: Audio.volumeIcon(Audio.volume, Audio.muted)
            value: Audio.volume
            muted: Audio.muted
            onMoved: v => Audio.setVolume(v)
            onMuteToggled: Audio.toggleMute()
        }

        // ---- 入力 ----
        Section { text: "入力"; Layout.topMargin: 12 }
        Repeater {
            model: ScriptModel {
                values: Audio.sources
            }
            ChoiceRow {
                required property var modelData    // PwNode
                Layout.fillWidth: true
                icon: "mic"
                text: Audio.sinkLabel(modelData)
                checked: Audio.source !== null && modelData.id === Audio.source.id
                onClicked: Audio.setDefaultSource(modelData)
            }
        }
        VolumeRow {
            Layout.fillWidth: true
            visible: Audio.sourceReady
            icon: Audio.sourceMuted ? "mic_off" : "mic"
            value: Audio.sourceVolume
            muted: Audio.sourceMuted
            onMoved: v => Audio.setSourceVolume(v)
            onMuteToggled: Audio.toggleSourceMute()
        }

        // ---- アプリごとの音量 ----
        Section { text: "アプリ"; Layout.topMargin: 12 }
        Repeater {
            model: ScriptModel {
                values: Audio.streams
            }
            ColumnLayout {
                id: app
                required property var modelData    // PwNode (ストリーム)
                Layout.fillWidth: true
                spacing: 0
                Label {
                    Layout.leftMargin: 12
                    text: Audio.streamLabel(app.modelData)
                    role: Typography.labelLarge
                    color: Colors.m3OnSurface
                }
                VolumeRow {
                    Layout.fillWidth: true
                    icon: app.modelData.audio.muted ? "volume_off" : "volume_up"
                    value: app.modelData.audio.volume
                    muted: app.modelData.audio.muted
                    onMoved: v => app.modelData.audio.volume = Math.max(0, Math.min(1, v))
                    onMuteToggled: app.modelData.audio.muted = !app.modelData.audio.muted
                }
            }
        }
        Label {
            visible: Audio.streams.length === 0
            Layout.leftMargin: 12
            text: "音を出しているアプリはありません"
            role: Typography.bodyMedium
            color: Colors.m3OnSurfaceVariant
        }
    }
}
