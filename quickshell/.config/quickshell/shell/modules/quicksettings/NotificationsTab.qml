import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"
import "../../tokens"

// 「通知」タブ: おやすみモードと、通知の履歴 (概要タブより広く出す)。
Item {
    id: root

    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 12

        ToggleTile {
            Layout.fillWidth: true
            icon: Notifications.dnd ? "notifications_off" : "notifications"
            text: "おやすみモード"
            checked: Notifications.dnd
            onClicked: Notifications.setDnd(!Notifications.dnd)
        }
        Label {
            Layout.fillWidth: true
            Layout.leftMargin: 12
            text: "オンの間は、通知のポップアップを出さず、履歴にだけ残します。"
            role: Typography.bodySmall
            color: Colors.m3OnSurfaceVariant
            wrapMode: Text.Wrap
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4

            Label {
                text: "履歴"
                role: Typography.titleSmall
                color: Colors.m3Primary
            }
            Label {
                visible: Notifications.count > 0
                text: Notifications.count
                role: Typography.labelLarge
                color: Colors.m3OnSurfaceVariant
                Layout.leftMargin: 4
            }
            Item { Layout.fillWidth: true }
            Button {
                size: "s"
                variant: "text"
                text: "すべて消去"
                visible: Notifications.count > 0
                onClicked: Notifications.clearAll()
            }
        }

        ListView {
            id: history
            Layout.fillWidth: true
            Layout.preferredHeight: Notifications.count === 0 ? 56 : Math.min(contentHeight, 480)
            clip: true
            spacing: 8
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel {
                values: Notifications.history.values.slice().reverse()
            }
            delegate: NotificationRow {
                width: history.width
            }

            Label {
                anchors.centerIn: parent
                visible: Notifications.count === 0
                text: "通知はありません"
                role: Typography.bodyMedium
                color: Colors.m3OnSurfaceVariant
            }
        }
    }
}
