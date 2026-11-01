import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import "../../components"
import "../../services"
import "../../tokens"

// メディアの操作 (MPRIS)。再生中のプレーヤーを優先して表示する。プレーヤーが無ければ非表示。
Rectangle {
    id: root

    // テストで偽のプレーヤーを差し込むための上書き (通常は null)
    property var playerOverride: null

    readonly property var player: playerOverride || Media.player

    // カードの本体をクリックするとメディア画面を開く (下の再生ボタンは、それぞれが先に受ける)
    signal clicked()

    visible: player !== null
    implicitHeight: visible ? 88 : 0
    radius: Shapes.large
    color: Colors.m3SurfaceContainerHighest

    StateLayer {
        anchors.fill: parent
        radius: root.radius
        hovered: cardMouse.containsMouse
        pressed: cardMouse.pressed
    }
    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        // ジャケット (角丸でクリップ)
        Item {
            Layout.preferredWidth: 64
            Layout.preferredHeight: 64

            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: Shapes.medium
                visible: false
                layer.enabled: true
            }
            Rectangle {
                anchors.fill: parent
                radius: Shapes.medium
                color: Colors.m3SecondaryContainer
            }
            Icon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                name: "music_note"
                size: 28
                color: Colors.m3OnSecondaryContainer
            }
            Image {
                id: art
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                sourceSize.width: 128
                sourceSize.height: 128
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: artMask
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Label {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackTitle || root.player.identity) : ""
                role: Typography.titleSmall
                elide: Text.ElideRight
                maximumLineCount: 1
            }
            Label {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackArtist || root.player.identity) : ""
                role: Typography.bodySmall
                color: Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        IconButton {
            size: "s"
            variant: "standard"
            icon: "skip_previous"
            enabled: root.player !== null && root.player.canGoPrevious
            onClicked: root.player.previous()
        }
        IconButton {
            size: "s"
            variant: "filled"
            icon: root.player && root.player.isPlaying ? "pause" : "play_arrow"
            enabled: root.player !== null && root.player.canTogglePlaying
            onClicked: root.player.togglePlaying()
        }
        IconButton {
            size: "s"
            variant: "standard"
            icon: "skip_next"
            enabled: root.player !== null && root.player.canGoNext
            onClicked: root.player.next()
        }
    }
}
