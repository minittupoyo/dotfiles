import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Window
import QtQuick.Layouts

PopupWindow {
    id: panel
    property var service: null
    property bool opened: false
    property bool exiting: false
    property real offsetScale: opened ? 0 : 1
    signal dismissed()
    visible: opened || exiting
    onOpenedChanged: exiting = !opened
    onOffsetScaleChanged: if (!opened && offsetScale >= 1) exiting = false
    Behavior on offsetScale {
        enabled: !Theme.reducedMotion
        NumberAnimation { duration: Theme.panelMotionDuration; easing.type: Easing.OutCubic }
    }
    color: "transparent"
    grabFocus: true
    HyprlandFocusGrab { windows: [panel]; active: panel.visible; onCleared: { if (panel.opened) panel.dismissed(); } }
    implicitWidth: Math.min(Theme.mediaPopupWidth, (screen?.width ?? Theme.mediaPopupWidth) - Theme.space16 * 2)
    implicitHeight: Math.min(Theme.launcherMaxHeight, Math.max(Theme.space32 * 3, contents.implicitHeight + header.implicitHeight + Theme.space16 + Theme.panelPadding * 2), (screen?.height ?? Theme.launcherMaxHeight) - Theme.barHeight - Theme.space24)
    anchor.rect.x: 0
    anchor.rect.y: anchor.item?.height ?? Theme.controlHeight
    anchor.edges: Edges.Bottom | Edges.Left
    anchor.gravity: Edges.Bottom | Edges.Right
    anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.SlideY

    readonly property var player: service?.player ?? null
    property real position: 0
    function refresh() { position = player?.positionSupported ? Math.max(0, player.position) : 0; }
    function time(seconds) { const s = Math.max(0, Math.floor(seconds || 0)); return Math.floor(s / 60) + ":" + (s % 60).toString().padStart(2, "0"); }
    onPlayerChanged: refresh()
    onVisibleChanged: { if (visible) { refresh(); Qt.callLater(() => { popupContent.forceActiveFocus(); popupContent.Window.window?.requestActivate(); }); } else if (opened) dismissed(); }
    Connections { target: panel.player; function onPositionChanged() { panel.refresh(); } function onPostTrackChanged() { panel.refresh(); } }
    Timer { interval: Theme.mediaPositionInterval; repeat: true; running: panel.visible && !!panel.player; onTriggered: panel.refresh() }
    Item {
        id: surface
        x: 0
        y: -(height + Theme.space4) * panel.offsetScale
        width: parent.width
        height: parent.height
        opacity: 1 - panel.offsetScale
    Rectangle { anchors.fill: parent; radius: Theme.popupRadius; color: Theme.surfaceContainer }
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Theme.popupRadius
        color: Theme.surfaceContainer
    }
    ColumnLayout {
        id: popupContent
        anchors.fill: parent; anchors.margins: Theme.panelPadding; spacing: Theme.space16
        focus: true
        Keys.onEscapePressed: panel.dismissed()
        PanelHeader { id: header; Layout.fillWidth: true; title: "Now Playing"; onDismissed: panel.dismissed() }
        Flickable {
            Layout.fillWidth: true; Layout.fillHeight: true
            clip: true; contentHeight: contents.implicitHeight; boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: contents
                width: parent.width; spacing: Theme.space16
                Text { visible: !panel.player; Layout.fillWidth: true; text: "再生プレイヤーがありません"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                Rectangle {
                    visible: !!panel.player; Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: Theme.mediaArtworkSize; Layout.preferredHeight: Theme.mediaArtworkSize
                    radius: Theme.shapeMedium; color: Theme.inputBackground; clip: true
                    Image { id: artwork; anchors.fill: parent; source: panel.player?.trackArtUrl ?? ""; asynchronous: true; sourceSize.width: Theme.mediaArtworkSize; sourceSize.height: Theme.mediaArtworkSize; fillMode: Image.PreserveAspectFit }
                    MaterialIcon { anchors.centerIn: parent; name: "music_note"; visible: artwork.status !== Image.Ready }
                }
                Text { visible: !!panel.player; Layout.fillWidth: true; text: panel.player?.trackTitle || "タイトルなし"; textFormat: Text.PlainText; wrapMode: Text.Wrap; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.titleSize; font.weight: Font.DemiBold }
                Text { visible: !!panel.player; Layout.fillWidth: true; text: [panel.player?.trackArtist, panel.player?.trackAlbum].filter(Boolean).join(" · ") || panel.player?.identity || ""; textFormat: Text.PlainText; wrapMode: Text.Wrap; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                Rectangle {
                    visible: !!panel.player; Layout.alignment: Qt.AlignHCenter
                    implicitWidth: transport.implicitWidth + Theme.space8 * 2
                    implicitHeight: Theme.buttonHeight + Theme.space8 * 2
                    radius: height / 2; color: Theme.inputBackground
                RowLayout {
                    id: transport; anchors.centerIn: parent
                    visible: !!panel.player; Layout.alignment: Qt.AlignHCenter; spacing: Theme.space4
                    ShellButton { objectName: "mediaPrevious"; icon: "skip_previous"; Accessible.name: "前の曲"; enabled: panel.player?.canGoPrevious ?? false; onClicked: panel.player.previous() }
                    ShellButton { objectName: "mediaPlay"; Layout.preferredWidth: Theme.mediaActionWidth; icon: panel.player?.isPlaying ? "pause" : "play_arrow"; Accessible.name: panel.player?.isPlaying ? "一時停止" : "再生"; emphasized: true; enabled: panel.player?.canTogglePlaying ?? false; onClicked: panel.player.togglePlaying() }
                    ShellButton { objectName: "mediaNext"; icon: "skip_next"; Accessible.name: "次の曲"; enabled: panel.player?.canGoNext ?? false; onClicked: panel.player.next() }
                }
                }
                ExpressiveProgress {
                    animationEnabled: panel.visible && (panel.player?.isPlaying ?? false)
                    objectName: "mediaProgress"; visible: !!panel.player && !!panel.player.lengthSupported && !!panel.player.positionSupported
                    Layout.fillWidth: true
                    value: panel.player?.length > 0 ? panel.position / panel.player.length : 0
                    Accessible.name: "再生位置"
                }
                RowLayout {
                    visible: !!panel.player && !!panel.player.positionSupported; Layout.fillWidth: true
                    Text { text: panel.time(panel.position); color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
                    Item { Layout.fillWidth: true }
                    Text { text: panel.player?.lengthSupported ? panel.time(panel.player.length) : "—"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
                }
                Repeater {
                    model: panel.service?.players ?? []
                    ShellButton { required property var modelData; Layout.fillWidth: true; text: modelData.identity || modelData.dbusName; emphasized: modelData === panel.player; trailingIcon: emphasized ? "check" : ""; onClicked: panel.service.select(modelData.dbusName) }
                }
            }
        }
    }
    }
}
