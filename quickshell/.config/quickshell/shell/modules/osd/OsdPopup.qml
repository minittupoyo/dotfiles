import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../../components"
import "../../services"
import "../../tokens"

// 音量・マイクのミュートの OSD。フォーカス中のモニターの、画面下の中央に出る。
// 出すかどうかは services/Osd が決める。クリックは下のウィンドウに通す。
Scope {
    id: root

    readonly property string focusedName: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData    // ShellScreen

            screen: modelData
            readonly property bool focusedHere: modelData.name === root.focusedName

            // 出入りの動き (位置はスプリングで、不透明度はオーバーシュートなしのスプリングで)
            SpringValue {
                id: slide
                target: Osd.shown && win.focusedHere ? 1 : 0
                spec: Motion.spatialDefault
                epsilon: 0.001
            }
            SpringValue {
                id: fade
                target: Osd.shown && win.focusedHere ? 1 : 0
                spec: Motion.effectsDefault
                epsilon: 0.001
            }

            visible: fade.value > 0.01 || fade.target > 0

            anchors.bottom: true
            margins.bottom: 72
            exclusionMode: ExclusionMode.Ignore
            implicitWidth: 360
            implicitHeight: 88
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell:osd"

            // 入力は受けない
            mask: Region {}

            Surface {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                width: 320
                height: 64
                y: (parent.height - height) / 2 + (1 - slide.value) * 32
                opacity: Math.max(0, Math.min(1, fade.value))
                level: 3
                radius: Shapes.full

                readonly property bool isMic: Osd.kind === "mic"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 24
                    spacing: 12

                    Icon {
                        name: pill.isMic ? (Audio.sourceMuted ? "mic_off" : "mic") : Audio.volumeIcon(Audio.volume, Audio.muted)
                        size: 24
                        color: (pill.isMic ? Audio.sourceMuted : Audio.muted) ? Colors.m3Outline : Colors.m3OnSurface
                    }

                    // 音量: スライダー (表示のみ)
                    Slider {
                        visible: !pill.isMic
                        Layout.fillWidth: true
                        value: Audio.muted ? 0 : Audio.volume
                        enabled: false
                    }
                    Label {
                        visible: !pill.isMic
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignRight
                        text: Math.round(Audio.volume * 100) + "%"
                        role: Typography.labelLarge
                        color: Audio.muted ? Colors.m3Outline : Colors.m3OnSurfaceVariant
                    }

                    // マイク: 状態だけ
                    Label {
                        visible: pill.isMic
                        Layout.fillWidth: true
                        text: Audio.sourceMuted ? "マイクをミュート" : "マイクをオン"
                        role: Typography.titleMedium
                        color: Audio.sourceMuted ? Colors.m3Outline : Colors.m3OnSurface
                    }
                }
            }
        }
    }
}
