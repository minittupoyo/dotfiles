import QtQuick
import QtQuick.Layouts
import "../../../components"
import "../../../services"

ColumnLayout {
    spacing: 20

    SettingGroup {
        Layout.fillWidth: true
        title: "クリップボード"

        SettingRow {
            title: "履歴の表示件数"
            description: "ランチャーのクリップボード検索に出す最大件数"
            ChoiceChips {
                options: [{ label: "20", value: 20 }, { label: "50", value: 50 }, { label: "100", value: 100 }]
                current: Settings.clipboardResults
                onPicked: v => Settings.set("clipboardResults", v)
            }
        }
    }

    SettingGroup {
        Layout.fillWidth: true
        title: "アプリ"

        SettingRow {
            title: "起動履歴をリセット"
            description: "よく使うアプリを上に出す並び順を、初期状態に戻します"
            Button { size: "s"; variant: "tonal"; icon: "restart_alt"; text: "リセット"; onClicked: Apps.resetUsage() }
        }
    }
}
