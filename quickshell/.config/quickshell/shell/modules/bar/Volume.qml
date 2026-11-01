import QtQuick
import QtQuick.Layouts
import "../../components"
import "../../services"
import "../../tokens"

// 既定出力の音量。クリックでミュート切替、スクロールで ±5%。
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: 40

    readonly property string iconName: Audio.muted ? "volume_off"
        : Audio.volume <= 0 ? "volume_mute"
        : Audio.volume < 0.5 ? "volume_down" : "volume_up"

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 0

        IconButton {
            size: "s"
            variant: "standard"
            icon: root.iconName
            onClicked: Audio.toggleMute()
        }
        Label {
            text: Math.round(Audio.volume * 100) + "%"
            role: Typography.labelLarge
            color: Audio.muted ? Colors.m3Outline : Colors.m3OnSurfaceVariant
            Layout.minimumWidth: 36
            Layout.rightMargin: 8
        }
    }

    WheelHandler {
        onWheel: e => Audio.changeVolume(e.angleDelta.y > 0 ? 0.05 : -0.05)
    }
}
