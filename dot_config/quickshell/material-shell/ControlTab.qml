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
    border.width: activeFocus ? 1 : 0
    border.color: Theme.primary
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
            radius: Theme.shapeFull
            color: button.selected ? (pointer.pressed ? Qt.rgba(Theme.secondaryContainerText.r, Theme.secondaryContainerText.g, Theme.secondaryContainerText.b, 0.10) : Theme.secondaryContainer)
                                   : pointer.pressed ? Qt.rgba(Theme.surfaceVariantText.r, Theme.surfaceVariantText.g, Theme.surfaceVariantText.b, 0.10)
                                                     : pointer.containsMouse ? Qt.rgba(Theme.surfaceVariantText.r, Theme.surfaceVariantText.g, Theme.surfaceVariantText.b, 0.08) : "transparent"
            border.width: button.activeFocus ? 1 : 0
            border.color: Theme.primary
            Behavior on color { ColorAnimation { duration: Theme.motionDuration } }
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
