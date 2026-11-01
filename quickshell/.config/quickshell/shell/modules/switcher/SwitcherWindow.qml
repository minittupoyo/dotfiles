import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../components"
import "../../tokens"

// Alt+Tab の画面。フォーカス中のモニターの中央に、ウィンドウのカードを横に並べる。
// 開閉と選択のスプリングは Motion トークン。クリックは、カードの上だけが受ける。
Scope {
    id: root

    required property var switcher

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData    // ShellScreen

            screen: modelData
            readonly property bool mine: modelData.name === root.switcher.targetScreen
            readonly property bool active: mine && root.switcher.shown
            readonly property bool animating: pop.value > 0.002 || fade.value > 0.002

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "shell:switcher"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None    // キーは Hyprland のサブマップが受ける
            color: "transparent"
            visible: mine && (root.switcher.shown || animating)

            // クリックは、パネルの上だけ
            mask: Region {
                item: panel
            }

            SpringValue {
                id: pop
                target: win.active ? 1 : 0
                spec: Motion.spatialDefault
                epsilon: 0.001
            }
            SpringValue {
                id: fade
                target: win.active ? 1 : 0
                spec: Motion.effectsDefault
                epsilon: 0.001
            }

            Surface {
                id: panel

                readonly property real cardW: 232
                readonly property real pad: 20
                readonly property real wantW: list.count * cardW + Math.max(0, list.count - 1) * list.spacing + 2 * pad

                anchors.centerIn: parent
                width: Math.min(wantW, win.width - 96)
                height: 212 + 16 + 2 * (pad - 8)
                level: 3
                radius: Shapes.extraLarge
                opacity: fade.value
                scale: 0.92 + 0.08 * pop.value

                ListView {
                    id: list
                    anchors.fill: parent
                    anchors.margins: panel.pad - 8    // 選択中のカードが少し大きくなっても、枠で切れないように
                    leftMargin: 8
                    rightMargin: 8
                    orientation: ListView.Horizontal
                    spacing: 12
                    clip: true
                    interactive: contentWidth > width
                    boundsBehavior: Flickable.StopAtBounds
                    highlightFollowsCurrentItem: false
                    // 開いている間だけ、カード (とキャプチャ) を作る
                    model: win.mine && (root.switcher.shown || win.animating) ? root.switcher.windows : []
                    currentIndex: root.switcher.index
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

                    delegate: SwitcherCard {
                        y: (list.height - height) / 2
                        selected: index === root.switcher.index
                        onClicked: {
                            root.switcher.index = index;
                            root.switcher.commit();
                        }
                    }
                }
            }
        }
    }
}
