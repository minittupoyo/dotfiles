import QtQuick
import QtQuick.Layouts
import "../tokens"

// 設定の 1 行: 左にタイトルと説明、右にコントロール (子要素は右側に入る)。
//   SettingRow {
//       title: "ダークモード"; description: "配色を暗くする"
//       Switch { checked: Settings.darkMode; onToggled: Settings.set("darkMode", !checked) }
//   }
Item {
    id: root

    property string title
    property string description
    // 説明を右に出さず、コントロールを下の行に回す (幅の要るコントロール向け)
    property bool stacked: false

    default property alias control: ctrl.data

    implicitHeight: Math.max(64, grid.implicitHeight + 24)

    GridLayout {
        id: grid
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        columns: root.stacked ? 1 : 2
        columnSpacing: 16
        rowSpacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Label {
                Layout.fillWidth: true
                text: root.title
                role: Typography.bodyLarge
                elide: Text.ElideRight
            }
            Label {
                Layout.fillWidth: true
                visible: root.description !== ""
                text: root.description
                role: Typography.bodySmall
                color: Colors.m3OnSurfaceVariant
                wrapMode: Text.WordWrap
            }
        }

        RowLayout {
            id: ctrl
            Layout.alignment: root.stacked ? Qt.AlignLeft : Qt.AlignRight | Qt.AlignVCenter
            Layout.fillWidth: root.stacked
            spacing: 8
        }
    }
}
