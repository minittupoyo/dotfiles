import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

PanelFrame {
    id: panel
    attachedToBar: true
    panelWidth: Theme.quickSettingsWidth
    panelHeight: Theme.quickSettingsHeight
    property var sink: null
    property var brightness: null
    property var notificationService: null
    property var playerService: null
    property bool captureActive: false
    property string error: ""
    property string message: ""
    property string tab: "quick"
    property var draft: ({})
    property int brightnessPreview: -1
    readonly property string cliDir: Quickshell.env("MATERIAL_SHELL_CLI_DIR") || ((Quickshell.env("HOME") || "") + "/.local/bin")
    signal panelRequested(string name)

    PwObjectTracker { objects: panel.visible ? panel.devices : [] }
    readonly property var tabs: [
        {name:"quick",label:"クイック",icon:"apps"},
        {name:"network",label:"接続",icon:"wifi"},
        {name:"audio",label:"音声",icon:"volume_up"},
        {name:"media",label:"メディア",icon:"music_note"},
        {name:"notifications",label:"通知",icon:"notifications"},
        {name:"settings",label:"設定",icon:"settings"},
        {name:"clipboard",label:"履歴",icon:"content_paste"},
        {name:"capture",label:"撮影",icon:"screenshot_monitor"}
    ]
    readonly property string tabTitle: tabs.find(item => item.name === tab)?.label ?? "コントロール"
    readonly property var devices: Pipewire.nodes.values.filter(node => node.audio && !node.isStream)
    readonly property var output: Pipewire.defaultAudioSink
    readonly property var input: Pipewire.defaultAudioSource
    onVisibleChanged: if (visible) { error = ""; brightnessPreview = -1; if (tab === "settings") draft = Object.assign({}, Settings.values); }
    onTabChanged: { error = ""; message = ""; if (tab === "settings") draft = Object.assign({}, Settings.values); }
    function selectTab(name) {
        if (name === "display") name = "quick";
        if (tabs.some(item => item.name === name)) tab = name;
    }
    function brightnessIcon() {
        const level = brightnessPreview >= 0 ? brightnessPreview : Number(brightness ?? 0);
        return level <= 25 ? "brightness_low" : level <= 70 ? "brightness_medium" : "brightness_high";
    }
    function volumeIcon() {
        if (!sink?.audio || sink.audio.muted || sink.audio.volume <= 0.01) return "volume_off";
        return sink.audio.volume <= 0.5 ? "volume_down" : "volume_up";
    }
    Connections {
        target: Settings
        function onSavingChanged() { if (!Settings.saving && !Settings.error) panel.message = "設定を保存しました"; }
    }

    Process {
        id: brightnessWorker
        stdout: SplitParser {}
        stderr: SplitParser { onRead: data => panel.error = data.trim() }
        onExited: (code, status) => {
            if (code !== 0) panel.error = panel.error || "明るさを変更できませんでした";
            brightnessPreviewReset.restart();
        }
    }
    Timer {
        id: brightnessApply
        interval: 120
        onTriggered: {
            if (panel.brightnessPreview < 0 || brightnessWorker.running) return;
            brightnessWorker.command = [panel.cliDir + "/material-display", "set", String(panel.brightnessPreview)];
            brightnessWorker.running = true;
        }
    }
    Timer { id: brightnessPreviewReset; interval: 1800; onTriggered: panel.brightnessPreview = -1 }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space12
        PanelHeader { Layout.fillWidth: true; title: panel.tabTitle; onDismissed: panel.dismissed() }
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.space12
            Flickable {
                id: tabRailScroll
                Layout.preferredWidth: Theme.quickTabWidth
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: tabRail.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: tabRail
                    width: parent.width
                    spacing: Theme.space4
                    Repeater {
                        model: panel.tabs
                        ControlTab { required property var modelData; name: modelData.name; label: modelData.label; icon: modelData.icon; selected: panel.tab === modelData.name; onChosen: name => panel.selectTab(name) }
                    }
                }
            }
            Flickable {
                id: bodyScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: body.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: body
                    width: parent.width
                    height: Math.max(implicitHeight, bodyScroll.height)
                    spacing: Theme.space16
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: panel.tab === "quick"
                    visible: panel.tab === "quick"
                    columns: 2
                    rowSpacing: Theme.space8
                    columnSpacing: Theme.space8
                    ControlTile {
                        Layout.fillHeight: panel.tab === "quick"
                        visible: panel.tab === "quick"
                        title: Settings.values.dnd ? "通知を一時停止中" : "通知を受け取る"
                        icon: Settings.values.dnd ? "notifications_off" : "notifications"
                        checked: Settings.values.dnd
                        onToggled: Settings.save(Object.assign({}, Settings.values, {dnd: !Settings.values.dnd}))
                    }
                    ControlTile {
                        Layout.fillHeight: panel.tab === "quick"
                        visible: panel.tab === "quick"
                        title: "壁紙と配色を選ぶ"
                        icon: "wallpaper"
                        onToggled: panel.panelRequested("wallpaper")
                    }
                    ControlTile {
                        Layout.fillHeight: panel.tab === "quick"
                        visible: panel.tab === "quick"
                        title: "ネットワーク接続"
                        icon: "wifi"
                        onToggled: panel.selectTab("network")
                    }
                    ControlTile {
                        Layout.fillHeight: panel.tab === "quick"
                        visible: panel.tab === "quick"
                        title: "音声デバイス"
                        icon: "volume_up"
                        onToggled: panel.selectTab("audio")
                    }
                }

                ControlNetwork {
                    Layout.fillWidth: true
                    Layout.fillHeight: panel.tab === "network"
                    visible: panel.tab === "network"
                    active: panel.visible && panel.tab === "network"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: panel.tab === "quick"
                    spacing: Theme.space4
                    RowLayout {
                        Layout.fillWidth: true
                        MaterialIcon { name: panel.volumeIcon() }
                        Text { Layout.fillWidth: true; text: "音量"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; font.weight: Font.Medium }
                        Text { text: panel.sink?.audio ? Math.round(panel.sink.audio.volume * 100) + "%" : "—"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        VolumeSlider {
                            Layout.fillWidth: true
                            enabled: !!panel.sink?.ready
                            value: panel.sink?.audio?.volume ?? 0
                            Accessible.name: "音量"
                            onAdjusted: value => { if (panel.sink?.audio) panel.sink.audio.volume = value; }
                        }
                        ShellButton {
                            text: panel.sink?.audio?.muted ? "解除" : "ミュート"
                            icon: panel.sink?.audio?.muted ? "volume_off" : "volume_mute"
                            enabled: !!panel.sink?.ready
                            Accessible.name: panel.sink?.audio?.muted ? "ミュート解除" : "ミュート"
                            onClicked: panel.sink.audio.muted = !panel.sink.audio.muted
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: panel.tab === "quick" && panel.brightness !== null
                    spacing: Theme.space4
                    RowLayout {
                        Layout.fillWidth: true
                        MaterialIcon { name: panel.brightnessIcon() }
                        Text { Layout.fillWidth: true; text: "明るさ"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; font.weight: Font.Medium }
                        Text { text: (panel.brightnessPreview >= 0 ? panel.brightnessPreview : panel.brightness) + "%"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                    }
                    VolumeSlider {
                        Layout.fillWidth: true
                        value: Math.max(0, panel.brightnessPreview >= 0 ? panel.brightnessPreview : panel.brightness ?? 0) / 100
                        Accessible.name: "画面の明るさ"
                        onAdjusted: value => { panel.error = ""; panel.brightnessPreview = Math.round(value * 100); brightnessPreviewReset.stop(); brightnessApply.restart(); }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: panel.tab === "audio"
                    spacing: Theme.space24
                    Repeater {
                        model: [true, false]
                        delegate: ColumnLayout {
                            id: section
                            required property bool modelData
                            readonly property var node: modelData ? panel.output : panel.input
                            Layout.fillWidth: true
                            spacing: Theme.space8
                            Text { text: section.modelData ? "出力" : "マイク入力"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.inputSize; font.weight: Font.Medium }
                            Text { Layout.fillWidth: true; text: section.node ? (section.node.description || section.node.name) : "利用できるデバイスがありません"; textFormat: Text.PlainText; wrapMode: Text.WrapAnywhere; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                            RowLayout {
                                Layout.fillWidth: true
                                VolumeSlider { Layout.fillWidth: true; enabled: !!section.node?.ready; value: section.node?.audio?.volume ?? 0; Accessible.name: section.modelData ? "出力音量" : "マイク音量"; onAdjusted: value => { if (section.node?.audio) section.node.audio.volume = value; } }
                                ShellButton { text: section.node?.audio?.muted ? "解除" : "ミュート"; icon: section.node?.audio?.muted ? "volume_off" : "volume_mute"; enabled: !!section.node?.ready; onClicked: section.node.audio.muted = !section.node.audio.muted }
                            }
                            Repeater {
                                model: panel.devices.filter(node => node.isSink === section.modelData)
                                delegate: ControlTile {
                                    required property var modelData
                                    title: modelData.description || modelData.name
                                    icon: section.modelData ? "volume_up" : "volume_mute"
                                    checked: modelData === section.node
                                    onToggled: { if (section.modelData) Pipewire.preferredDefaultAudioSink = modelData; else Pipewire.preferredDefaultAudioSource = modelData; }
                                }
                            }
                        }
                    }
                    ShellButton { Layout.fillWidth: true; text: "再生中のメディア"; icon: "music_note"; onClicked: panel.panelRequested("media") }
                }

                ControlMedia {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 500
                    visible: panel.tab === "media"
                    service: panel.playerService
                    active: panel.visible && panel.tab === "media"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: panel.tab === "notifications"
                    spacing: Theme.space8
                    RowLayout {
                        Layout.fillWidth: true
                        Text { Layout.fillWidth: true; text: "通知を一時停止"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                        Toggle { checked: Settings.values.dnd; Accessible.name: "通知を一時停止"; onToggled: Settings.save(Object.assign({}, Settings.values, {dnd: !checked})) }
                    }
                    ListView {
                        id: notificationList
                        Layout.fillWidth: true
                        Layout.preferredHeight: 440
                        model: panel.notificationService?.history ?? []
                        spacing: Theme.space8
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        delegate: Rectangle {
                            id: notificationRow
                            required property var modelData
                            readonly property var activeNotification: panel.notificationService?.activeNotification(modelData) ?? null
                            width: notificationList.width
                            height: notificationContent.implicitHeight + Theme.space16 * 2
                            radius: Theme.shapeMedium
                            color: Theme.surfaceContainerHigh
                            ColumnLayout {
                                id: notificationContent
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                                anchors.margins: Theme.space12
                                spacing: Theme.space8
                                RowLayout {
                                    Layout.fillWidth: true
                                    Text { Layout.fillWidth: true; text: notificationRow.modelData.app; textFormat: Text.PlainText; elide: Text.ElideRight; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
                                    Text { text: Qt.formatDateTime(new Date(notificationRow.modelData.timestamp), "MM/dd HH:mm"); color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
                                }
                                Text { Layout.fillWidth: true; text: notificationRow.modelData.summary; textFormat: Text.PlainText; wrapMode: Text.Wrap; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize; font.weight: Font.Medium }
                                Text { Layout.fillWidth: true; visible: text !== ""; text: notificationRow.modelData.body; textFormat: Text.PlainText; wrapMode: Text.Wrap; maximumLineCount: 5; elide: Text.ElideRight; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: Theme.space4
                                    Repeater { model: notificationRow.activeNotification?.actions ?? []; delegate: ShellButton { required property var modelData; text: modelData.text; onClicked: modelData.invoke() } }
                                    ShellButton { visible: !!notificationRow.activeNotification; text: "閉じる"; onClicked: notificationRow.activeNotification?.dismiss() }
                                }
                            }
                        }
                        Text { anchors.centerIn: parent; visible: notificationList.count === 0; text: "通知はありません"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                    }
                    ShellButton { Layout.alignment: Qt.AlignRight; text: "履歴を消去"; destructive: true; enabled: (panel.notificationService?.history.length ?? 0) > 0; onClicked: panel.notificationService?.clearHistory() }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: panel.tab === "settings"
                    spacing: Theme.space8
                    Repeater {
                        model: [{key:"showCpu",label:"CPU使用率"},{key:"showMemory",label:"メモリ使用率"},{key:"showNetwork",label:"ネットワーク"},{key:"showWindowTitle",label:"ウィンドウ名"},{key:"showTray",label:"システムトレイ"},{key:"osd",label:"音量・明るさのOSD"},{key:"dnd",label:"通知を一時停止"}]
                        delegate: RowLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: Theme.buttonHeight
                            Text { Layout.fillWidth: true; text: parent.modelData.label; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                            Toggle { checked: panel.draft[parent.modelData.key] ?? false; Accessible.name: parent.modelData.label; enabled: !Settings.saving; onToggled: { const next = Object.assign({}, panel.draft); next[parent.modelData.key] = !checked; panel.draft = next; } }
                        }
                    }
                    Repeater {
                        model: [{key:"workspaces",label:"ワークスペース数",min:1,max:10,step:1},{key:"autoLockMinutes",label:"自動ロック（分）",min:0,max:240,step:5},{key:"screenOffMinutes",label:"自動消灯（分）",min:0,max:240,step:5}]
                        delegate: RowLayout {
                            id: numberSetting
                            required property var modelData
                            Layout.fillWidth: true
                            Text { Layout.fillWidth: true; text: numberSetting.modelData.label; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                            ShellButton { text: "−"; enabled: !Settings.saving && panel.draft[numberSetting.modelData.key] > numberSetting.modelData.min; onClicked: { const next = Object.assign({}, panel.draft); next[numberSetting.modelData.key] = Math.max(numberSetting.modelData.min, next[numberSetting.modelData.key] - numberSetting.modelData.step); panel.draft = next; } }
                            Text { text: panel.draft[numberSetting.modelData.key] === 0 ? "無効" : String(panel.draft[numberSetting.modelData.key] ?? ""); color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                            ShellButton { text: "+"; enabled: !Settings.saving && panel.draft[numberSetting.modelData.key] < numberSetting.modelData.max; onClicked: { const next = Object.assign({}, panel.draft); next[numberSetting.modelData.key] = Math.min(numberSetting.modelData.max, next[numberSetting.modelData.key] + numberSetting.modelData.step); panel.draft = next; } }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Item { Layout.fillWidth: true }
                        ShellButton { text: "戻す"; enabled: !Settings.saving; onClicked: { panel.draft = Object.assign({}, Settings.values); panel.message = ""; } }
                        ShellButton { text: Settings.saving ? "保存中…" : "保存"; emphasized: true; enabled: !Settings.saving; onClicked: Settings.save(panel.draft) }
                    }
                    Text { Layout.fillWidth: true; visible: panel.message !== "" || Settings.error !== ""; text: Settings.error || panel.message; color: Settings.error ? Theme.error : Theme.surfaceVariantText; wrapMode: Text.Wrap; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
                }

                ControlClipboard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 500
                    visible: panel.tab === "clipboard"
                    active: panel.visible && panel.tab === "clipboard"
                }
                ControlCapture {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 360
                    visible: panel.tab === "capture"
                    busy: panel.captureActive
                    message: panel.message
                    onCaptureRequested: mode => panel.panelRequested("capture:" + mode)
                    onCancelRequested: panel.panelRequested("cancel-capture")
                }
                }
            }
        }
        Text { Layout.fillWidth: true; visible: panel.error !== ""; text: panel.error; color: Theme.error; wrapMode: Text.Wrap; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
        RowLayout {
            Layout.fillWidth: true
            visible: panel.tab === "quick"
            ShellButton { Layout.fillWidth: true; text: "通知"; icon: "notifications"; onClicked: panel.selectTab("notifications") }
            ShellButton { Layout.fillWidth: true; text: "すべての設定"; icon: "settings"; onClicked: panel.selectTab("settings") }
        }
    }
}
