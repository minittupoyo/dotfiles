import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../../components"
import "../../services"
import "../../tokens"

// クイック設定の中身。このデスクトップ機 (バッテリー・輝度なし、有線) に合わせた構成:
//   タイル (Bluetooth / おやすみ / スリープ抑止) → 音量・マイク → メディア → 通知の履歴 → 電源
Item {
    id: root

    signal closeRequested()

    implicitHeight: col.implicitHeight
    focus: true

    // 再起動・シャットダウンの確認中か ("" | "reboot" | "poweroff")
    property string confirming: ""
    property bool devicesOpen: false

    function open() {
        confirming = "";
        devicesOpen = false;
        forceActiveFocus();
    }

    Keys.onEscapePressed: closeRequested()

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevices: adapter ? adapter.devices.values.filter(d => d.paired) : []

    function volIcon(vol, muted) {
        return muted ? "volume_off" : vol <= 0 ? "volume_mute" : vol < 0.5 ? "volume_down" : "volume_up";
    }

    ColumnLayout {
        id: col
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 16

        // ---- タイル ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ToggleTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                visible: root.adapter !== null
                icon: "bluetooth"
                text: "Bluetooth"
                checked: root.adapter !== null && root.adapter.enabled
                onClicked: root.adapter.enabled = !root.adapter.enabled
            }
            ToggleTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: Notifications.dnd ? "notifications_off" : "notifications"
                text: "おやすみ"
                checked: Notifications.dnd
                onClicked: Notifications.setDnd(!Notifications.dnd)
            }
            ToggleTile {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                icon: "coffee"
                text: "スリープ抑止"
                checked: IdleInhibit.active
                onClicked: IdleInhibit.toggle()
            }
        }

        // ---- Bluetooth のペア済みデバイス ----
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.adapter !== null && root.adapter.enabled && root.btDevices.length > 0

            Repeater {
                model: ScriptModel {
                    values: root.btDevices
                }

                BaseButton {
                    id: dev
                    required property var modelData    // BluetoothDevice
                    Layout.fillWidth: true
                    implicitHeight: 44
                    variant: "standard"
                    checkable: true
                    autoToggle: false
                    checked: modelData.connected
                    squareRadius: Shapes.medium
                    onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12
                        Icon { name: "bluetooth"; size: 20; fill: dev.checkProgress; color: dev.contentColor }
                        Label {
                            Layout.fillWidth: true
                            text: dev.modelData.name
                            role: Typography.labelLarge
                            color: Colors.m3OnSurface
                            elide: Text.ElideRight
                        }
                        Label {
                            visible: dev.modelData.batteryAvailable
                            text: Math.round(dev.modelData.battery * 100) + "%"
                            role: Typography.labelMedium
                            color: Colors.m3OnSurfaceVariant
                        }
                        Label {
                            text: dev.modelData.connected ? "接続中" : "未接続"
                            role: Typography.labelMedium
                            color: dev.contentColor
                        }
                    }
                }
            }
        }

        // ---- 出力 (音量) ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            IconButton {
                size: "s"
                variant: "standard"
                icon: root.volIcon(Audio.volume, Audio.muted)
                onClicked: Audio.toggleMute()
            }
            Slider {
                Layout.fillWidth: true
                value: Audio.volume
                onMoved: v => Audio.setVolume(v)
            }
            Label {
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
                text: Math.round(Audio.volume * 100) + "%"
                role: Typography.labelLarge
                color: Audio.muted ? Colors.m3Outline : Colors.m3OnSurfaceVariant
            }
        }

        // 出力デバイスの切り替え (展開して選ぶ)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: Audio.sinks.length > 0

            BaseButton {
                Layout.fillWidth: true
                implicitHeight: 40
                variant: "standard"
                onClicked: root.devicesOpen = !root.devicesOpen

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8
                    Icon { name: "speaker"; size: 20; color: Colors.m3OnSurfaceVariant }
                    Label {
                        Layout.fillWidth: true
                        text: Audio.sinkLabel(Audio.sink) || "出力デバイス"
                        role: Typography.labelLarge
                        color: Colors.m3OnSurface
                        elide: Text.ElideRight
                    }
                    Icon { name: root.devicesOpen ? "expand_less" : "expand_more"; size: 20; color: Colors.m3OnSurfaceVariant }
                }
            }

            Repeater {
                model: ScriptModel {
                    values: root.devicesOpen ? Audio.sinks : []
                }

                BaseButton {
                    id: sinkBtn
                    required property var modelData    // PwNode
                    Layout.fillWidth: true
                    implicitHeight: 40
                    variant: "standard"
                    checkable: true
                    autoToggle: false
                    checked: Audio.sink !== null && modelData.id === Audio.sink.id
                    onClicked: Audio.setDefaultSink(modelData)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 28
                        anchors.rightMargin: 12
                        spacing: 8
                        Label {
                            Layout.fillWidth: true
                            text: Audio.sinkLabel(sinkBtn.modelData)
                            role: Typography.bodyMedium
                            color: sinkBtn.contentColor
                            elide: Text.ElideRight
                        }
                        Icon { visible: sinkBtn.checked; name: "check"; size: 20; color: sinkBtn.contentColor }
                    }
                }
            }
        }

        // ---- 入力 (マイク) ----
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: Audio.sourceReady

            IconButton {
                size: "s"
                variant: "standard"
                icon: Audio.sourceMuted ? "mic_off" : "mic"
                onClicked: Audio.toggleSourceMute()
            }
            Slider {
                Layout.fillWidth: true
                value: Audio.sourceVolume
                onMoved: v => Audio.setSourceVolume(v)
            }
            Label {
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
                text: Math.round(Audio.sourceVolume * 100) + "%"
                role: Typography.labelLarge
                color: Audio.sourceMuted ? Colors.m3Outline : Colors.m3OnSurfaceVariant
            }
        }

        // ---- メディア (再生中のプレーヤーがあるときだけ) ----
        MediaCard {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
        }

        // ---- 通知の履歴 ----
        RowLayout {
            Layout.fillWidth: true

            Label {
                text: "通知"
                role: Typography.titleMedium
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
            Layout.preferredHeight: Notifications.count === 0 ? 56 : Math.min(contentHeight, 320)
            clip: true
            spacing: 8
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            // 新しいものを上に
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

        // ---- 電源 ----
        RowLayout {
            Layout.fillWidth: true
            visible: root.confirming === ""
            spacing: 8

            Item { Layout.fillWidth: true }
            IconButton {
                size: "m"
                variant: "tonal"
                icon: "lock"
                onClicked: {
                    root.closeRequested();
                    Lock.lock();
                }
            }
            IconButton {
                size: "m"
                variant: "tonal"
                icon: "bedtime"
                onClicked: {
                    Power.run("suspend");
                    root.closeRequested();
                }
            }
            IconButton {
                size: "m"
                variant: "tonal"
                icon: "restart_alt"
                onClicked: root.confirming = "reboot"
            }
            IconButton {
                size: "m"
                variant: "tonal"
                icon: "power_settings_new"
                onClicked: root.confirming = "poweroff"
            }
            Item { Layout.fillWidth: true }
        }

        // 再起動・シャットダウンの確認
        Rectangle {
            Layout.fillWidth: true
            visible: root.confirming !== ""
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
                    text: root.confirming === "reboot" ? "再起動しますか？" : "シャットダウンしますか？"
                    role: Typography.titleSmall
                    color: Colors.m3OnErrorContainer
                }
                Button {
                    size: "s"
                    variant: "text"
                    text: "キャンセル"
                    onClicked: root.confirming = ""
                }
                Button {
                    size: "s"
                    variant: "filled"
                    text: root.confirming === "reboot" ? "再起動" : "シャットダウン"
                    onClicked: {
                        const action = root.confirming;
                        root.confirming = "";
                        Power.run(action);
                        root.closeRequested();
                    }
                }
            }
        }
    }
}
