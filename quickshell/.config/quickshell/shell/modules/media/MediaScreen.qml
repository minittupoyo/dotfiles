import QtQuick
import Quickshell.Io
import "../../components"
import "../../services"

// メディア画面 (再生中のプレーヤーの大きな操作画面)。
// 開くのは、クイック設定のメディアカードのクリック (UiState.openMedia)。テスト用に IPC: qs ipc call media toggle|open|close
OverlayWindow {
    id: root

    namespace: "shell:media"
    panelWidth: 820
    panelHeight: 400
    padding: 32
    content: Component {
        MediaPanel {}
    }

    onShownChanged: UiState.mediaShown = shown

    Connections {
        target: UiState
        function onMediaOpen() {
            root.open();
        }
    }

    IpcHandler {
        target: "media"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
    }
}
