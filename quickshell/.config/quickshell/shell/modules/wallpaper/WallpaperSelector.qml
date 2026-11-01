import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../../components"
import "../../services"
import "../../tokens"

// 壁紙セレクター。フォーカス中のモニターにだけ、背景を暗くして中央に表示する。
// 開閉は IPC: qs ipc call wallpaper toggle|open|close
Scope {
    id: root

    property bool shown: false
    // 開いた時点のフォーカス中モニター (開いている間に動いても、表示は動かさない)
    property string targetScreen: ""

    function open() {
        const m = Hyprland.focusedMonitor;
        targetScreen = m ? m.name : "";
        Wallpaper.ensureThumbs();
        shown = true;
    }
    function close() {
        shown = false;
    }
    function toggle() {
        shown ? close() : open();
    }

    IpcHandler {
        target: "wallpaper"
        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function close(): void { root.close(); }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData    // ShellScreen

            screen: modelData
            readonly property bool mine: screen.name === root.targetScreen

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell:wallpaper"
            WlrLayershell.keyboardFocus: root.shown && mine ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"
            // 閉じるアニメーションが終わるまでは表示しておく
            visible: mine && (root.shown || pop.value > 0.002 || fade.value > 0.002)

            SpringValue {
                id: pop
                target: root.shown && win.mine ? 1 : 0
                spec: Motion.spatialDefault
                epsilon: 0.001
            }
            SpringValue {
                id: fade
                target: root.shown && win.mine ? 1 : 0
                spec: Motion.effectsDefault
                epsilon: 0.001
            }

            Connections {
                target: root
                function onShownChanged() {
                    if (root.shown && win.mine)
                        content.open();
                }
            }

            // 背景 (スクリム)。クリックで閉じる
            Rectangle {
                anchors.fill: parent
                color: Colors.m3Scrim
                opacity: 0.4 * fade.value
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            Surface {
                id: panel
                anchors.centerIn: parent
                width: Math.min(1100, win.width - 96)
                height: Math.min(720, win.height - 96)
                level: 3
                radius: Shapes.extraLarge
                opacity: fade.value
                scale: 0.92 + 0.08 * pop.value

                // パネル内のクリックを背景に通さない
                MouseArea {
                    anchors.fill: parent
                }

                WallpaperPanel {
                    id: content
                    anchors.fill: parent
                    anchors.margins: 24
                    onCloseRequested: root.close()
                }
            }

        }
    }
}
