import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../components"
import "../../services"
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

    // スリープ・ロックの抑止 (クイック設定のトグル)。常に表示されるバーのウィンドウに付ける
    IdleInhibitor {
        window: win
        enabled: IdleInhibit.active
    }

    BarIsland {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Workspaces { monitor: win.monitor }
        ActiveWindow { monitor: win.monitor }
    }

    // 中央の島 (時計)。クリックでダッシュボードを開く
    BarIsland {
        id: clockIsland
        anchors.centerIn: parent

        Clock {}
    }
    StateLayer {
        anchors.fill: clockIsland
        radius: Shapes.full
        hovered: clockMouse.containsMouse
        pressed: clockMouse.pressed
    }
    MouseArea {
        id: clockMouse
        anchors.fill: clockIsland
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: UiState.toggleDashboard()
    }

    BarIsland {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Tray {}
        NetworkIcon {}
        Volume {}
        NotificationButton {}
    }
}
