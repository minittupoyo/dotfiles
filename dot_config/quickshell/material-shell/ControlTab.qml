import QtQuick

Rectangle {
    id: button
    property string name: ""
    property string icon: ""
    property string label: ""
    property bool selected: false
    signal chosen(string name)
    implicitWidth: Theme.quickTabWidth
    implicitHeight: Theme.quickTabHeight
    color: "transparent"
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: label
    Accessible.description: selected ? "選択中" : ""
    Keys.onReturnPressed: { chosen(name); }
    Keys.onSpacePressed: { chosen(name); }
    Column {
        anchors.centerIn: parent
        spacing: Theme.space4
        Rectangle {
            id: indicator
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.quickTabIndicatorWidth
            height: Theme.quickTabIndicatorHeight
            radius: pointer.pressed ? Theme.pressedRadius : height / 2
            color: button.selected ? Theme.secondaryContainer : "transparent"
            readonly property color contentColor: button.selected ? Theme.secondaryContainerText : Theme.surfaceVariantText
            border.width: button.activeFocus ? 1 : 0
            border.color: Theme.primary
            Behavior on color { ColorAnimation { duration: Theme.motionDuration } }
            Behavior on radius { enabled: !Theme.reducedMotion; SpringAnimation { spring: Theme.motionSpring; damping: Theme.motionDamping; epsilon: Theme.motionEpsilon } }
            Rectangle { anchors.fill: parent; radius: parent.radius; color: pointer.pressed ? Qt.rgba(indicator.contentColor.r, indicator.contentColor.g, indicator.contentColor.b, 0.10) : pointer.containsMouse ? Qt.rgba(indicator.contentColor.r, indicator.contentColor.g, indicator.contentColor.b, 0.08) : "transparent" }
            MaterialIcon { anchors.centerIn: parent; name: button.icon; size: Theme.iconSize; color: button.selected ? Theme.secondaryContainerText : Theme.surfaceVariantText }
        }
        Text {
            objectName: "controlTabLabel"
            width: Theme.quickTabWidth
            height: Theme.labelMediumLineHeight
            text: button.label
            color: button.selected ? Theme.secondaryContainerText : Theme.surfaceVariantText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelMediumSize
            font.weight: button.selected ? Font.Medium : Font.Normal
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }
    MouseArea { id: pointer; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onPressed: button.focus = false; onClicked: button.chosen(button.name) }
}
