import QtQuick
import ".."
Rectangle {
    id: control
    property bool checked: false
    signal toggled()
    implicitWidth: Theme.switchWidth
    implicitHeight: Theme.switchHeight
    radius: height / 2
    color: checked ? Theme.primary : Theme.inputBackground
    Behavior on color { ColorAnimation { duration: Theme.motionDuration } }
    border.width: activeFocus ? 1 : 0
    border.color: Theme.primary
    activeFocusOnTab: enabled
    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true
    Accessible.checked: checked
    Keys.onSpacePressed: toggled()
    Keys.onReturnPressed: toggled()
    Rectangle { width: Theme.switchThumb; height: width; radius: width / 2; anchors.verticalCenter: parent.verticalCenter; x: control.checked ? control.width - width - Theme.space4 : Theme.space4; color: control.checked ? Theme.primaryText : Theme.surfaceVariantText; Behavior on x { enabled: !Theme.reducedMotion; SpringAnimation { spring: Theme.motionSpring; damping: Theme.motionDamping; epsilon: Theme.motionEpsilon } } }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: control.toggled() }
}
