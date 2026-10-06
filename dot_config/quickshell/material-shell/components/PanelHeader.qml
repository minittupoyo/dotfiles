import QtQuick
import QtQuick.Layouts
import ".."
RowLayout {
    property string title: ""
    signal dismissed()
    Text { Layout.fillWidth: true; text: parent.title; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.titleSize; font.weight: Font.DemiBold }
    ShellButton { icon: "close"; Accessible.name: "閉じる"; onClicked: parent.dismissed() }
}
