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
    // 次に開くときのタブ (0 = 概要 / 1 = Bluetooth / 2 = サウンド / 3 = 通知)
    property int startTab: 0

    content: Component {
        QuickSettingsPanel {
            startTab: root.startTab
        }
    }

    onShownChanged: UiState.quickSettingsOpen = shown

    Connections {
        target: UiState
        function onQuickSettingsToggle() {
            root.startTab = 0;
            root.toggle();
        }
    }

    IpcHandler {
        target: "quicksettings"
        function toggle(): void { root.startTab = 0; root.toggle(); }
        function open(): void { root.startTab = 0; root.open(); }
        function tab(index: int): void { root.startTab = index; root.open(); }
        function close(): void { root.close(); }
    }
}
