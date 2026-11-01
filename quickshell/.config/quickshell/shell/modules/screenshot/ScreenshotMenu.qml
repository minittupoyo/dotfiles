import QtQuick
import Quickshell.Io
import "../../components"
import "../../services"

// スクリーンショットのメニュー (画面下の中央)。開閉は IPC: qs ipc call screenshot toggle|open|close、Print キー。
// テスト・スクリプト用に IPC: qs ipc call screenshot take <region|window|screen|all> (メニューを出さずに撮る)
OverlayWindow {
    id: root

    namespace: "shell:screenshot"
    panelWidth: 600
    panelHeight: 200
    padding: 20
    yFraction: 0.88
    scrimOpacity: 0     // 背景は暗くしない (撮る画面を変えないため)
    content: Component {
        ScreenshotPanel {
            onChosen: mode => Screenshot.take(mode)
        }
    }

    IpcHandler {
        target: "screenshot"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
        function take(mode: string): void { Screenshot.take(mode); }
    }
}
