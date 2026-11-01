import QtQuick
import QtQuick.Layouts
import "../tokens"

// ミュートボタン + スライダー + 数字の 1 行。値は 0〜1。
//   VolumeRow { icon: "volume_up"; value: node.audio.volume; muted: node.audio.muted
//               onMoved: v => node.audio.volume = v; onMuteToggled: node.audio.muted = !node.audio.muted }
RowLayout {
    id: root

    property string icon: "volume_up"
    property real value: 0
    property bool muted: false

    signal moved(real value)
    signal muteToggled()

    spacing: 8

    IconButton {
        size: "s"
        variant: "standard"
        icon: root.icon
        onClicked: root.muteToggled()
    }
    Slider {
        Layout.fillWidth: true
        value: root.value
        onMoved: v => root.moved(v)
    }
    Label {
        Layout.preferredWidth: 40
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100) + "%"
        role: Typography.labelLarge
        color: root.muted ? Colors.m3Outline : Colors.m3OnSurfaceVariant
    }
}
