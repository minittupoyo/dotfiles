import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: button
    property string text: ""
    property string icon: ""
    property string trailingIcon: ""
    property bool emphasized: false
    property bool destructive: false
    property bool flat: false
    property bool alignLeft: false
    readonly property color containerColor: flat ? "transparent" : destructive ? (emphasized ? Theme.error : Theme.errorContainer) : (emphasized ? Theme.primary : Theme.secondaryContainer)
    readonly property color contentColor: flat ? (destructive ? Theme.error : Theme.surfaceVariantText) : destructive ? (emphasized ? Theme.errorText : Theme.errorContainerText) : (emphasized ? Theme.primaryText : Theme.secondaryContainerText)
    readonly property color stateLayer: contentColor
    signal clicked()
    implicitHeight: Theme.buttonHeight
    implicitWidth: text === "" && trailingIcon === "" ? Theme.buttonHeight : content.implicitWidth + Theme.space16 * 2
    radius: area.pressed ? Theme.pressedRadius : height / 2
    color: containerColor
    Behavior on radius { enabled: !Theme.reducedMotion; SpringAnimation { spring: Theme.motionSpring; damping: Theme.motionDamping; epsilon: Theme.motionEpsilon } }
    Behavior on color { ColorAnimation { duration: Theme.motionDuration } }
    opacity: enabled ? 1 : 0.38
    activeFocusOnTab: enabled
    border.width: activeFocus ? 1 : 0
    border.color: Theme.primary
    Accessible.role: Accessible.Button
    Accessible.name: text
    Keys.onReturnPressed: if (enabled) clicked()
    Keys.onSpacePressed: if (enabled) clicked()
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: area.pressed || button.activeFocus ? Qt.rgba(button.stateLayer.r, button.stateLayer.g, button.stateLayer.b, 0.10)
                            : area.containsMouse ? Qt.rgba(button.stateLayer.r, button.stateLayer.g, button.stateLayer.b, 0.08)
                                                 : "transparent"
    }
    RowLayout {
        id: content
        anchors.centerIn: button.alignLeft ? undefined : parent
        anchors.left: button.alignLeft ? parent.left : undefined
        anchors.right: button.alignLeft ? parent.right : undefined
        anchors.leftMargin: Theme.space12
        anchors.rightMargin: Theme.space12
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.space8
        MaterialIcon { visible: button.icon !== ""; name: button.icon; color: button.contentColor }
        Text { visible: text !== ""; Layout.fillWidth: button.alignLeft; text: button.text; elide: Text.ElideRight; color: button.contentColor; font.family: Theme.fontFamily; font.pixelSize: Theme.labelLargeSize; font.weight: Font.Medium }
        MaterialIcon { visible: button.trailingIcon !== ""; name: button.trailingIcon; color: button.contentColor }
    }
    MouseArea { id: area; anchors.fill: parent; enabled: button.enabled; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onPressed: button.focus = false; onClicked: button.clicked() }
}
