import QtQuick
import Quickshell.Io
import "../../components"
import "../../services"

// ランチャー。開閉は IPC: qs ipc call launcher toggle|open|clipboard|emoji|close
OverlayWindow {
    id: root

    namespace: "shell:launcher"
    panelWidth: 680
    yFraction: 0.28
    padding: 20

    // 次に開くときのモード ("apps" | "clipboard" | "emoji")
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
        Emoji.ensure();
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
        // すでに絵文字で開いていれば閉じる。ほかのモードで開いていれば絵文字に切り替える
        function emoji(): void {
            if (root.shown && root.startMode === "emoji") {
                root.close();
            } else {
                root.startMode = "emoji";
                root.open();
            }
        }
        function close(): void { root.close(); }
    }
}
