import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../../tokens"

// 画面上端のバー (モニターごとに 1 つ)。左・中央・右の 3 つの「島」を透明な背景の上に浮かせる。
PanelWindow {
    id: win

    required property var modelData    // ShellScreen (Variants から渡される)

    screen: modelData
    anchors {
        top: true
        left: true
        right: true
    }
    margins {
        top: 12
        left: 12
        right: 12
    }
    implicitHeight: 48
    color: "transparent"

    readonly property var monitor: Hyprland.monitorFor(screen)

    BarIsland {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Workspaces { monitor: win.monitor }
        ActiveWindow { monitor: win.monitor }
    }

    BarIsland {
        anchors.centerIn: parent

        Clock {}
    }

    BarIsland {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Tray {}
        NetworkIcon {}
        Volume {}
    }
}
