import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../components"
import "../../services"
import "../../tokens"

// 「回線」タブの WiFi: 電源、近くのネットワークの一覧、接続 (必要ならパスワード入力)、切断、保存済みの削除。
Item {
    id: root

    // 表示中か (NetworkTab が渡す)
    property bool active: false
    // パスワード入力を開いているネットワーク ("" なら開いていない)
    property string askingFor: ""
    // 削除の確認中のネットワーク
    property string confirmingForget: ""

    visible: Wifi.available
    implicitHeight: Wifi.available ? col.implicitHeight : 0

    Binding {
        target: Wifi
        property: "active"
        value: root.active
    }
    onActiveChanged: if (!active) { askingFor = ""; confirmingForget = ""; }

    function submit(ssid, pass) {
        askingFor = "";
        Wifi.connectTo(ssid, pass);
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "WiFi"
                role: Typography.titleSmall
                color: Colors.m3Primary
            }
            Label {
                visible: Wifi.scanning && Wifi.powered
                text: "検索中…"
                role: Typography.labelMedium
                color: Colors.m3OnSurfaceVariant
                Layout.leftMargin: 8
            }
            Item { Layout.fillWidth: true }
            Button {
                size: "s"
                variant: "tonal"
                visible: Wifi.powered
                text: "再検索"
                onClicked: Wifi.scan()
            }
            Switch {
                Layout.leftMargin: 4
                checked: Wifi.powered
                onToggled: Wifi.setPower(!Wifi.powered)
            }
        }

        Repeater {
            model: ScriptModel {
                values: Wifi.powered ? Wifi.networks : []
            }

            ColumnLayout {
                id: net
                required property var modelData    // { name, security, signal, connected, known }
                readonly property bool secured: modelData.security !== "open"
                readonly property bool asking: root.askingFor === modelData.name
                readonly property bool confirming: root.confirmingForget === modelData.name
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    visible: !net.confirming
                    Layout.fillWidth: true
                    spacing: 4

                    ChoiceRow {
                        Layout.fillWidth: true
                        icon: net.modelData.signal >= 4 ? "signal_wifi_4_bar" : net.modelData.signal >= 3 ? "network_wifi_3_bar"
                            : net.modelData.signal >= 2 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                        text: net.modelData.name + (Wifi.connecting === net.modelData.name ? "  接続中…" : "")
                        checked: net.modelData.connected
                        onClicked: {
                            if (net.modelData.connected) {
                                Wifi.disconnect();
                            } else if (net.secured && !net.modelData.known) {
                                root.askingFor = net.asking ? "" : net.modelData.name;
                            } else {
                                Wifi.connectTo(net.modelData.name, "");
                            }
                        }
                    }
                    Icon {
                        visible: net.secured
                        name: "lock"
                        size: 16
                        color: Colors.m3OnSurfaceVariant
                    }
                    IconButton {
                        visible: net.modelData.known
                        size: "s"
                        variant: "standard"
                        icon: "delete"
                        onClicked: root.confirmingForget = net.modelData.name
                    }
                }

                // パスワード入力
                RowLayout {
                    visible: net.asking
                    Layout.fillWidth: true
                    Layout.leftMargin: 12
                    spacing: 8
                    onVisibleChanged: if (visible) pass.forceActiveFocus()

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 44
                        radius: Shapes.medium
                        color: Colors.m3SurfaceContainerHighest

                        TextInput {
                            id: pass
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            color: Colors.m3OnSurface
                            selectionColor: Colors.m3Primary
                            selectedTextColor: Colors.m3OnPrimary
                            font.family: Typography.family
                            font.pixelSize: Typography.bodyLarge.size
                            clip: true
                            onAccepted: if (text !== "") { root.submit(net.modelData.name, text); text = ""; }
                            Keys.onEscapePressed: root.askingFor = ""
                        }
                        Label {
                            visible: pass.text === ""
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "パスワード"
                            role: Typography.bodyLarge
                            color: Colors.m3OnSurfaceVariant
                        }
                    }
                    Button {
                        size: "s"
                        variant: "filled"
                        text: "接続"
                        enabled: pass.text !== ""
                        onClicked: { root.submit(net.modelData.name, pass.text); pass.text = ""; }
                    }
                }

                // 保存済みの削除の確認
                Rectangle {
                    visible: net.confirming
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
                            text: "「" + net.modelData.name + "」の保存を削除しますか？"
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
                                Wifi.forget(net.modelData.name);
                            }
                        }
                    }
                }
            }
        }

        Label {
            visible: Wifi.error !== ""
            Layout.fillWidth: true
            Layout.leftMargin: 12
            text: Wifi.error
            role: Typography.bodySmall
            color: Colors.m3Error
            wrapMode: Text.Wrap
        }
        Label {
            visible: Wifi.powered && Wifi.networks.length === 0
            Layout.leftMargin: 12
            text: Wifi.scanning ? "探しています…" : "ネットワークが見つかりません"
            role: Typography.bodyMedium
            color: Colors.m3OnSurfaceVariant
        }
    }
}
