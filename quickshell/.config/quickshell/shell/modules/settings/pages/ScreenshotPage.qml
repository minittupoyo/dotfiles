import QtQuick
import QtQuick.Layouts
import "../../../components"
import "../../../services"

ColumnLayout {
    spacing: 20

    SettingGroup {
        Layout.fillWidth: true
        title: "撮影"

        SettingRow {
            title: "ファイルに保存"
            description: "オフにするとクリップボードにだけコピーします"
            Switch { checked: Screenshot.saveToFile; onToggled: Screenshot.setSaveToFile(!checked) }
        }
        SettingRow {
            title: "撮影までのディレイ"
            ChoiceChips {
                options: Screenshot.delays.map(d => ({ label: d === 0 ? "なし" : d + " 秒", value: d }))
                current: Screenshot.delay
                onPicked: v => Screenshot.setDelay(v)
            }
        }
    }
}
