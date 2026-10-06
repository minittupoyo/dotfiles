import QtQuick
import QtQuick.Layouts

Item {
    id: page
    property var service: null
    property bool active: false
    property real position: 0
    readonly property var player: service?.player ?? null
    implicitHeight: 480
    function refresh() { position = player?.positionSupported ? Math.max(0, player.position) : 0; }
    function time(seconds) { const s = Math.max(0, Math.floor(seconds || 0)); return Math.floor(s / 60) + ":" + (s % 60).toString().padStart(2, "0"); }
    onActiveChanged: if (active) refresh()
    Connections { target: page.player; function onPositionChanged() { page.refresh(); } function onPostTrackChanged() { page.refresh(); } }
    Timer { interval: Theme.mediaPositionInterval; repeat: true; running: page.active && !!page.player; onTriggered: page.refresh() }
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space16
        Rectangle {
            visible: !!page.player
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Theme.mediaArtworkSize
            Layout.preferredHeight: Theme.mediaArtworkSize
            radius: Theme.shapeMedium
            color: Theme.inputBackground
            clip: true
            Image { id: artwork; anchors.fill: parent; source: page.player?.trackArtUrl ?? ""; asynchronous: true; sourceSize.width: Theme.mediaArtworkSize; sourceSize.height: Theme.mediaArtworkSize; fillMode: Image.PreserveAspectFit }
            MaterialIcon { anchors.centerIn: parent; name: "music_note"; visible: artwork.status !== Image.Ready }
        }
        Item {
            objectName: "mediaEmptyState"
            visible: !page.player
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumHeight: Theme.space32 * 4
            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width, Theme.mediaEmptyContentWidth)
                spacing: Theme.space12
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: Theme.mediaEmptyContainerSize
                    height: width
                    radius: width / 2
                    color: Theme.secondaryContainer
                    MaterialIcon { anchors.centerIn: parent; name: "music_note"; size: Theme.mediaEmptySymbolSize; color: Theme.secondaryContainerText }
                }
                Text {
                    objectName: "mediaEmptyTitle"
                    Layout.fillWidth: true
                    text: "再生中のメディアはありません"
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.titleMediumSize
                    font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
                Text {
                    objectName: "mediaEmptyDescription"
                    Layout.fillWidth: true
                    text: "音楽や動画を再生すると、曲名や操作ボタンがここに表示されます。"
                    color: Theme.surfaceVariantText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodySize
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                }
            }
        }
        Text { visible: !!page.player; Layout.fillWidth: true; text: page.player?.trackTitle || "タイトルなし"; textFormat: Text.PlainText; wrapMode: Text.Wrap; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.titleSize; font.weight: Font.DemiBold }
        Text { visible: !!page.player; Layout.fillWidth: true; text: [page.player?.trackArtist, page.player?.trackAlbum].filter(Boolean).join(" · ") || page.player?.identity || ""; textFormat: Text.PlainText; wrapMode: Text.Wrap; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        Rectangle {
            visible: !!page.player
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: transport.implicitWidth + Theme.space8 * 2
            implicitHeight: Theme.buttonHeight + Theme.space8 * 2
            radius: height / 2
            color: Theme.inputBackground
            RowLayout {
                id: transport
                anchors.centerIn: parent
                spacing: Theme.space4
                ShellButton { objectName: "mediaPrevious"; icon: "skip_previous"; Accessible.name: "前の曲"; enabled: page.player?.canGoPrevious ?? false; onClicked: page.player.previous() }
                ShellButton { objectName: "mediaPlay"; Layout.preferredWidth: Theme.mediaActionWidth; icon: page.player?.isPlaying ? "pause" : "play_arrow"; Accessible.name: page.player?.isPlaying ? "一時停止" : "再生"; emphasized: true; enabled: page.player?.canTogglePlaying ?? false; onClicked: page.player.togglePlaying() }
                ShellButton { objectName: "mediaNext"; icon: "skip_next"; Accessible.name: "次の曲"; enabled: page.player?.canGoNext ?? false; onClicked: page.player.next() }
            }
        }
        ExpressiveProgress {
            objectName: "mediaProgress"
            visible: !!page.player && !!page.player.lengthSupported && !!page.player.positionSupported
            Layout.fillWidth: true
            animationEnabled: page.active && (page.player?.isPlaying ?? false)
            value: page.player?.length > 0 ? page.position / page.player.length : 0
            interactive: !!page.player && !!page.player.canSeek && !!page.player.positionSupported && !!page.player.lengthSupported && page.player.length > 0
            onAdjusted: fraction => {
                if (!page.player || !page.player.canSeek || !page.player.positionSupported || !page.player.lengthSupported) return;
                const target = Math.max(0, Math.min(page.player.length, fraction * page.player.length));
                page.player.position = target;
                page.refresh();
            }
            Accessible.name: "再生位置"
        }
        RowLayout {
            visible: !!page.player && !!page.player.positionSupported
            Layout.fillWidth: true
            Text { text: page.time(page.position); color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
            Item { Layout.fillWidth: true }
            Text { text: page.player?.lengthSupported ? page.time(page.player.length) : "—"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
        }
        Repeater {
            model: page.service?.players ?? []
            ShellButton { required property var modelData; Layout.fillWidth: true; text: modelData.identity || modelData.dbusName; emphasized: modelData === page.player; trailingIcon: emphasized ? "check" : ""; onClicked: page.service.select(modelData.dbusName) }
        }
    }
}
