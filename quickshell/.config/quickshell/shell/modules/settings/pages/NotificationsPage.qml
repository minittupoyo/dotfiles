import QtQuick
import QtQuick.Layouts
import "../../../components"
import "../../../services"

ColumnLayout {
    spacing: 20

    SettingGroup {
        Layout.fillWidth: true
        title: "ポップアップ"

        SettingRow {
            title: "表示時間"
            description: "通知が時間を指定していないときの秒数 (緊急は消えません)"
            ChoiceChips {
                options: [{ label: "3 秒", value: 3 }, { label: "6 秒", value: 6 }, { label: "10 秒", value: 10 }, { label: "15 秒", value: 15 }]
                current: Settings.notifTimeout
                onPicked: v => Settings.set("notifTimeout", v)
            }
        }
        SettingRow {
            title: "おやすみモード"
            description: "ポップアップを出さず、履歴だけ残します (緊急は例外)。再起動で戻ります"
            Switch { checked: Notifications.dnd; onToggled: Notifications.setDnd(!checked) }
        }
    }
}
