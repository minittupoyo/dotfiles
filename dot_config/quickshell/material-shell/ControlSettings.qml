import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: settingsRoot
    property var draft: ({})
    property string message: ""
    property bool showPanelLinks: true
    property bool showFooter: true
    signal wallpaperRequested()
    signal panelRequested(string name)
    signal changeRequested(string key, var value)
    signal resetRequested()
    signal saveRequested(var draft)
    signal messageRequested(string text, bool failed)

    spacing: Theme.space16

    function change(key, value) {
        changeRequested(key, value);
    }

    // --- 1. カラーテーマ ---
    PanelSection {
        title: "カラーテーマ"
        icon: "wallpaper"
        description: "壁紙から自動生成された配色と表示トーン"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.space12

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8

                ShellButton {
                    objectName: "themeModeLight"
                    Layout.fillWidth: true
                    text: "ライトモード"
                    icon: "brightness_high"
                    emphasized: settingsRoot.draft.themeMode === "light"
                    enabled: !Settings.saving
                    onClicked: {
                        settingsRoot.change("themeMode", "light");
                        Settings.save(Object.assign({}, Settings.values, {themeMode: "light"}));
                    }
                }
                ShellButton {
                    objectName: "themeModeDark"
                    Layout.fillWidth: true
                    text: "ダークモード"
                    icon: "bedtime"
                    emphasized: settingsRoot.draft.themeMode !== "light"
                    enabled: !Settings.saving
                    onClicked: {
                        settingsRoot.change("themeMode", "dark");
                        Settings.save(Object.assign({}, Settings.values, {themeMode: "dark"}));
                    }
                }
            }

            // 配色プレビューパレット
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space8

                Text {
                    text: "抽出パレット:"
                    color: Theme.surfaceVariantText
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.labelSize
                }

                Repeater {
                    model: [
                        { name: "Primary", color: Theme.primary },
                        { name: "Secondary", color: Theme.secondaryContainer },
                        { name: "Surface", color: Theme.surfaceContainerHighest },
                        { name: "Outline", color: Theme.outline },
                        { name: "Error", color: Theme.error }
                    ]
                    Rectangle {
                        id: colorChip
                        required property var modelData
                        width: 20
                        height: 20
                        radius: 10
                        color: modelData.color
                        border.width: 1
                        border.color: Theme.outlineVariant

                        BarTooltip {
                            target: colorChip
                            text: colorChip.modelData.name + " (" + colorChip.modelData.color + ")"
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                ShellButton {
                    text: "壁紙を選択"
                    icon: "wallpaper"
                    flat: true
                    enabled: !Settings.saving
                    onClicked: settingsRoot.wallpaperRequested()
                }
            }
        }
    }

    // --- 2. ステータスバー ---
    PanelSection {
        title: "ステータスバー"
        icon: "tune"
        description: "画面上部のバーに表示する各ウィジェットと時計"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.space4

            Repeater {
                model: [
                    { key: "showWindowTitle", label: "アクティブウィンドウ名" },
                    { key: "clock24", label: "24時間表記の時計 (オフで12時間表記)" },
                    { key: "showCpu", label: "CPU使用率インジケーター" },
                    { key: "showMemory", label: "メモリ使用率インジケーター" },
                    { key: "showNetwork", label: "ネットワーク接続インジケーター" },
                    { key: "showTray", label: "システムトレイ（アプレット領域）" }
                ]
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeight

                    Text {
                        Layout.fillWidth: true
                        text: parent.modelData.label
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodySize
                    }
                    Toggle {
                        objectName: "setting-" + parent.modelData.key
                        checked: settingsRoot.draft[parent.modelData.key] ?? false
                        Accessible.name: parent.modelData.label
                        enabled: !Settings.saving
                        onToggled: settingsRoot.change(parent.modelData.key, !checked)
                    }
                }
            }
        }
    }

    // --- 3. 通知と操作表示 ---
    PanelSection {
        title: "通知と操作表示"
        icon: "notifications"
        description: "デスクトップ通知とお知らせポップアップの挙動"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.space4

            Repeater {
                model: [
                    { key: "osd", label: "音量・明るさ変更時のOSD通知" },
                    { key: "dnd", label: "通知を一時停止（おやすみモード）" }
                ]
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeight

                    Text {
                        Layout.fillWidth: true
                        text: parent.modelData.label
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodySize
                    }
                    Toggle {
                        objectName: "setting-" + parent.modelData.key
                        checked: settingsRoot.draft[parent.modelData.key] ?? false
                        Accessible.name: parent.modelData.label
                        enabled: !Settings.saving
                        onToggled: settingsRoot.change(parent.modelData.key, !checked)
                    }
                }
            }
        }
    }

    // --- 4. ワークスペースと画面管理 ---
    PanelSection {
        title: "ワークスペースと省電力"
        icon: "lock"
        description: "仮想デスクトップ数と無操作時の自動ロック・消灯"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.space8

            Repeater {
                model: [
                    { key: "workspaces", label: "ワークスペース数", min: 1, max: 10, step: 1, unit: "面" },
                    { key: "autoLockMinutes", label: "自動ロック（分）", min: 0, max: 240, step: 5, unit: "分" },
                    { key: "screenOffMinutes", label: "自動消灯（分）", min: 0, max: 240, step: 5, unit: "分" }
                ]
                delegate: RowLayout {
                    id: numericRow
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.buttonHeight

                    Text {
                        Layout.fillWidth: true
                        text: numericRow.modelData.label
                        color: Theme.surfaceText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.bodySize
                    }

                    ShellButton {
                        text: "−"
                        Accessible.name: numericRow.modelData.label + "を減らす"
                        enabled: !Settings.saving && (settingsRoot.draft[numericRow.modelData.key] ?? numericRow.modelData.min) > numericRow.modelData.min
                        onClicked: settingsRoot.change(numericRow.modelData.key, Math.max(numericRow.modelData.min, (settingsRoot.draft[numericRow.modelData.key] ?? numericRow.modelData.min) - numericRow.modelData.step))
                    }

                    Rectangle {
                        implicitWidth: 64
                        implicitHeight: Theme.buttonHeight - Theme.space8
                        radius: Theme.shapeSmall
                        color: Theme.surfaceContainerHighest

                        Text {
                            anchors.centerIn: parent
                            text: {
                                const val = settingsRoot.draft[numericRow.modelData.key] ?? 0;
                                if (val === 0 && numericRow.modelData.min === 0) return "無効";
                                return String(val) + (numericRow.modelData.unit ? " " + numericRow.modelData.unit : "");
                            }
                            color: Theme.surfaceText
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.bodySize
                            font.weight: Font.Medium
                        }
                    }

                    ShellButton {
                        text: "+"
                        Accessible.name: numericRow.modelData.label + "を増やす"
                        enabled: !Settings.saving && (settingsRoot.draft[numericRow.modelData.key] ?? numericRow.modelData.min) < numericRow.modelData.max
                        onClicked: settingsRoot.change(numericRow.modelData.key, Math.min(numericRow.modelData.max, (settingsRoot.draft[numericRow.modelData.key] ?? numericRow.modelData.min) + numericRow.modelData.step))
                    }
                }
            }

            Text {
                visible: (settingsRoot.draft.autoLockMinutes ?? 0) > 0 && (settingsRoot.draft.screenOffMinutes ?? 0) > 0 && (settingsRoot.draft.screenOffMinutes < settingsRoot.draft.autoLockMinutes)
                text: "※ 自動消灯時間は自動ロック時間以上に設定してください。"
                color: Theme.error
                font.family: Theme.fontFamily
                font.pixelSize: Theme.labelSize
                wrapMode: Text.Wrap
            }
        }
    }

    // --- 5. 関連ツール・ショートカット ---
    PanelSection {
        visible: settingsRoot.showPanelLinks
        title: "関連コントロール"
        icon: "keyboard"
        description: "他のコントロールパネル機能へのクイックアクセス"

        Flow {
            Layout.fillWidth: true
            spacing: Theme.space8

            ShellButton {
                text: "音声設定"
                icon: "volume_up"
                flat: true
                onClicked: settingsRoot.panelRequested("audio")
            }
            ShellButton {
                text: "メディア操作"
                icon: "music_note"
                flat: true
                onClicked: settingsRoot.panelRequested("media")
            }
            ShellButton {
                text: "クリップボード"
                icon: "content_paste"
                flat: true
                onClicked: settingsRoot.panelRequested("clipboard")
            }
            ShellButton {
                text: "画面キャプチャ"
                icon: "screenshot_monitor"
                flat: true
                onClicked: settingsRoot.panelRequested("capture")
            }
            ShellButton {
                text: "接続 (Wi-Fi / BT)"
                icon: "wifi"
                flat: true
                onClicked: settingsRoot.panelRequested("network")
            }
        }
    }

    // --- 6. システム環境 ---
    PanelSection {
        title: "システム情報"
        icon: "storage"
        description: "Material Shell 実行環境"

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.space4

            RowLayout {
                Layout.fillWidth: true
                Text { text: "バージョン"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
                Item { Layout.fillWidth: true }
                Text { text: "Material Shell v3 (M3 Expressive)"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize; font.weight: Font.Medium }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "コンポジタ"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
                Item { Layout.fillWidth: true }
                Text { text: "Hyprland Wayland Compositor"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: "シェル基盤"; color: Theme.surfaceVariantText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
                Item { Layout.fillWidth: true }
                Text { text: "Quickshell 0.3.1 + Matugen 4.2.0"; color: Theme.surfaceText; font.family: Theme.fontFamily; font.pixelSize: Theme.labelSize }
            }
        }
    }

    // --- 操作フッター ---
    RowLayout {
        Layout.fillWidth: true
        visible: settingsRoot.showFooter
        spacing: Theme.space8

        ShellButton {
            objectName: "controlSettingsReset"
            text: "初期値"
            flat: true
            enabled: !Settings.saving
            onClicked: settingsRoot.resetRequested()
        }

        Item { Layout.fillWidth: true }

        ShellButton {
            objectName: "controlSettingsRevert"
            text: "戻す"
            enabled: !Settings.saving
            onClicked: {
                settingsRoot.draft = Object.assign({}, Settings.values);
                settingsRoot.message = "";
                settingsRoot.messageRequested("変更を元に戻しました", false);
            }
        }

        ShellButton {
            objectName: "controlSettingsSave"
            text: Settings.saving ? "保存中…" : "保存"
            emphasized: true
            enabled: !Settings.saving
            onClicked: settingsRoot.saveRequested(settingsRoot.draft)
        }
    }
}
