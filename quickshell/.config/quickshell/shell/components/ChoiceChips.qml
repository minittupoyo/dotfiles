import QtQuick
import "../tokens"

// 選択肢を横に並べるボタン列 (単一選択)。options は [{ label, value }]。
//   ChoiceChips { options: [{label:"5分", value:5}]; current: Settings.lockMinutes; onPicked: v => Settings.set("lockMinutes", v) }
Flow {
    id: root

    property var options: []
    property var current

    signal picked(var value)

    spacing: 4

    Repeater {
        model: root.options

        Button {
            required property var modelData
            size: "s"
            variant: "tonal"
            text: modelData.label
            checkable: true
            autoToggle: false
            checked: root.current === modelData.value
            onClicked: root.picked(modelData.value)
        }
    }
}
