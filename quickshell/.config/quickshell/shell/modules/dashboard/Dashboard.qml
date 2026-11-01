import QtQuick
import Quickshell.Io
import "../../components"
import "../../services"

// ダッシュボード (カレンダー + システムモニター)。開くのは、バー中央の島 (時計) のクリック (UiState.openDashboard)。
// テスト用に IPC: qs ipc call dashboard toggle|open|close
OverlayWindow {
    id: root

    namespace: "shell:dashboard"
    panelWidth: 940
    panelHeight: 480
    padding: 16
    content: Component {
        DashboardPanel {}
    }

    // システムモニターは、開いている間だけ更新する
    onShownChanged: SystemStats.active = shown

    Connections {
        target: UiState
        function onDashboardToggle() {
            root.toggle();
        }
    }

    IpcHandler {
        target: "dashboard"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
    }
}
