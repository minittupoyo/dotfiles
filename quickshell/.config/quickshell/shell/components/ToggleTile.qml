import QtQuick
import "../tokens"

// クイック設定のトグルタイル。アイコンを上、ラベルを下に置く。選択で色と角丸がモーフする。
//   ToggleTile { icon: "bluetooth"; text: "Bluetooth"; checked: on; onClicked: toggle() }
BaseButton {
    id: root

    property string icon
    property string text

    variant: "tonal"
    checkable: true
    autoToggle: false    // 状態は外部 (Bluetooth の電源など) が持つ
    implicitHeight: 76
    implicitWidth: 120
    pressedRadius: Shapes.medium
    squareRadius: Shapes.large

    Column {
        anchors.centerIn: parent
        spacing: 4

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: root.icon
            size: 24
            fill: root.checkProgress
            color: root.contentColor
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.text
            role: Typography.labelMedium
            color: root.contentColor
        }
    }
}
