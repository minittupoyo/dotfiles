import QtQuick
import QtQuick.Layouts
import "../../../components"
import "../../../services"

ColumnLayout {
    spacing: 20

    SettingGroup {
        Layout.fillWidth: true
        title: "自動ロック"

        SettingRow {
            title: "アイドルでロックするまで"
            description: "操作がなくなってからの時間。スリープ抑止中はロックされません"
            ChoiceChips {
                options: [{ label: "しない", value: 0 }, { label: "5 分", value: 5 }, { label: "10 分", value: 10 }, { label: "15 分", value: 15 }, { label: "30 分", value: 30 }]
                current: Settings.lockMinutes
                onPicked: v => Settings.set("lockMinutes", v)
            }
        }
        SettingRow {
            title: "ロック中に画面を消す"
            description: "環境によっては、画面が点き直らなくなることがあります。試すときは、すぐ戻せる状態で"
            ChoiceChips {
                options: [{ label: "消さない", value: 0 }, { label: "1 分", value: 1 }, { label: "5 分", value: 5 }]
                current: Settings.dpmsMinutes
                onPicked: v => Settings.set("dpmsMinutes", v)
            }
        }
        SettingRow {
            title: "今すぐロック"
            Button { size: "s"; variant: "tonal"; icon: "lock"; text: "ロック"; onClicked: Lock.lock() }
        }
    }
}
