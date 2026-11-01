import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import "../../components"
import "../../tokens"

// 「Bluetooth」タブ: 電源、ペア済みの端末の接続・切断・削除。
// 近くの端末の検索とペアリング、信頼 (自動接続) の切り替え、検出可能・ペアリング可能の設定。
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

    // 表示中か (QuickSettingsPanel が渡す)。離れたら検索を止める
    property bool active: false
    // 近くの端末 (未ペアで、名前が取れているもの。名前がアドレスだけの端末は出さない)
    readonly property var nearby: adapter ? adapter.devices.values.filter(d => !d.paired && d.name !== "" && d.name.replace(/-/g, ":") !== d.address) : []
    readonly property bool scanning: adapter !== null && adapter.discovering

    function startScan() {
        if (adapter && adapter.enabled)
            adapter.discovering = true;
        scanLimit.restart();
    }
    function stopScan() {
        scanLimit.stop();
        if (adapter && adapter.discovering)
            adapter.discovering = false;
    }
    onActiveChanged: if (!active) stopScan()

    // 検索は 30 秒で自動的に止める
    Timer {
        id: scanLimit
        interval: 30000
        onTriggered: root.stopScan()
    }

    // ペアリングの受け口 (PIN 確認なしの agent)。検索中・ペアリング中だけ bluetoothctl に動かしてもらう
    Process {
        id: agent
        command: ["bluetoothctl", "--agent", "NoInputNoOutput"]
        running: root.active && (root.scanning || root.pairingBusy)
        stdinEnabled: true
    }
    readonly property bool pairingBusy: adapter !== null && adapter.devices.values.some(d => d.pairing)

    // ペアリングが済んだら、信頼して接続する
    Instantiator {
        model: root.adapter ? root.adapter.devices : null
        delegate: QtObject {
            id: watcher
            required property var modelData    // BluetoothDevice
            readonly property bool paired: modelData.paired
            property bool seen: false
            onPairedChanged: {
                // 検索中に新しくペアになった端末だけ (起動時の読み込みでは動かさない)
                if (paired && seen && root.scanning) {
                    modelData.trusted = true;
                    modelData.connect();
                }
            }
            Component.onCompleted: seen = true
        }
    }

    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            visible: root.adapter !== null
            spacing: 12

            Icon {
                Layout.leftMargin: 4
                name: "bluetooth"
                size: 24
                fill: root.adapter !== null && root.adapter.enabled ? 1 : 0
                color: root.adapter !== null && root.adapter.enabled ? Colors.m3Primary : Colors.m3OnSurfaceVariant
            }
            Label {
                Layout.fillWidth: true
                text: "Bluetooth"
                role: Typography.titleMedium
                color: Colors.m3OnSurface
            }
            Switch {
                checked: root.adapter !== null && root.adapter.enabled
                onToggled: root.adapter.enabled = !root.adapter.enabled
            }
        }

        // 検出可能・ペアリング可能
        RowLayout {
            Layout.fillWidth: true
            visible: root.adapter !== null && root.adapter.enabled
            spacing: 8

            ToggleTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: "visibility"
                text: "検出可能"
                checked: root.adapter !== null && root.adapter.discoverable
                onClicked: root.adapter.discoverable = !root.adapter.discoverable
            }
            ToggleTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: "link"
                text: "ペアリング可能"
                checked: root.adapter !== null && root.adapter.pairable
                onClicked: root.adapter.pairable = !root.adapter.pairable
            }
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
                        icon: "verified_user"
                        checkable: true
                        autoToggle: false
                        checked: row.modelData.trusted
                        onClicked: row.modelData.trusted = !row.modelData.trusted
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

        // ---- 近くの端末 ----
        RowLayout {
            visible: root.adapter !== null && root.adapter.enabled
            Layout.fillWidth: true
            Layout.topMargin: 8

            Label {
                text: "近くの端末"
                role: Typography.titleSmall
                color: Colors.m3Primary
            }
            Item { Layout.fillWidth: true }
            Button {
                size: "s"
                variant: root.scanning ? "filled" : "tonal"
                text: root.scanning ? "停止" : "探す"
                onClicked: root.scanning ? root.stopScan() : root.startScan()
            }
        }

        Repeater {
            model: ScriptModel {
                values: root.adapter && root.adapter.enabled ? root.nearby : []
            }

            ChoiceRow {
                id: near
                required property var modelData    // BluetoothDevice
                Layout.fillWidth: true
                icon: root.iconFor(modelData)
                text: modelData.name + (modelData.pairing ? "  ペアリング中…" : "")
                checked: modelData.pairing
                onClicked: modelData.pairing ? modelData.cancelPair() : modelData.pair()
            }
        }

        Label {
            visible: root.adapter !== null && root.adapter.enabled && root.nearby.length === 0
            Layout.fillWidth: true
            Layout.leftMargin: 12
            text: root.scanning ? "探しています…" : "「探す」で近くの端末を検索します。"
            role: Typography.bodyMedium
            color: Colors.m3OnSurfaceVariant
            wrapMode: Text.Wrap
        }
    }
}
