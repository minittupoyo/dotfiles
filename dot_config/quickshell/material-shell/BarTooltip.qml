import Quickshell
import QtQuick

PopupWindow {
    id: tooltip
    required property Item target
    property string text: ""
    property bool active: false
    property bool ready: false

    visible: active && ready && text !== ""
    color: "transparent"
    grabFocus: false
    implicitWidth: Math.ceil(message.implicitWidth) + Theme.space16
    implicitHeight: Math.max(Theme.space24, Math.ceil(message.implicitHeight) + Theme.space8)
    anchor.item: target
    anchor.rect.x: target.width / 2
    anchor.rect.y: target.height + Theme.space8
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    anchor.adjustment: PopupAdjustment.SlideX | PopupAdjustment.FlipY

    onActiveChanged: ready = false
    Timer {
        interval: Theme.tooltipDelay
        running: tooltip.active && tooltip.text !== ""
        onTriggered: tooltip.ready = true
    }
    // Material 3 plain tooltip: inverse surface, 4px corners, no elevation.
    Rectangle {
        anchors.fill: parent
        radius: Theme.shapeExtraSmall
        color: Theme.inverseSurface
        Text {
            id: message
            anchors.centerIn: parent
            text: tooltip.text
            textFormat: Text.PlainText
            color: Theme.inverseSurfaceText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelSize
            font.weight: Font.Normal
            Accessible.role: Accessible.ToolTip
            Accessible.name: text
        }
    }
}
