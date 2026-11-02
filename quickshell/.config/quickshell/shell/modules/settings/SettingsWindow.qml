import QtQuick
import Quickshell.Io
import "../../components"
import "../../services"

// 設定画面。バーの歯車 / クイック設定の歯車 / IPC: qs ipc call settings toggle|open|close|page <0-5>
OverlayWindow {
    id: root

    namespace: "shell:settings"
    panelWidth: 980
    panelHeight: 700
    padding: 0
    scrimOpacity: 0.4
    property int startPage: 0

    content: Component {
        SettingsPanel {
            startPage: root.startPage
        }
    }

    Connections {
        target: UiState
        function onSettingsOpen(page) {
            root.startPage = page;
            root.open();
        }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { root.startPage = 0; root.toggle(); }
        function open(): void { root.startPage = 0; root.open(); }
        function page(index: int): void { root.startPage = index; root.open(); }
        function close(): void { root.close(); }
    }
}
