import QtQuick
import QtQuick.Layouts

PanelFrame {
    id: panel
    attachedToBar: true
    property var service: null
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space16
        PanelHeader { Layout.fillWidth: true; title: "通知"; onDismissed: panel.dismissed() }
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: "通知を一時停止"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
            Toggle { checked: Settings.values.dnd; Accessible.name: "通知を一時停止"; onToggled: Settings.save(Object.assign({}, Settings.values, {dnd: !checked})) }
        }
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: panel.service?.history ?? []
            spacing: Theme.space8
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            delegate: Rectangle {
                id: row
                required property var modelData
                readonly property var activeNotification: panel.service?.activeNotification(modelData) ?? null
                width: list.width
                height: content.implicitHeight + Theme.space16 * 2
                radius: Theme.shapeMedium
                color: Theme.inputBackground
                ColumnLayout {
                    id: content
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                    anchors.margins: Theme.space16
                    spacing: Theme.space8
                    RowLayout {
                        Layout.fillWidth: true
                        Text { Layout.fillWidth: true; text: row.modelData.app; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
                        Text { text: Qt.formatDateTime(new Date(row.modelData.timestamp), "MM/dd HH:mm"); color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
                    }
                    Text { Layout.fillWidth: true; text: row.modelData.summary; textFormat: Text.PlainText; wrapMode: Text.Wrap; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; font.weight: Font.Medium }
                    Text { Layout.fillWidth: true; visible: text !== ""; text: row.modelData.body; textFormat: Text.PlainText; wrapMode: Text.Wrap; maximumLineCount: 6; elide: Text.ElideRight; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                    Flow {
                        Layout.fillWidth: true
                        spacing: Theme.space4
                        Repeater {
                            model: row.activeNotification?.actions ?? []
                            ShellButton { required property var modelData; text: modelData.text; onClicked: { modelData.invoke(); } }
                        }
                        ShellButton { visible: !!row.activeNotification; text: "閉じる"; onClicked: row.activeNotification?.dismiss() }
                    }
                }
            }
            Text { anchors.centerIn: parent; visible: list.count === 0; text: "通知はありません"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        }
        RowLayout { Layout.fillWidth: true; Item { Layout.fillWidth: true } ShellButton { text: "履歴を消去"; enabled: (panel.service?.history.length ?? 0) > 0; onClicked: panel.service.clearHistory() } }
    }
}
