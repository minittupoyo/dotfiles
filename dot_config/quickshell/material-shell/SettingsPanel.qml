import QtQuick
import QtQuick.Layouts

PanelFrame {
    id: panel
    attachedToBar: true
    panelWidth: Theme.quickSettingsWidth
    panelHeight: Theme.quickSettingsHeight

    property var draft: ({})
    property string message: ""
    signal wallpaperRequested()
    signal panelRequested(string name)

    onVisibleChanged: if (visible) { draft = Object.assign({}, Settings.values); message = ""; }

    function change(key, value) {
        const next = Object.assign({}, draft);
        next[key] = value;
        draft = next;
        message = "";
    }

    function resetDefaults() {
        draft = {
            showCpu: true, showMemory: true, showNetwork: true, showWindowTitle: true,
            showTray: true, clock24: true, themeMode: "dark", workspaces: 5,
            dnd: false, osd: true, autoLockMinutes: 0, screenOffMinutes: 0
        };
        message = "初期値を読み込みました（未保存）";
    }

    Connections {
        target: Settings
        function onSavingChanged() {
            if (!Settings.saving && !Settings.error) panel.message = "設定を保存しました";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.space12

        PanelHeader {
            Layout.fillWidth: true
            title: "設定"
            icon: "settings"
            subtitle: "シェルの表示と動作をカスタマイズ"
            onDismissed: panel.dismissed()
        }

        Flickable {
            id: settingsScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: settingsContent.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            PanelScrollIndicator {
                parent: settingsScroll
                view: settingsScroll
            }

            ControlSettings {
                id: settingsContent
                width: parent.width - (settingsScroll.contentHeight > settingsScroll.height ? Theme.space12 : 0)
                draft: panel.draft
                message: panel.message
                showPanelLinks: true
                showFooter: false

                onChangeRequested: (key, value) => panel.change(key, value)
                onWallpaperRequested: panel.wallpaperRequested()
                onPanelRequested: name => panel.panelRequested(name)
                onResetRequested: panel.resetDefaults()
                onSaveRequested: targetDraft => Settings.save(targetDraft)
            }
        }

        // 下部固定フッター
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outlineVariant
        }

        Text {
            Layout.fillWidth: true
            visible: text !== ""
            text: Settings.error !== "" ? Settings.error : panel.message
            color: Settings.error !== "" ? Theme.error : Theme.primary
            wrapMode: Text.Wrap
            font.family: Theme.fontFamily
            font.pixelSize: Theme.bodySize
            font.weight: Font.Medium
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.space8

            ShellButton {
                text: "初期値"
                flat: true
                enabled: !Settings.saving
                onClicked: panel.resetDefaults()
            }

            Item { Layout.fillWidth: true }

            ShellButton {
                text: "戻す"
                enabled: !Settings.saving
                onClicked: {
                    panel.draft = Object.assign({}, Settings.values);
                    panel.message = "";
                }
            }

            ShellButton {
                objectName: "settingsSave"
                text: Settings.saving ? "保存中…" : "保存"
                emphasized: true
                enabled: !Settings.saving
                onClicked: Settings.save(panel.draft)
            }
        }
    }
}
