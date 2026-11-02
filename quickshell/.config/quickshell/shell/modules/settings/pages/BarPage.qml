import QtQuick
import QtQuick.Layouts
import "../../../components"
import "../../../services"

ColumnLayout {
    spacing: 20

    SettingGroup {
        Layout.fillWidth: true
        title: "時計"

        SettingRow {
            title: "24 時間表示"
            description: "オフにすると 12 時間表示 (AM / PM)"
            Switch { checked: Settings.clock24h; onToggled: Settings.set("clock24h", !checked) }
        }
        SettingRow {
            title: "秒を表示"
            Switch { checked: Settings.clockSeconds; onToggled: Settings.set("clockSeconds", !checked) }
        }
        SettingRow {
            title: "日付を表示"
            Switch { checked: Settings.clockDate; onToggled: Settings.set("clockDate", !checked) }
        }
    }

    SettingGroup {
        Layout.fillWidth: true
        title: "表示する項目"

        SettingRow {
            title: "アクティブウィンドウのタイトル"
            description: "フォーカス中のウィンドウの名前"
            Switch { checked: Settings.barActiveWindow; onToggled: Settings.set("barActiveWindow", !checked) }
        }
        SettingRow {
            title: "システムトレイ"
            description: "常駐アプリのアイコン"
            Switch { checked: Settings.barTray; onToggled: Settings.set("barTray", !checked) }
        }
    }
}
