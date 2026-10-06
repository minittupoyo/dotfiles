import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

PanelWindow {
    id: osd
    property string icon: "volume_up"
    property string label: ""
    property real value: 0
    property bool mediaMode: false
    property string artworkUrl: ""
    property string artist: ""
    visible: false
    anchors.bottom: true
    margins.bottom: Theme.space32
    implicitWidth: mediaMode ? Theme.mediaOsdWidth : Theme.osdWidth
    readonly property int contentHeight: mediaMode
        ? Math.max(Theme.mediaOsdArtworkSize, titleText.implicitHeight + Theme.space4 + artistText.implicitHeight)
        : Math.max(Theme.iconSize, titleText.implicitHeight + Theme.space8 + progressBar.implicitHeight)
    implicitHeight: contentHeight + Theme.osdVerticalPadding * 2
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}
    WlrLayershell.namespace: "material-shell-osd"
    function show(kind, text, amount, targetScreen) {
        if (!Settings.values.osd) return;
        screen = targetScreen; mediaMode = false; artworkUrl = ""; artist = "";
        icon = kind; label = text; value = Math.max(0, Math.min(1, amount)); visible = true; hide.restart();
    }
    function showTrack(player, targetScreen) {
        if (!Settings.values.osd || !player) return;
        screen = targetScreen;
        mediaMode = true;
        artworkUrl = player.trackArtUrl || "";
        label = player.trackTitle || player.identity || "再生中";
        artist = player.trackArtist || "アーティスト不明";
        visible = true;
        hide.restart();
    }
    Timer { id: hide; interval: osd.mediaMode ? Theme.mediaOsdDuration : Theme.osdDuration; onTriggered: osd.visible = false }
    Rectangle {
        anchors.fill: parent
        radius: Theme.shapeMedium
        color: Theme.panelBackground
        RowLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Theme.space16
            spacing: Theme.space16
            Rectangle {
                visible: osd.mediaMode
                Layout.preferredWidth: Theme.mediaOsdArtworkSize
                Layout.preferredHeight: Theme.mediaOsdArtworkSize
                radius: Theme.shapeSmall
                color: Theme.inputBackground
                clip: true
                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: osd.artworkUrl
                    sourceSize.width: Theme.mediaOsdArtworkSize
                    sourceSize.height: Theme.mediaOsdArtworkSize
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    visible: status === Image.Ready
                }
                Shape {
                    anchors.fill: parent
                    visible: albumArt.status === Image.Ready
                    antialiasing: true
                    ShapePath {
                        fillRule: ShapePath.OddEvenFill
                        fillColor: Theme.inputBackground
                        strokeColor: "transparent"
                        startX: 0
                        startY: 0
                        PathLine { x: Theme.mediaOsdArtworkSize; y: 0 }
                        PathLine { x: Theme.mediaOsdArtworkSize; y: Theme.mediaOsdArtworkSize }
                        PathLine { x: 0; y: Theme.mediaOsdArtworkSize }
                        PathLine { x: 0; y: 0 }
                        PathMove { x: Theme.shapeSmall; y: 0 }
                        PathLine { x: Theme.mediaOsdArtworkSize - Theme.shapeSmall; y: 0 }
                        PathArc { x: Theme.mediaOsdArtworkSize; y: Theme.shapeSmall; radiusX: Theme.shapeSmall; radiusY: Theme.shapeSmall; direction: PathArc.Clockwise }
                        PathLine { x: Theme.mediaOsdArtworkSize; y: Theme.mediaOsdArtworkSize - Theme.shapeSmall }
                        PathArc { x: Theme.mediaOsdArtworkSize - Theme.shapeSmall; y: Theme.mediaOsdArtworkSize; radiusX: Theme.shapeSmall; radiusY: Theme.shapeSmall; direction: PathArc.Clockwise }
                        PathLine { x: Theme.shapeSmall; y: Theme.mediaOsdArtworkSize }
                        PathArc { x: 0; y: Theme.mediaOsdArtworkSize - Theme.shapeSmall; radiusX: Theme.shapeSmall; radiusY: Theme.shapeSmall; direction: PathArc.Clockwise }
                        PathLine { x: 0; y: Theme.shapeSmall }
                        PathArc { x: Theme.shapeSmall; y: 0; radiusX: Theme.shapeSmall; radiusY: Theme.shapeSmall; direction: PathArc.Clockwise }
                    }
                }
                MaterialIcon {
                    anchors.centerIn: parent
                    name: "music_note"
                    size: Theme.iconSize
                    visible: albumArt.status !== Image.Ready
                }
            }
            MaterialIcon { visible: !osd.mediaMode; name: osd.icon; Layout.alignment: Qt.AlignVCenter }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: osd.mediaMode ? Theme.space4 : Theme.space8
                Text {
                    id: titleText
                    Layout.fillWidth: true
                    text: osd.label
                    color: Theme.surfaceText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodySize
                    font.weight: osd.mediaMode ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                Text {
                    id: artistText
                    visible: osd.mediaMode
                    Layout.fillWidth: true
                    text: osd.artist
                    color: Theme.surfaceVariantText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSize
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
                ExpressiveProgress {
                    id: progressBar
                    visible: !osd.mediaMode
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    value: osd.value
                    animationEnabled: osd.visible
                }
            }
        }
    }
}
