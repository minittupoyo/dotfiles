import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../services"

// 通知のポップアップ。フォーカス中のモニターの右上に積み重ねる (バーの下)。
Scope {
    id: root

    // フォーカス中のモニター名。ウィンドウごとに Hyprland を読まず、ここで 1 か所だけ持つ (束縛ループを避ける)
    readonly property string focusedName: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData    // ShellScreen

            screen: modelData
            readonly property bool focusedHere: modelData.name === root.focusedName    // screen ではなく modelData を読む (visible との束縛ループを避ける)

            visible: focusedHere && Notifications.popups.length > 0

            anchors {
                top: true
                right: true
            }
            // exclusionMode は既定 (Normal / ゾーン 0) のままにして、バーの予約領域の下に出す
            margins {
                top: 12
                right: 12
            }
            implicitWidth: 380
            implicitHeight: 900
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell:notifications"

            // カードのある所だけが入力を受ける (ウィンドウの空き部分は下のウィンドウに通す)
            mask: Region {
                item: stack
            }

            Column {
                id: stack
                spacing: 8

                Repeater {
                    // ScriptModel は配列の差分だけを反映する。JS 配列をそのまま渡すと、更新のたびに全カードが作り直される
                    model: ScriptModel {
                        values: Notifications.popups
                    }

                    NotificationCard {}
                }
            }
        }
    }
}
