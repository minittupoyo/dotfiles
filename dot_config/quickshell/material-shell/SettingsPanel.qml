import QtQuick
import QtQuick.Layouts

PanelFrame {
    id: panel
    attachedToBar: true
    property var draft: ({})
    property string message: ""
    signal wallpaperRequested()
    signal panelRequested(string name)
    onVisibleChanged: if (visible) { draft = Object.assign({}, Settings.values); message = ""; }
    function change(key, value) { const next = Object.assign({}, draft); next[key] = value; draft = next; message = ""; }
    Connections {
        target: Settings
        function onSavingChanged() { if (!Settings.saving && !Settings.error) panel.message = "設定を保存しました"; }
    }
    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space16
        PanelHeader { Layout.fillWidth: true; title: "設定"; onDismissed: panel.dismissed() }
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: options.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: options
                width: parent.width
                spacing: Theme.space12
                Repeater {
                    model: [{key:"showCpu",label:"CPU使用率"},{key:"showMemory",label:"メモリ使用率"},
                        {key:"showNetwork",label:"ネットワーク"},{key:"showWindowTitle",label:"ウィンドウ名"},
                        {key:"showTray",label:"システムトレイ"},{key:"clock24",label:"24時間表示"},
                        {key:"osd",label:"音量・明るさのOSD"},{key:"dnd",label:"通知を一時停止"}]
                    RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.buttonHeight
                        Text { Layout.fillWidth: true; text: parent.modelData.label; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                        Toggle { objectName: "setting-" + parent.modelData.key; checked: panel.draft[parent.modelData.key] ?? false; Accessible.name: parent.modelData.label; enabled: !Settings.saving; onToggled: panel.change(parent.modelData.key, !checked) }
                    }
                }
                Repeater {
                    model: [{key:"workspaces",label:"ワークスペース数",min:1,max:10,step:1},
                        {key:"autoLockMinutes",label:"自動ロック（分）",min:0,max:240,step:5},
                        {key:"screenOffMinutes",label:"自動消灯（分）",min:0,max:240,step:5}]
                    RowLayout {
                        id: numeric
                        required property var modelData
                        Layout.fillWidth: true
                        Text { Layout.fillWidth: true; text: numeric.modelData.label; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                        ShellButton { text: "−"; Accessible.name: numeric.modelData.label + "を減らす"; enabled: !Settings.saving && panel.draft[numeric.modelData.key] > numeric.modelData.min; onClicked: panel.change(numeric.modelData.key, Math.max(numeric.modelData.min, panel.draft[numeric.modelData.key] - numeric.modelData.step)) }
                        Text { text: panel.draft[numeric.modelData.key] === 0 ? "無効" : String(panel.draft[numeric.modelData.key] ?? ""); color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
                        ShellButton { text: "+"; Accessible.name: numeric.modelData.label + "を増やす"; enabled: !Settings.saving && panel.draft[numeric.modelData.key] < numeric.modelData.max; onClicked: panel.change(numeric.modelData.key, Math.min(numeric.modelData.max, panel.draft[numeric.modelData.key] + numeric.modelData.step)) }
                    }
                }
                ShellButton { text: "壁紙を選択"; icon: "wallpaper"; onClicked: panel.wallpaperRequested() }
                ShellButton { text: "Now Playing"; icon: "music_note"; onClicked: panel.panelRequested("media") }
                ShellButton { text: "オーディオ"; icon: "volume_up"; onClicked: panel.panelRequested("audio") }
                ShellButton { text: "クリップボード"; icon: "content_paste"; onClicked: panel.panelRequested("clipboard") }
                ShellButton { text: "スクリーンショット"; icon: "screenshot_monitor"; onClicked: panel.panelRequested("capture") }
            }
        }
        Text { Layout.fillWidth: true; visible: text !== ""; text: Settings.error || panel.message; color: Settings.error ? Theme.error : Theme.surfaceVariantText; wrapMode: Text.Wrap; font.family: Theme.fontFamily; font.pixelSize: Theme.bodySize }
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            ShellButton { text: "戻す"; enabled: !Settings.saving; onClicked: { panel.draft = Object.assign({}, Settings.values); panel.message = ""; } }
            ShellButton { objectName: "settingsSave"; text: Settings.saving ? "保存中…" : "保存"; emphasized: true; enabled: !Settings.saving; onClicked: Settings.save(panel.draft) }
        }
    }
}
