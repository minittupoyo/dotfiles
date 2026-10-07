import QtQuick
import QtQuick.Layouts

Rectangle {
    id: tile
    property string title: ""
    property string icon: ""
    property string subtitle: ""
    property bool checked: false
    property bool checkable: false
    property bool available: true
    signal toggled()
    Layout.fillWidth: true
    Layout.preferredHeight: Theme.quickSettingTileHeight
    radius: pointer.pressed ? Theme.pressedRadius : Theme.shapeMedium
    color: checked ? Theme.secondaryContainer : Theme.surfaceContainerHigh
    opacity: available ? 1 : 0.38
    Behavior on radius { enabled: !Theme.reducedMotion; SpringAnimation { spring: Theme.motionSpring; damping: Theme.motionDamping; epsilon: Theme.motionEpsilon } }
    Behavior on color { ColorAnimation { duration: Theme.motionDuration } }
    activeFocusOnTab: available
    border.width: activeFocus ? 1 : 0
    border.color: Theme.primary
    Accessible.role: checkable ? Accessible.CheckBox : Accessible.Button
    Accessible.name: title
    Accessible.description: subtitle
    Accessible.checkable: checkable
    Accessible.checked: checked
    Keys.onReturnPressed: if (available) toggled()
    Keys.onSpacePressed: if (available) toggled()
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Theme.space16
        anchors.rightMargin: Theme.space16
        spacing: Theme.space12
        MaterialIcon { name: tile.icon; size: Theme.quickSettingIconSize; color: tile.checked ? Theme.secondaryContainerText : Theme.surfaceVariantText }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.space4
            Text {
                Layout.fillWidth: true
                text: tile.title
                color: tile.checked ? Theme.secondaryContainerText : Theme.surfaceText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.bodySize
                font.weight: Font.Medium
                elide: Text.ElideRight
            }
            Text { visible: tile.subtitle !== ""; Layout.fillWidth: true; text: tile.subtitle; color: tile.checked ? Theme.secondaryContainerText : Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize; elide: Text.ElideRight }
        }
        MaterialIcon { name: tile.checked ? "check" : "chevron_right"; visible: tile.available; color: tile.checked ? Theme.secondaryContainerText : Theme.surfaceVariantText }
    }
    Rectangle { anchors.fill: parent; radius: parent.radius; color: pointer.pressed ? Theme.pressedState : pointer.containsMouse ? Theme.hoverState : "transparent" }
    MouseArea { id: pointer; anchors.fill: parent; enabled: tile.available; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onPressed: tile.focus = false; onClicked: tile.toggled() }
}
