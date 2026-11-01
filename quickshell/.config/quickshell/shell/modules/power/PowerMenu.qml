import QtQuick
import Quickshell.Io
import "../../components"
import "../../services"

// 電源メニュー (画面中央)。開閉は IPC: qs ipc call power toggle|open|close、SUPER+M。
OverlayWindow {
    id: root

    namespace: "shell:power"
    panelWidth: 680
    panelHeight: 240
    padding: 24
    scrimOpacity: 0.4
    content: Component {
        PowerPanel {}
    }

    IpcHandler {
        target: "power"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
    }
}
