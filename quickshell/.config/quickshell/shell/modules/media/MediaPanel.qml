import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../../components"
import "../../services"
import "../../tokens"

// メディア画面の中身: ジャケット + 曲情報 + シーク + 操作 (シャッフル・前・再生・次・ループ) + システム音量。
// 操作: Space で再生/一時停止、← → で 5 秒シーク、Esc で閉じる。
Item {
    id: root

    // テストで偽のプレーヤーを差し込むための上書き (通常は null)
    property var playerOverride: null
    readonly property var player: playerOverride || Media.player

    signal closeRequested()

    implicitHeight: 336

    function open() {
        keys.forceActiveFocus();
    }

    // 再生位置は自動では更新されないので、再生中は定期的に読み直させる
    Timer {
        interval: 500
        repeat: true
        running: root.player !== null && root.player.isPlaying && root.visible
        onTriggered: root.player.positionChanged()
    }

    // シークは、ドラッグ中に送りすぎないよう間引く
    property real _seekTo: -1
    Timer {
        id: seekTimer
        interval: 100
        onTriggered: {
            if (root._seekTo >= 0 && root.player && root.player.canSeek)
                root.player.position = root._seekTo;
            root._seekTo = -1;
        }
    }
    function seekFraction(f) {
        if (!player || !player.canSeek || player.length <= 0)
            return;
        _seekTo = Math.max(0, Math.min(1, f)) * player.length;
        if (!seekTimer.running)
            seekTimer.start();
    }
    function seekBy(sec) {
        if (player && player.canSeek)
            player.position = Math.max(0, Math.min(player.length > 0 ? player.length : 1e9, player.position + sec));
    }

    function nextLoop() {
        if (!player || !player.loopSupported)
            return;
        const s = player.loopState;
        player.loopState = s === MprisLoopState.None ? MprisLoopState.Playlist
                         : s === MprisLoopState.Playlist ? MprisLoopState.Track
                         : MprisLoopState.None;
    }

    // ---- キー操作 ----
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closeRequested()
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space && root.player && root.player.canTogglePlaying) {
                root.player.togglePlaying();
            } else if (event.key === Qt.Key_Left) {
                root.seekBy(-5);
            } else if (event.key === Qt.Key_Right) {
                root.seekBy(5);
            } else {
                return;
            }
            event.accepted = true;
        }
    }

    // ---- プレーヤーが無いとき ----
    ColumnLayout {
        anchors.centerIn: parent
        visible: root.player === null
        spacing: 12
        Icon {
            Layout.alignment: Qt.AlignHCenter
            name: "music_off"
            size: 48
            color: Colors.m3OnSurfaceVariant
        }
        Label {
            text: "再生中のメディアはありません"
            role: Typography.titleMedium
            color: Colors.m3OnSurfaceVariant
        }
    }

    RowLayout {
        anchors.fill: parent
        visible: root.player !== null
        spacing: 32

        // ---- ジャケット (再生中は角が大きく、一時停止では小さくなる) ----
        Item {
            Layout.preferredWidth: 320
            Layout.preferredHeight: 320
            Layout.alignment: Qt.AlignVCenter

            SpringValue {
                id: artRadius
                target: root.player && root.player.isPlaying ? Shapes.extraLargeIncreased : Shapes.large
                spec: Motion.spatialDefault
                epsilon: 0.05
            }

            Rectangle {
                id: artMask
                anchors.fill: parent
                radius: Math.max(0, artRadius.value)
                visible: false
                layer.enabled: true
            }
            Rectangle {
                anchors.fill: parent
                radius: Math.max(0, artRadius.value)
                color: Colors.m3SecondaryContainer
            }
            Icon {
                anchors.centerIn: parent
                visible: art.status !== Image.Ready
                name: "music_note"
                size: 96
                color: Colors.m3OnSecondaryContainer
            }
            Image {
                id: art
                anchors.fill: parent
                source: root.player ? root.player.trackArtUrl : ""
                sourceSize.width: 640
                sourceSize.height: 640
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

        // ---- 右側: 情報と操作 ----
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // プレーヤーが複数あるときだけ、切り替えのチップを出す
            Row {
                visible: Media.players.length > 1
                Layout.bottomMargin: 8
                spacing: 8
                Repeater {
                    model: Media.players
                    Button {
                        required property var modelData
                        size: "s"
                        variant: "tonal"
                        text: modelData.identity
                        checkable: true
                        autoToggle: false
                        checked: modelData === root.player
                        onClicked: Media.select(modelData)
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                text: root.player ? (root.player.trackTitle || root.player.identity) : ""
                role: Typography.headlineSmall
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
            }
            Label {
                Layout.fillWidth: true
                text: root.player ? root.player.trackArtist : ""
                visible: text !== ""
                role: Typography.titleMedium
                color: Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
                maximumLineCount: 1
            }
            Label {
                Layout.fillWidth: true
                text: root.player ? root.player.trackAlbum : ""
                visible: text !== ""
                role: Typography.bodyMedium
                color: Colors.m3OnSurfaceVariant
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Item { Layout.fillHeight: true }

            // ---- シーク ----
            Slider {
                Layout.fillWidth: true
                enabled: root.player !== null && root.player.canSeek && root.player.length > 0
                value: root.player && root.player.length > 0 ? root.player.position / root.player.length : 0
                onMoved: v => root.seekFraction(v)
            }
            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: Media.formatTime(root.player ? root.player.position : 0)
                    role: Typography.labelMedium
                    color: Colors.m3OnSurfaceVariant
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: root.player && root.player.length > 0 ? Media.formatTime(root.player.length) : ""
                    role: Typography.labelMedium
                    color: Colors.m3OnSurfaceVariant
                }
            }

            // ---- 操作 ----
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 4
                spacing: 8

                IconButton {
                    size: "s"
                    variant: "standard"
                    icon: "shuffle"
                    checkable: true
                    autoToggle: false
                    checked: root.player !== null && root.player.shuffleSupported && root.player.shuffle
                    enabled: root.player !== null && root.player.shuffleSupported
                    onClicked: root.player.shuffle = !root.player.shuffle
                }
                IconButton {
                    size: "m"
                    variant: "tonal"
                    icon: "skip_previous"
                    enabled: root.player !== null && root.player.canGoPrevious
                    onClicked: root.player.previous()
                }
                IconButton {
                    size: "m"
                    variant: "filled"
                    icon: root.player && root.player.isPlaying ? "pause" : "play_arrow"
                    enabled: root.player !== null && root.player.canTogglePlaying
                    onClicked: root.player.togglePlaying()
                }
                IconButton {
                    size: "m"
                    variant: "tonal"
                    icon: "skip_next"
                    enabled: root.player !== null && root.player.canGoNext
                    onClicked: root.player.next()
                }
                IconButton {
                    size: "s"
                    variant: "standard"
                    icon: root.player && root.player.loopState === MprisLoopState.Track ? "repeat_one" : "repeat"
                    checkable: true
                    autoToggle: false
                    checked: root.player !== null && root.player.loopSupported && root.player.loopState !== MprisLoopState.None
                    enabled: root.player !== null && root.player.loopSupported
                    onClicked: root.nextLoop()
                }
            }

            // ---- システム音量 ----
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 8
                IconButton {
                    size: "s"
                    variant: "standard"
                    icon: Audio.volumeIcon(Audio.volume, Audio.muted)
                    onClicked: Audio.toggleMute()
                }
                Slider {
                    Layout.fillWidth: true
                    value: Audio.muted ? 0 : Audio.volume
                    onMoved: v => Audio.setVolume(v)
                }
                Label {
                    Layout.preferredWidth: 40
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Audio.volume * 100) + "%"
                    role: Typography.labelLarge
                    color: Audio.muted ? Colors.m3Outline : Colors.m3OnSurfaceVariant
                }
            }
        }
    }
}
