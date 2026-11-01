import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../../components"
import "../../tokens"

// 「Bluetooth」タブ: 電源、ペア済みの端末の接続・切断・削除。
// 新しい端末のペアリングは未対応 (bluetoothctl で行う)。
Item {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var devices: adapter ? adapter.devices.values.filter(d => d.paired) : []

    // 削除の確認中の端末 (アドレス)。"" なら確認していない
    property string confirmingForget: ""

    function iconFor(d) {
        const i = d.icon || "";
        if (i.indexOf("headset") >= 0 || i.indexOf("headphones") >= 0)
            return "headphones";
        if (i.indexOf("audio") >= 0)
            return "speaker";
        if (i.indexOf("phone") >= 0)
            return "smartphone";
        if (i.indexOf("keyboard") >= 0)
            return "keyboard";
        if (i.indexOf("mouse") >= 0)
            return "mouse";
        if (i.indexOf("gaming") >= 0)
            return "sports_esports";
        return "bluetooth";
    }

    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 12

        ToggleTile {
            Layout.fillWidth: true
            visible: root.adapter !== null
            icon: "bluetooth"
            text: "Bluetooth"
            checked: root.adapter !== null && root.adapter.enabled
            onClicked: root.adapter.enabled = !root.adapter.enabled
        }

        Label {
            visible: root.adapter === null
            text: "Bluetooth アダプターが見つかりません"
            role: Typography.bodyMedium
            color: Colors.m3OnSurfaceVariant
        }

        Label {
            visible: root.adapter !== null && root.adapter.enabled
            Layout.topMargin: 4
            text: "ペア済みの端末"
            role: Typography.titleSmall
            color: Colors.m3Primary
        }

        Repeater {
            model: ScriptModel {
                values: root.adapter && root.adapter.enabled ? root.devices : []
            }

            ColumnLayout {
                id: row
                required property var modelData    // BluetoothDevice
                readonly property bool confirming: root.confirmingForget === modelData.address
                Layout.fillWidth: true
                spacing: 0

                // 通常の行: 本体のクリックで接続・切断、右端のボタンで削除の確認へ
                RowLayout {
                    visible: !row.confirming
                    Layout.fillWidth: true
                    spacing: 4

                    ChoiceRow {
                        Layout.fillWidth: true
                        icon: root.iconFor(row.modelData)
                        text: row.modelData.name + (row.modelData.batteryAvailable ? "  " + Math.round(row.modelData.battery * 100) + "%" : "")
                        checked: row.modelData.connected
                        onClicked: row.modelData.connected ? row.modelData.disconnect() : row.modelData.connect()
                    }
                    IconButton {
                        size: "s"
                        variant: "standard"
                        icon: "link_off"
                        onClicked: root.confirmingForget = row.modelData.address
                    }
                }

                // 削除の確認
                Rectangle {
                    visible: row.confirming
                    Layout.fillWidth: true
                    implicitHeight: 72
                    radius: Shapes.large
                    color: Colors.m3ErrorContainer

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 8

                        Label {
                            Layout.fillWidth: true
                            text: "「" + row.modelData.name + "」のペアリングを削除しますか？"
                            role: Typography.titleSmall
                            color: Colors.m3OnErrorContainer
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                        }
                        Button {
                            size: "s"
                            variant: "text"
                            text: "キャンセル"
                            onClicked: root.confirmingForget = ""
                        }
                        Button {
                            size: "s"
                            variant: "filled"
                            text: "削除"
                            onClicked: {
                                root.confirmingForget = "";
                                row.modelData.forget();
                            }
                        }
                    }
                }
            }
        }

        Label {
            visible: root.adapter !== null && root.adapter.enabled && root.devices.length === 0
            Layout.leftMargin: 12
            text: "ペア済みの端末はありません"
            role: Typography.bodyMedium
            color: Colors.m3OnSurfaceVariant
        }

        Label {
            visible: root.adapter !== null && root.adapter.enabled
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.leftMargin: 12
            text: "新しい端末のペアリングは、bluetoothctl で行います。"
            role: Typography.bodySmall
            color: Colors.m3OnSurfaceVariant
            wrapMode: Text.Wrap
        }
    }
}
