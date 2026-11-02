import QtQuick
import QtQuick.Layouts
import "../tokens"

// 設定のグループ: 見出し + 角丸のカードに行を縦に並べる。
//   SettingGroup { title: "外観"; SettingRow { ... } SettingRow { ... } }
ColumnLayout {
    id: root

    property string title

    default property alias rows: body.data

    spacing: 8

    Label {
        Layout.leftMargin: 8
        visible: root.title !== ""
        text: root.title
        role: Typography.titleSmallEmphasized
        color: Colors.m3Primary
    }

    Card {
        Layout.fillWidth: true
        implicitHeight: body.implicitHeight
        radius: Shapes.large
        clip: true

        ColumnLayout {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 0
        }
    }
}
