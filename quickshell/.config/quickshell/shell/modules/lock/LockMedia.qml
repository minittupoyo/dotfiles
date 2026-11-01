import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../components"
import "../../services"
import "../../tokens"

// ロック画面のメディアカード (MPRIS)。曲名・アーティスト・進行バー (表示のみ) と、前 / 再生 / 次。
// プレーヤーが無い、または停止中 (再生も一時停止もしていない) なら非表示。
// ロック中でも操作できるのは再生制御だけ (パスワードが要る操作は無い)。
Surface {
    id: root

    // テストで偽のプレーヤーを差し込むための上書き (通常は null)
    property var playerOverride: null

    readonly property var player: playerOverride || Media.player
    // 停止中のプレーヤー (曲を持たない) は出さない
    readonly property bool active: player !== null && player.playbackState !== MprisPlaybackState.Stopped

    visible: active
    implicitWidth: 360
    implicitHeight: active ? col.implicitHeight + 32 : 0
    level: 2
    radius: Shapes.extraLarge

    // 再生位置は自動では更新されないので、再生中は定期的に読み直させる
    Timer {
        interval: 500
        repeat: true
        running: root.active && root.player.isPlaying
        onTriggered: root.player.positionChanged()
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            AlbumArt {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                source: root.player ? root.player.trackArtUrl : ""
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
        }

        // 進行バー (表示のみ。誤操作を避けるためシークはさせない)
        RowLayout {
            Layout.fillWidth: true
            visible: root.active && root.player.length > 0
            spacing: 8

            Label {
                text: Media.formatTime(root.player ? root.player.position : 0)
                role: Typography.labelSmall
                color: Colors.m3OnSurfaceVariant
            }
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 4
                radius: Shapes.full
                color: Colors.m3SurfaceContainerHighest

                Rectangle {
                    height: parent.height
                    radius: Shapes.full
                    color: Colors.m3Primary
                    width: root.active && root.player.length > 0
                        ? parent.width * Math.max(0, Math.min(1, root.player.position / root.player.length))
                        : 0
                }
            }
            Label {
                text: root.active ? Media.formatTime(root.player.length) : ""
                role: Typography.labelSmall
                color: Colors.m3OnSurfaceVariant
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8

            IconButton {
                size: "s"
                variant: "standard"
                icon: "skip_previous"
                enabled: root.active && root.player.canGoPrevious
                onClicked: root.player.previous()
            }
            IconButton {
                size: "s"
                variant: "filled"
                icon: root.active && root.player.isPlaying ? "pause" : "play_arrow"
                enabled: root.active && root.player.canTogglePlaying
                onClicked: root.player.togglePlaying()
            }
            IconButton {
                size: "s"
                variant: "standard"
                icon: "skip_next"
                enabled: root.active && root.player.canGoNext
                onClicked: root.player.next()
            }
        }
    }
}
