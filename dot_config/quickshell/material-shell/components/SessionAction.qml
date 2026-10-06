import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: action
    property string label: ""
    property string icon: ""
    signal clicked()

    implicitWidth: Theme.sessionActionWidth
    implicitHeight: Theme.sessionActionHeight
    radius: area.pressed ? Theme.pressedRadius : Theme.shapeMedium
    color: Theme.inputBackground
    opacity: enabled ? 1 : 0.38
    activeFocusOnTab: enabled
    border.width: activeFocus ? 1 : 0
    border.color: Theme.primary
    Accessible.role: Accessible.Button
    Accessible.name: label
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
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
            color: Theme.surfaceText
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
            color: Theme.surfaceText
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
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: action.clicked()
    }
}
