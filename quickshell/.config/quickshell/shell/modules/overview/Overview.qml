import QtQuick
import Quickshell.Io
import "../../components"

// ワークスペースのオーバービュー (SUPER+Tab)。フォーカス中のモニターのワークスペースを並べて、
// クリックで移動、ウィンドウのドラッグで別のワークスペースへ移す。
// 開閉は IPC: qs ipc call overview toggle|open|close
OverlayWindow {
    id: root

    namespace: "shell:overview"
    panelWidth: 1700
    panelHeight: 400
    padding: 24
    scrimOpacity: 0.5
    content: Component {
        OverviewPanel {}
    }

    IpcHandler {
        target: "overview"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
    }
}
