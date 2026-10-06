import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: page
    property bool active: false
    property string error: ""
    property string message: ""
    property string operation: ""
    property string selectedWifiSsid: ""
    property string pendingWifiSsid: ""
    property string pendingSecret: ""
    property bool revealPassword: false
    readonly property bool busy: worker.running
    property var state: ({wifi:null, wifiAvailable:false, wifiConnected:"", wifiNetworks:[], bluetooth:null, bluetoothAvailable:false, bluetoothDevices:[]})
    readonly property string cliDir: Quickshell.env("MATERIAL_SHELL_CLI_DIR") || ((Quickshell.env("HOME") || "") + "/.local/bin")
    implicitHeight: content.implicitHeight
    function run(args, actionName, secret) {
        if (worker.running) return;
        error = "";
        message = "";
        operation = actionName;
        pendingSecret = secret || "";
        worker.command = [cliDir + "/material-control", ...args];
        worker.running = true;
    }
    function refresh() { run(["status"], "status", ""); }
    function scanWifi() { run(["scan-wifi"], "scan-wifi", ""); }
    function scanBluetooth() { run(["scan-bluetooth"], "scan-bluetooth", ""); }
    function toggleRadio(name) { run(["toggle", name], "toggle-" + name, ""); }
    function connectWifi(network, password) {
        pendingWifiSsid = network.ssid;
        const args = ["wifi-connect", network.ssid];
        if (network.savedConnection) args.push(network.savedConnection);
        if (password) args.push("--password-stdin");
        run(args, "wifi-connect", password);
    }
    function connectBluetooth(device) {
        run([device.paired ? "bluetooth-connect" : "bluetooth-pair", device.address], device.paired ? "bluetooth-connect" : "bluetooth-pair", "");
    }
    function forgetBluetooth(device) { run(["bluetooth-remove", device.address], "bluetooth-remove", ""); }
    onActiveChanged: if (active) refresh()
    onSelectedWifiSsidChanged: if (selectedWifiSsid !== "") Qt.callLater(() => passwordInput.forceActiveFocus())
    Process {
        id: worker
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => {
                try { page.state = JSON.parse(data); }
                catch (error) { page.error = "接続状態を読み込めません"; }
            }
        }
        stderr: SplitParser { onRead: data => page.error = data.trim() }
        onStarted: if (page.pendingSecret !== "") { write(page.pendingSecret + "\n"); page.pendingSecret = ""; }
        onExited: (code, status) => {
            const completed = page.operation;
            page.pendingSecret = "";
            if (code !== 0) {
                if (!page.error) page.error = "操作に失敗しました。設定を確認してもう一度お試しください。";
                if (completed === "wifi-connect") page.selectedWifiSsid = page.pendingWifiSsid;
                return;
            }
            if (completed === "scan-wifi") page.message = "Wi-Fiネットワークを更新しました";
            else if (completed === "scan-bluetooth") page.message = "Bluetooth機器の検索が完了しました";
            else if (completed === "wifi-connect") { page.message = "Wi-Fiへの接続を開始しました"; page.selectedWifiSsid = ""; }
            else if (completed === "wifi-disconnect") page.message = "Wi-Fiを切断しました";
            else if (completed === "bluetooth-connect") page.message = "Bluetooth機器に接続しました";
            else if (completed === "bluetooth-pair") page.message = "Bluetooth機器をペア設定しました";
            else if (completed === "bluetooth-disconnect") page.message = "Bluetooth機器を切断しました";
            else if (completed === "bluetooth-remove") page.message = "ペア設定を解除しました";
            if (completed !== "status") settleRefresh.restart();
        }
    }
    Timer { interval: 30000; repeat: true; running: page.active; onTriggered: page.refresh() }
    Timer { id: settleRefresh; interval: 1200; onTriggered: page.refresh() }

    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: Theme.space4

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.inputHeight
            spacing: Theme.space8
            MaterialIcon { name: "wifi"; size: Theme.quickSettingIconSize; color: Theme.primary }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: "Wi-Fi"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.titleMediumSize; font.weight: Font.Medium }
                Text {
                    Layout.fillWidth: true
                    text: !page.state.wifiAvailable ? "利用できません" : !page.state.wifi ? "オフ" : page.state.wifiConnected ? "接続中 · " + page.state.wifiConnected : "ネットワークを選択してください"
                    color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize; elide: Text.ElideRight
                }
            }
            ShellButton { objectName: "wifiScan"; text: worker.running && page.operation === "scan-wifi" ? "検索中" : "更新"; icon: "search"; enabled: page.state.wifiAvailable && page.state.wifi && !worker.running; Accessible.name: "Wi-Fiネットワークを検索"; onClicked: page.scanWifi() }
            Toggle { objectName: "wifiToggle"; checked: page.state.wifi === true; enabled: page.state.wifiAvailable && !worker.running; Accessible.name: "Wi-Fi"; onToggled: page.toggleRadio("wifi") }
        }

        ListView {
            id: wifiList
            objectName: "wifiNetworks"
            Layout.fillWidth: true
            Layout.fillHeight: visible
            Layout.preferredHeight: Math.min(contentHeight, Theme.listRowHeight * 2 + Theme.space4)
            Layout.maximumHeight: contentHeight
            visible: page.state.wifiAvailable && page.state.wifi && count > 0
            clip: true
            spacing: Theme.space4
            boundsBehavior: Flickable.StopAtBounds
            model: page.state.wifiNetworks || []
            delegate: Rectangle {
                id: wifiRow
                required property var modelData
                width: wifiList.width
                height: Theme.listRowHeight
                radius: Theme.shapeSmall
                color: modelData.connected ? Theme.secondaryContainer : Theme.surfaceContainerHigh
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space12
                    anchors.rightMargin: Theme.space8
                    spacing: Theme.space8
                    MaterialIcon { name: modelData.connected ? "wifi" : modelData.secured ? "lock" : "wifi"; color: modelData.connected ? Theme.secondaryContainerText : Theme.surfaceVariantText }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { Layout.fillWidth: true; text: wifiRow.modelData.ssid; color: wifiRow.modelData.connected ? Theme.secondaryContainerText : Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; font.weight: Font.Medium; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: (wifiRow.modelData.connected ? "接続済み · " : "") + (wifiRow.modelData.secured ? wifiRow.modelData.security : "オープン") + " · " + wifiRow.modelData.signal + "%"; color: wifiRow.modelData.connected ? Theme.secondaryContainerText : Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize; elide: Text.ElideRight }
                    }
                    ShellButton {
                        objectName: "wifiConnectButton"
                        text: wifiRow.modelData.connected ? "切断" : "接続"
                        enabled: !worker.running
                        onClicked: {
                            if (wifiRow.modelData.connected) page.run(["wifi-disconnect"], "wifi-disconnect", "");
                            else if (wifiRow.modelData.savedConnection || !wifiRow.modelData.secured) page.connectWifi(wifiRow.modelData, "");
                            else { page.selectedWifiSsid = wifiRow.modelData.ssid; page.revealPassword = false; }
                        }
                    }
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.listRowHeight
            visible: !page.state.wifiAvailable || !page.state.wifi
            radius: Theme.shapeSmall
            color: Theme.surfaceContainerHigh
            RowLayout {
                anchors.fill: parent; anchors.margins: Theme.space12; spacing: Theme.space8
                MaterialIcon { name: "wifi_off"; color: Theme.surfaceVariantText }
                Text {
                    Layout.fillWidth: true
                    text: !page.state.wifiAvailable ? "この端末ではWi-Fiアダプターを利用できません。" : "Wi-Fiをオンにすると、周辺のネットワークが表示されます。"
                    color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; wrapMode: Text.Wrap
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.listRowHeight
            visible: page.state.wifiAvailable && page.state.wifi && wifiList.count === 0 && !worker.running
            radius: Theme.shapeSmall
            color: Theme.surfaceContainerHigh
            RowLayout {
                anchors.fill: parent; anchors.margins: Theme.space12; spacing: Theme.space8
                MaterialIcon { name: "wifi_off"; color: Theme.surfaceVariantText }
                Text { Layout.fillWidth: true; text: "ネットワークが見つかりません。検索をお試しください。"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; wrapMode: Text.Wrap }
            }
        }
        RowLayout {
            objectName: "wifiPasswordPrompt"
            Layout.fillWidth: true
            visible: page.selectedWifiSsid !== ""
            spacing: Theme.space8
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.inputHeight
                radius: Theme.inputRadius
                color: Theme.inputBackground
                border.width: passwordInput.activeFocus ? 1 : 0
                border.color: Theme.primary
                TextInput {
                    id: passwordInput
                    objectName: "wifiPasswordInput"
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space12
                    anchors.rightMargin: Theme.space4
                    verticalAlignment: TextInput.AlignVCenter
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.bodySize
                    color: Theme.surfaceText
                    echoMode: page.revealPassword ? TextInput.Normal : TextInput.Password
                    inputMethodHints: Qt.ImhSensitiveData
                    Accessible.name: page.selectedWifiSsid + "のWi-Fiパスワード"
                    onAccepted: if (text !== "") { page.connectWifi(selectedNetwork(), text); text = ""; }
                    function selectedNetwork() { return (page.state.wifiNetworks || []).find(item => item.ssid === page.selectedWifiSsid) || {ssid:page.selectedWifiSsid,secured:true}; }
                }
                Text { anchors.left: parent.left; anchors.right: parent.right; anchors.leftMargin: Theme.space12; anchors.rightMargin: Theme.space12; anchors.verticalCenter: parent.verticalCenter; visible: !passwordInput.activeFocus && passwordInput.text === ""; text: "「" + page.selectedWifiSsid + "」のパスワード"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; elide: Text.ElideRight }
            }
            ShellButton { text: page.revealPassword ? "隠す" : "表示"; Accessible.name: page.revealPassword ? "パスワードを隠す" : "パスワードを表示"; onClicked: page.revealPassword = !page.revealPassword }
            ShellButton { text: "取消"; enabled: !worker.running; onClicked: { page.selectedWifiSsid = ""; passwordInput.text = ""; } }
            ShellButton {
                text: "接続"; emphasized: true; enabled: passwordInput.text !== "" && !worker.running
                onClicked: { page.connectWifi(passwordInput.selectedNetwork(), passwordInput.text); passwordInput.text = ""; }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: Theme.outlineVariant }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.inputHeight
            spacing: Theme.space8
            MaterialIcon { name: "bluetooth"; size: Theme.quickSettingIconSize; color: Theme.primary }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: "Bluetooth"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.titleMediumSize; font.weight: Font.Medium }
                Text {
                    Layout.fillWidth: true
                    text: !page.state.bluetoothAvailable ? "利用できません" : page.state.bluetooth ? page.state.bluetoothDevices.filter(device => device.connected).length ? "接続中 · " + page.state.bluetoothDevices.filter(device => device.connected).map(device => device.name).join("、") : "オン" : "オフ"
                    color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize; elide: Text.ElideRight
                }
            }
            ShellButton { objectName: "bluetoothScan"; text: worker.running && page.operation === "scan-bluetooth" ? "検索中" : "検索"; icon: "search"; enabled: page.state.bluetoothAvailable && page.state.bluetooth && !worker.running; Accessible.name: "Bluetooth機器を検索"; onClicked: page.scanBluetooth() }
            Toggle { objectName: "bluetoothToggle"; checked: page.state.bluetooth === true; enabled: page.state.bluetoothAvailable && !worker.running; Accessible.name: "Bluetooth"; onToggled: page.toggleRadio("bluetooth") }
        }

        ListView {
            id: bluetoothList
            objectName: "bluetoothDevices"
            Layout.fillWidth: true
            Layout.fillHeight: visible
            Layout.preferredHeight: Math.min(contentHeight, Theme.listRowHeight * 2 + Theme.space4)
            Layout.maximumHeight: contentHeight
            visible: page.state.bluetooth && count > 0
            clip: true
            spacing: Theme.space4
            boundsBehavior: Flickable.StopAtBounds
            model: page.state.bluetoothDevices || []
            delegate: Rectangle {
                id: bluetoothRow
                required property var modelData
                width: bluetoothList.width
                height: Theme.listRowHeight
                radius: Theme.shapeSmall
                color: modelData.connected ? Theme.secondaryContainer : Theme.surfaceContainerHigh
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.space12
                    anchors.rightMargin: Theme.space8
                    spacing: Theme.space8
                    MaterialIcon { name: "bluetooth"; color: bluetoothRow.modelData.connected ? Theme.secondaryContainerText : Theme.surfaceVariantText }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text { Layout.fillWidth: true; text: bluetoothRow.modelData.name; color: bluetoothRow.modelData.connected ? Theme.secondaryContainerText : Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; font.weight: Font.Medium; elide: Text.ElideRight }
                        Text { Layout.fillWidth: true; text: bluetoothRow.modelData.connected ? "接続済み" : bluetoothRow.modelData.paired ? "ペア設定済み" : bluetoothRow.modelData.address; color: bluetoothRow.modelData.connected ? Theme.secondaryContainerText : Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize; elide: Text.ElideRight }
                    }
                    ShellButton {
                        objectName: "bluetoothConnectButton"
                        text: bluetoothRow.modelData.connected ? "切断" : bluetoothRow.modelData.paired ? "接続" : "ペア設定"
                        enabled: bluetoothRow.modelData.available && !worker.running
                        onClicked: bluetoothRow.modelData.connected ? page.run(["bluetooth-disconnect", bluetoothRow.modelData.address], "bluetooth-disconnect", "") : page.connectBluetooth(bluetoothRow.modelData)
                    }
                    ShellButton {
                        objectName: "bluetoothRemoveButton"
                        visible: bluetoothRow.modelData.paired
                        text: "解除"
                        Accessible.name: bluetoothRow.modelData.name + "のペア設定を解除"
                        enabled: bluetoothRow.modelData.available && !worker.running
                        onClicked: page.forgetBluetooth(bluetoothRow.modelData)
                    }
                }
            }
        }
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Theme.listRowHeight
            visible: !page.state.bluetoothAvailable || !page.state.bluetooth || (bluetoothList.count === 0 && !worker.running)
            radius: Theme.shapeSmall
            color: Theme.surfaceContainerHigh
            RowLayout {
                anchors.fill: parent; anchors.margins: Theme.space12; spacing: Theme.space8
                MaterialIcon { name: "bluetooth"; color: Theme.surfaceVariantText }
                Text {
                    Layout.fillWidth: true
                    text: !page.state.bluetoothAvailable ? "この端末ではBluetoothアダプターを利用できません。" : !page.state.bluetooth ? "Bluetoothをオンにすると、ペア設定済みの機器を表示できます。" : "登録済みの機器はありません。検索して近くの機器を追加できます。"
                    color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; wrapMode: Text.Wrap
                }
            }
        }
        Text {
            Layout.fillWidth: true
            visible: page.error !== "" || page.message !== ""
            text: page.error || page.message
            color: page.error ? Theme.error : Theme.surfaceVariantText
            font.family: Theme.fontFamily
            font.pixelSize: Theme.labelSize
            wrapMode: Text.Wrap
        }
    }
}
