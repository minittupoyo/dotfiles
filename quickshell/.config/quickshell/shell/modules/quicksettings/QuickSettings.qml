import QtQuick
import Quickshell.Io
import "../../components"
import "../../services"

// クイック設定。バーのボタン (UiState) か、IPC: qs ipc call quicksettings toggle|open|close
OverlayWindow {
    id: root

    namespace: "shell:quicksettings"
    panelWidth: 420
    panelHeight: 700
    padding: 20
    alignRight: true
    topOffset: 72       // バー (60px) の下
    scrimOpacity: 0     // 背景は暗くしない (外側のクリックでは閉じる)
    content: Component {
        QuickSettingsPanel {}
    }

    onShownChanged: UiState.quickSettingsOpen = shown

    Connections {
        target: UiState
        function onQuickSettingsToggle() {
            root.toggle();
        }
    }

    IpcHandler {
        target: "quicksettings"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
    }
}
