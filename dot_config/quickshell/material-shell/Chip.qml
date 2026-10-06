import QtQuick
import QtQuick.Layouts

Rectangle {
    id: chip
    property string icon: ""
    property string label: ""
    property string hint: ""
    property bool interactive: false
    property int horizontalPadding: Theme.space12
    property color foreground: Theme.surfaceVariantText
    signal clicked()
    signal scrolled(real delta)
    implicitWidth: content.implicitWidth + horizontalPadding * 2
    implicitHeight: Theme.controlHeight
    radius: Theme.shapeFull
    color: !interactive ? "transparent" : mouse.pressed ? Theme.pressedState : mouse.containsMouse ? Theme.hoverState : "transparent"
    border.width: activeFocus ? 1 : 0
    border.color: Theme.primary
    activeFocusOnTab: interactive
    Accessible.role: interactive ? Accessible.Button : Accessible.StaticText
    Accessible.name: hint || label
    Keys.onReturnPressed: if (interactive) clicked()
    Keys.onSpacePressed: if (interactive) clicked()
    Behavior on color { ColorAnimation { duration: Theme.motionDuration } }
    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Theme.space8
        MaterialIcon {
            visible: chip.icon !== ""
            name: chip.icon
            color: chip.foreground
            size: Theme.barIconSize
            Layout.preferredWidth: Theme.barIconSize
            Layout.preferredHeight: Theme.barIconSize
        }
        Text {
            visible: chip.label !== ""
            text: chip.label
            color: chip.foreground
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelSize
            font.weight: Font.Medium
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: chip.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: chip.focus = false
        onClicked: if (chip.interactive) chip.clicked()
        onWheel: wheel => { if (chip.interactive) chip.scrolled(wheel.angleDelta.y); }
    }
    BarTooltip {
        target: chip
        text: chip.hint
        active: chip.visible && mouse.containsMouse && !mouse.pressed
    }
}
