import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: action
    property string label: ""
    property string icon: ""
    property bool destructive: false
    signal clicked()

    implicitWidth: Theme.sessionActionWidth
    implicitHeight: Theme.sessionActionHeight
    radius: area.pressed ? Theme.pressedRadius : Theme.shapeMedium
    color: destructive ? Theme.errorContainer : Theme.surfaceContainerHighest
    opacity: enabled ? 1 : 0.38
    activeFocusOnTab: enabled
    border.width: activeFocus ? 1 : 0
    border.color: Theme.primary
    Accessible.role: Accessible.Button
    Accessible.name: label
    Keys.onReturnPressed: if (enabled) clicked()
    Keys.onSpacePressed: if (enabled) clicked()
    Behavior on radius {
        enabled: !Theme.reducedMotion
        SpringAnimation { spring: Theme.motionSpring; damping: Theme.motionDamping; epsilon: Theme.motionEpsilon }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.sessionActionSpacing
        MaterialIcon {
            Layout.alignment: Qt.AlignHCenter
            name: action.icon
            size: Theme.sessionActionIconSize
            color: action.destructive ? Theme.errorContainerText : Theme.surfaceText
        }
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: action.width - Theme.space8 * 2
            Layout.minimumWidth: Layout.preferredWidth
            Layout.maximumWidth: Layout.preferredWidth
            Layout.preferredHeight: Theme.sessionActionLabelHeight
            Layout.minimumHeight: Theme.sessionActionLabelHeight
            Layout.maximumHeight: Theme.sessionActionLabelHeight
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: action.label
            textFormat: Text.PlainText
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            color: action.destructive ? Theme.errorContainerText : Theme.surfaceText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.sessionActionLabelSize
            font.weight: Font.Medium
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: area.pressed ? Theme.pressedState : area.containsMouse ? Theme.hoverState : "transparent"
    }
    MouseArea {
        id: area
        anchors.fill: parent
        enabled: action.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: action.focus = false
        onClicked: action.clicked()
    }
}
