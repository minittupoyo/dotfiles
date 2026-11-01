import QtQuick
import QtQuick.Layouts
import "../tokens"

// 選択肢の 1 行 (デバイスの一覧など)。選ばれている行は色が付いて、チェックが出る。
//   ChoiceRow { text: "Speaker"; icon: "speaker"; checked: isCurrent; onClicked: select() }
BaseButton {
    id: root

    property string text
    property string icon

    implicitHeight: 44
    variant: "standard"
    checkable: true
    autoToggle: false
    squareRadius: Shapes.medium

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        Icon {
            visible: root.icon !== ""
            name: root.icon
            size: 20
            fill: root.checkProgress
            color: root.contentColor
        }
        Label {
            Layout.fillWidth: true
            text: root.text
            role: Typography.labelLarge
            color: root.checked ? root.contentColor : Colors.m3OnSurface
            elide: Text.ElideRight
        }
        Icon {
            visible: root.checked
            name: "check"
            size: 20
            color: root.contentColor
        }
    }
}
