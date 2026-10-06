import QtQuick
import ".."
Rectangle {
    id: control
    property bool checked: false
    signal toggled()
    implicitWidth: Theme.switchWidth
    implicitHeight: Theme.switchHeight
    radius: height / 2
    color: checked ? Theme.primary : Theme.surfaceContainerHighest
    Behavior on color { ColorAnimation { duration: Theme.motionDuration } }
    border.width: activeFocus || !checked ? 1 : 0
    border.color: activeFocus ? Theme.primary : Theme.outline
    activeFocusOnTab: enabled
    opacity: enabled ? 1 : 0.38
    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true
    Accessible.checked: checked
    Keys.onSpacePressed: if (enabled) toggled()
    Keys.onReturnPressed: if (enabled) toggled()
    Rectangle {
        id: thumb
        width: Theme.switchThumb; height: width; radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: control.checked ? control.width - width - Theme.space4 : Theme.space4
        color: control.checked ? Theme.primaryText : Theme.surfaceVariantText
        Behavior on x { enabled: !Theme.reducedMotion; SpringAnimation { spring: Theme.motionSpring; damping: Theme.motionDamping; epsilon: Theme.motionEpsilon } }
        MaterialIcon { anchors.centerIn: parent; visible: control.checked; name: "check"; size: Theme.labelMediumSize; color: Theme.primary }
    }
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: pointer.pressed ? Qt.rgba(checked ? Theme.primaryText.r : Theme.surfaceText.r, checked ? Theme.primaryText.g : Theme.surfaceText.g, checked ? Theme.primaryText.b : Theme.surfaceText.b, 0.10)
               : pointer.containsMouse ? Qt.rgba(checked ? Theme.primaryText.r : Theme.surfaceText.r, checked ? Theme.primaryText.g : Theme.surfaceText.g, checked ? Theme.primaryText.b : Theme.surfaceText.b, 0.08)
                                        : "transparent"
    }
    MouseArea { id: pointer; anchors.fill: parent; enabled: control.enabled; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onPressed: control.focus = false; onClicked: control.toggled() }
}
