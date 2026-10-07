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
    signal messageRequested(string text, bool failed)

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
    readonly property string tabIcon: tabs.find(item => item.name === tab)?.icon ?? "apps"
    readonly property string tabDescription: ({quick:"よく使う操作をまとめて", network:"Wi-FiとBluetoothの接続を管理", audio:"出力・マイクとデバイスを調整", media:"再生中のメディアを操作", notifications:"受け取った通知を確認", settings:"シェルの表示と動作をカスタマイズ", clipboard:"コピーしたテキストと画像", capture:"画面を撮影して保存・コピー"})[tab] || ""
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
        function onSavingChanged() {
            if (!Settings.saving) {
                if (Settings.error) {
                    panel.messageRequested(Settings.error, true);
                } else {
                    panel.message = "設定を保存しました";
                    panel.messageRequested(panel.message, false);
                }
            }
        }
    }

    Process {
        id: brightnessWorker
        stdout: SplitParser {}
        stderr: SplitParser { onRead: data => panel.error = data.trim() }
        onExited: (code, status) => {
            if (code !== 0) {
                panel.error = panel.error || "明るさを変更できませんでした";
                panel.messageRequested(panel.error, true);
            }
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
        PanelHeader { Layout.fillWidth: true; title: panel.tabTitle; icon: panel.tabIcon; subtitle: panel.tabDescription; onDismissed: panel.dismissed() }
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
                objectName: "controlBody"
                PanelScrollIndicator { parent: bodyScroll; view: bodyScroll }
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: body.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                ColumnLayout {
                    id: body
                    objectName: "controlPageLayout"
                    width: parent.width - (bodyScroll.contentHeight > bodyScroll.height ? Theme.space8 : 0)
                    height: Math.max(implicitHeight, bodyScroll.height)
                    spacing: Theme.space16
                GridLayout {
                    objectName: "quickTiles"
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    visible: panel.tab === "quick"
                    columns: 2
                    rowSpacing: Theme.space8
                    columnSpacing: Theme.space8
                    ControlTile {
                        Layout.fillHeight: false
                        visible: panel.tab === "quick"
                        title: "通知を一時停止"
                        subtitle: Settings.values.dnd ? "オン" : "オフ"
                        icon: Settings.values.dnd ? "notifications_off" : "notifications"
                        checked: Settings.values.dnd
                        checkable: true
                        onToggled: Settings.save(Object.assign({}, Settings.values, {dnd: !Settings.values.dnd}))
                    }
                    ControlTile {
                        Layout.fillHeight: false
                        visible: panel.tab === "quick"
                        title: "壁紙と配色"
                        subtitle: "画像からテーマを生成"
                        icon: "wallpaper"
                        onToggled: panel.panelRequested("wallpaper")
                    }
                    ControlTile {
                        Layout.fillHeight: false
                        visible: panel.tab === "quick"
                        title: "ネットワーク"
                        subtitle: "Wi-Fi・Bluetooth"
                        icon: "wifi"
                        onToggled: panel.selectTab("network")
                    }
                    ControlTile {
                        Layout.fillHeight: false
                        visible: panel.tab === "quick"
                        title: "音声デバイス"
                        subtitle: "出力・マイク入力"
                        icon: "volume_up"
                        onToggled: panel.selectTab("audio")
                    }
                }

                ControlNetwork {
                    Layout.fillWidth: true
                    Layout.fillHeight: panel.tab === "network"
                    visible: panel.tab === "network"
                    active: panel.visible && panel.tab === "network"
                    onMessageRequested: (text, failed) => panel.messageRequested(text, failed)
                }

                PanelSection {
                    objectName: "quickVolume"
                    Layout.fillWidth: true
                    visible: panel.tab === "quick"
                    spacing: Theme.space8
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

                PanelSection {
                    Layout.fillWidth: true
                    visible: panel.tab === "quick" && panel.brightness !== null
                    spacing: Theme.space8
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
                    spacing: Theme.space16
                    Repeater {
                        model: [true, false]
                        delegate: PanelSection {
                            id: section
                            title: modelData ? "出力" : "マイク入力"
                            icon: modelData ? "volume_up" : "volume_mute"
                            required property bool modelData
                            readonly property var node: modelData ? panel.output : panel.input
                            Layout.fillWidth: true
                            spacing: Theme.space8
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
                    Layout.fillHeight: panel.tab === "media"
                    Layout.minimumHeight: implicitHeight
                    visible: panel.tab === "media"
                    service: panel.playerService
                    active: panel.visible && panel.tab === "media"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: panel.tab === "notifications"
                    Layout.fillHeight: panel.tab === "notifications"
                    spacing: Theme.space8
                    RowLayout {
                        Layout.fillWidth: true
                        Text { Layout.fillWidth: true; text: "通知を一時停止"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                        Toggle { checked: Settings.values.dnd; Accessible.name: "通知を一時停止"; onToggled: Settings.save(Object.assign({}, Settings.values, {dnd: !checked})) }
                    }
                    ListView {
                        id: notificationList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: Theme.emptyStateContainerSize * 2
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
                                anchors.margins: Theme.space16
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
                        PanelEmptyState { objectName: "notificationEmptyState"; anchors.fill: parent; visible: notificationList.count === 0; icon: "notifications"; title: "通知はありません"; description: "受け取った通知はここに表示されます。" }
                    }
                    ShellButton {
                        objectName: "clearNotificationsButton"
                        Layout.alignment: Qt.AlignRight
                        text: "履歴を消去"
                        flat: true
                        destructive: true
                        enabled: (panel.notificationService?.history.length ?? 0) > 0
                        onClicked: {
                            panel.notificationService?.clearHistory();
                            panel.messageRequested("通知履歴を消去しました", false);
                        }
                    }
                }

                ControlSettings {
                    Layout.fillWidth: true
                    visible: panel.tab === "settings"
                    draft: panel.draft
                    message: panel.message
                    showPanelLinks: false
                    onChangeRequested: (key, value) => {
                        const next = Object.assign({}, panel.draft);
                        next[key] = value;
                        panel.draft = next;
                        panel.message = "";
                    }
                    onWallpaperRequested: panel.panelRequested("wallpaper")
                    onPanelRequested: name => panel.selectTab(name)
                    onResetRequested: {
                        panel.draft = {
                            showCpu: true, showMemory: true, showNetwork: true, showWindowTitle: true,
                            showTray: true, clock24: true, themeMode: "dark", workspaces: 5,
                            dnd: false, osd: true, autoLockMinutes: 0, screenOffMinutes: 0
                        };
                        panel.message = "初期値を読み込みました（未保存）";
                        panel.messageRequested(panel.message, false);
                    }
                    onSaveRequested: targetDraft => Settings.save(targetDraft)
                    onMessageRequested: (text, failed) => panel.messageRequested(text, failed)
                }


                ControlClipboard {
                    Layout.fillWidth: true
                    Layout.fillHeight: panel.tab === "clipboard"
                    Layout.minimumHeight: Theme.listRowHeight * 3
                    visible: panel.tab === "clipboard"
                    active: panel.visible && panel.tab === "clipboard"
                    onMessageRequested: (text, failed) => panel.messageRequested(text, failed)
                }
                ControlCapture {
                    Layout.fillWidth: true
                    Layout.fillHeight: panel.tab === "capture"
                    Layout.minimumHeight: implicitHeight
                    visible: panel.tab === "capture"
                    busy: panel.captureActive
                    message: panel.message
                    onCaptureRequested: mode => panel.panelRequested("capture:" + mode)
                    onCancelRequested: panel.panelRequested("cancel-capture")
                }
                Item { visible: panel.tab === "quick"; Layout.fillHeight: true }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            visible: panel.tab === "quick"
            ShellButton { Layout.fillWidth: true; text: "通知"; icon: "notifications"; onClicked: panel.selectTab("notifications") }
            ShellButton { Layout.fillWidth: true; text: "すべての設定"; icon: "settings"; onClicked: panel.selectTab("settings") }
        }
    }
}
