import QtQuick
import Quickshell.Io
import "../../components"
import "../../services"

// ランチャー。開閉は IPC: qs ipc call launcher toggle|open|clipboard|close
OverlayWindow {
    id: root

    namespace: "shell:launcher"
    panelWidth: 680
    yFraction: 0.28
    padding: 20

    // 次に開くときのモード ("apps" | "clipboard")
    property string startMode: "apps"

    content: Component {
        LauncherPanel {
            startMode: root.startMode
        }
    }

    // 起動直後は DesktopEntries / 履歴が空なので、先に触って読み込ませておく
    Component.onCompleted: {
        Apps.all.length;
        Clipboard.refresh();
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.startMode = "apps"; root.toggle(); }
        function open(): void { root.startMode = "apps"; root.open(); }
        // すでにクリップボードで開いていれば閉じる。アプリで開いていればクリップボードに切り替える
        function clipboard(): void {
            if (root.shown && root.startMode === "clipboard") {
                root.close();
            } else {
                root.startMode = "clipboard";
                root.open();
            }
        }
        function close(): void { root.close(); }
    }
}
