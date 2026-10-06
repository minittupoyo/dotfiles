import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: button
    property string text: ""
    property string icon: ""
    property string trailingIcon: ""
    property bool emphasized: false
    signal clicked()
    implicitHeight: Theme.buttonHeight
    implicitWidth: content.implicitWidth + Theme.space16 * 2
    radius: area.pressed ? Theme.pressedRadius : height / 2
    color: emphasized ? Theme.primary : Theme.inputBackground
    Behavior on radius { enabled: !Theme.reducedMotion; SpringAnimation { spring: Theme.motionSpring; damping: Theme.motionDamping; epsilon: Theme.motionEpsilon } }
    Behavior on color { ColorAnimation { duration: Theme.motionDuration } }
    opacity: enabled ? 1 : 0.38
    activeFocusOnTab: enabled
    border.width: activeFocus ? 1 : 0
    border.color: Theme.primary
    Accessible.role: Accessible.Button
    Accessible.name: text
    Keys.onReturnPressed: clicked()
    Keys.onSpacePressed: clicked()
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: area.pressed ? Theme.pressedState : area.containsMouse ? Theme.hoverState : "transparent"
    }
    RowLayout {
        id: content
        anchors.centerIn: parent
        spacing: Theme.space8
        MaterialIcon { visible: button.icon !== ""; name: button.icon; color: button.emphasized ? Theme.primaryText : Theme.surfaceVariantText }
        Text { visible: text !== ""; text: button.text; color: button.emphasized ? Theme.primaryText : Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; font.weight: Font.Medium }
        MaterialIcon { visible: button.trailingIcon !== ""; name: button.trailingIcon; color: button.emphasized ? Theme.primaryText : Theme.surfaceVariantText }
    }
    MouseArea { id: area; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: button.clicked() }
}
