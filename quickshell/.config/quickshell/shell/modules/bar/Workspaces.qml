import QtQuick
import Quickshell.Hyprland
import "../../components"
import "../../tokens"

// このモニターに割り当てられたワークスペースだけを並べる (モニター名は埋め込まない)。
// 選択中は幅が広がる (スプリング) 形状モーフィング付きのピル。
Row {
    id: root

    required property var monitor    // HyprlandMonitor

    spacing: 4

    readonly property var list: {
        const mon = root.monitor;
        if (!mon)
            return [];
        return Hyprland.workspaces.values
            .filter(w => w.monitor && w.monitor.name === mon.name && w.id > 0)
            .sort((a, b) => a.id - b.id);
    }

    Repeater {
        model: root.list

        BaseButton {
            id: pill

            required property var modelData    // HyprlandWorkspace

            variant: "tonal"
            checkable: true
            autoToggle: false        // 選択状態は Hyprland 側の active に従う
            checked: modelData.active
            pressedRadius: Shapes.small
            squareRadius: Shapes.medium

            implicitHeight: 32
            implicitWidth: width_.value

            SpringValue {
                id: width_
                target: pill.checked ? 56 : 32
                spec: Motion.spatialDefault
                epsilon: 0.05
            }

            onClicked: modelData.activate()

            Label {
                anchors.centerIn: parent
                text: pill.modelData.id
                role: Typography.labelLarge
                color: pill.contentColor
                // 空のワークスペースは控えめに
                opacity: pill.checked || pill.modelData.toplevels.values.length > 0 ? 1 : 0.5
            }
        }
    }
}
