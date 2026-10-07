import QtQuick
import QtQuick.Layouts
import ".."
Rectangle {
    id: card
    property var notification: null
    implicitHeight: content.implicitHeight + Theme.space16 * 2
    radius: Theme.shapeMedium
    color: Theme.panelBackground
    ColumnLayout {
        id: content
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: Theme.space16
        spacing: Theme.space8
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: card.notification?.appName ?? ""; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
            ShellButton { icon: "close"; flat: true; Accessible.name: "通知を閉じる"; onClicked: card.notification?.dismiss() }
        }
        Text { Layout.fillWidth: true; text: card.notification?.summary ?? ""; textFormat: Text.PlainText; wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; font.weight: Font.Medium }
        Text { Layout.fillWidth: true; visible: text !== ""; text: card.notification?.body ?? ""; textFormat: Text.PlainText; wrapMode: Text.Wrap; maximumLineCount: 4; elide: Text.ElideRight; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        Flow {
            Layout.fillWidth: true
            spacing: Theme.space4
            Repeater {
                model: card.notification?.actions ?? []
                ShellButton {
                    required property var modelData
                    text: modelData.text
                    onClicked: { modelData.invoke(); }
                }
            }
        }
    }
}
