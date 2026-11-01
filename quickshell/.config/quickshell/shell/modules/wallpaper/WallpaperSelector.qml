import QtQuick
import Quickshell.Io
import "../../components"
import "../../services"

// 壁紙セレクター。開閉は IPC: qs ipc call wallpaper toggle|open|close
OverlayWindow {
    id: root

    namespace: "shell:wallpaper"
    panelWidth: 1100
    panelHeight: 720
    content: Component {
        WallpaperPanel {}
    }

    onShownChanged: if (shown) Wallpaper.ensureThumbs()

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
    }
}
