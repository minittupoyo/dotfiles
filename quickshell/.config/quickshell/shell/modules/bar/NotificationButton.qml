import QtQuick
import "../../components"
import "../../services"
import "../../tokens"

// バーの通知・クイック設定ボタン。通知の数のバッジ付き。クリックでクイック設定を開閉する。
Item {
    implicitWidth: 40
    implicitHeight: 40

    IconButton {
        anchors.fill: parent
        size: "s"
        variant: "standard"
        checkable: true
        autoToggle: false
        checked: UiState.quickSettingsOpen
        icon: Notifications.dnd ? "notifications_off" : "notifications"
        onClicked: UiState.toggleQuickSettings()
    }

    // 未読ではなく「履歴にある数」。おやすみ中は出さない
    Rectangle {
        visible: Notifications.count > 0 && !Notifications.dnd
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 2
        anchors.rightMargin: 2
        width: Math.max(16, badgeText.implicitWidth + 8)
        height: 16
        radius: Shapes.full
        color: Colors.m3Error

        Label {
            id: badgeText
            anchors.centerIn: parent
            text: Notifications.count > 9 ? "9+" : Notifications.count
            role: Typography.labelSmall
            color: Colors.m3OnError
        }
    }
}
