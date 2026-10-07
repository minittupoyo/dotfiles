import QtQuick
import QtQuick.Layouts
import ".."
RowLayout {
    id: header
    property string title: ""
    property string subtitle: ""
    property string icon: ""
    signal dismissed()
    spacing: Theme.space12
    Rectangle {
        visible: header.icon !== ""
        width: Theme.panelHeadingIconSize; height: width; radius: Theme.shapeMedium
        color: Theme.secondaryContainer
        MaterialIcon { anchors.centerIn: parent; name: header.icon; color: Theme.secondaryContainerText }
    }
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Theme.space4
        Text { Layout.fillWidth: true; text: header.title; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.titleSize; font.weight: Font.DemiBold; elide: Text.ElideRight }
        Text { visible: header.subtitle !== ""; Layout.fillWidth: true; text: header.subtitle; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize; wrapMode: Text.Wrap }
    }
    ShellButton { icon: "close"; flat: true; Accessible.name: "閉じる"; onClicked: header.dismissed() }
}
