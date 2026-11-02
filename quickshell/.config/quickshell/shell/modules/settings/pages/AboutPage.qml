import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../components"
import "../../../services"
import "../../../tokens"

ColumnLayout {
    spacing: 20

    SettingGroup {
        Layout.fillWidth: true
        title: "モニター"

        Repeater {
            model: Quickshell.screens

            SettingRow {
                required property var modelData    // ShellScreen
                title: modelData.name
                description: modelData.width + " × " + modelData.height + (modelData.model ? " · " + modelData.model : "")
                Label {
                    text: "×" + modelData.devicePixelRatio
                    role: Typography.labelLarge
                    color: Colors.m3OnSurfaceVariant
                }
            }
        }
    }

    SettingGroup {
        Layout.fillWidth: true
        title: "設定ファイル"

        SettingRow {
            title: "保存先"
            description: Settings.stateFile
        }
        SettingRow {
            title: "すべて初期値に戻す"
            description: "設定画面の項目を、すべて初期値に戻します"
            Button { size: "s"; variant: "tonal"; icon: "restart_alt"; text: "初期値に戻す"; onClicked: { Settings.resetAll(); Wallpaper.reapply(); } }
        }
    }
}
