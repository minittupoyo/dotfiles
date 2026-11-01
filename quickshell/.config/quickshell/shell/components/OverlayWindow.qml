import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../tokens"

// フォーカス中のモニターにだけ出る、画面全体のオーバーレイ (壁紙セレクター・ランチャー共通)。
// 背景を暗くして中央 (または yFraction の位置) にパネルを出し、開閉はスプリングで動く。
//
//   OverlayWindow {
//       id: ov
//       content: Component { MyPanel {} }     // 中身。open() があれば開くたびに呼ばれ、closeRequested() で閉じる
//   }
//   ov.toggle()
//
// 中身は表示中のモニターにだけ生成され、閉じるアニメーションが終わると破棄される。
Scope {
    id: root

    property bool shown: false
    // 開いた時点のフォーカス中モニター (開いている間にフォーカスが動いても、表示は動かさない)
    property string targetScreen: ""

    property Component content
    property real panelWidth: 1100       // 最大幅 (画面に収まらなければ縮める)
    property real panelHeight: 720       // 既定の高さ。中身が implicitHeight を持てばそれに追従する
    property real padding: 24
    property real yFraction: 0.5         // 縦位置: 0 = 上端 / 0.5 = 中央
    property real topOffset: -1          // 0 以上なら、上端からの絶対位置 (yFraction より優先)
    property bool alignRight: false      // true なら右端に寄せる (クイック設定)。拡大縮小も右上を起点にする
    property real edgeMargin: 12         // alignRight のときの右端との間隔
    property real scrimOpacity: 0.4      // 背景の暗さ。0 でも、外側のクリックで閉じる
    property string namespace: "shell:overlay"

    function open() {
        const m = Hyprland.focusedMonitor;
        targetScreen = m ? m.name : "";
        shown = true;
    }
    function close() {
        shown = false;
    }
    function toggle() {
        shown ? close() : open();
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData    // ShellScreen

            screen: modelData
            readonly property bool mine: modelData.name === root.targetScreen    // screen ではなく modelData を読む (visible との束縛ループを避ける)
            readonly property bool active: mine && root.shown
            readonly property bool animating: pop.value > 0.002 || fade.value > 0.002

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: root.namespace
            WlrLayershell.keyboardFocus: active ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"
            // 閉じるアニメーションが終わるまでは表示しておく
            visible: mine && (root.shown || animating)

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

            // すでに中身がある (閉じるアニメーション中に開き直した) 場合の open()
            Connections {
                target: root
                function onShownChanged() {
                    if (root.shown && win.mine && loader.item && loader.item.open)
                        loader.item.open();
                }
            }

            // 背景 (スクリム)。クリックで閉じる
            Rectangle {
                anchors.fill: parent
                color: Colors.m3Scrim
                opacity: root.scrimOpacity * fade.value
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            Surface {
                id: panel

                // 中身が implicitHeight を持てばそれに合わせる (ランチャーの結果数に追従)
                // (ウィンドウが非表示の間は win.height が 0 なので、その間は既定値で見積もる)
                readonly property real maxHeight: win.height > 0 ? win.height - 96 : root.panelHeight
                readonly property real wantHeight: loader.item && loader.item.implicitHeight > 0
                    ? Math.min(loader.item.implicitHeight + 2 * root.padding, maxHeight)
                    : Math.min(root.panelHeight, maxHeight)

                // 開いた直後は、ウィンドウの高さが確定するまでアニメーションさせず値を追従させる
                property bool settleNext: false
                onWantHeightChanged: if (settleNext && win.height > 0) settleHeight()
                function settleHeight() {
                    heightSpring.settle();
                    settleNext = false;
                }

                width: Math.min(root.panelWidth, win.width - 96)
                height: heightSpring.value
                x: root.alignRight ? win.width - width - root.edgeMargin : (win.width - width) / 2
                y: root.topOffset >= 0 ? root.topOffset : (win.height - height) * root.yFraction
                transformOrigin: root.alignRight ? Item.TopRight : Item.Center
                level: 3
                radius: Shapes.extraLarge
                opacity: fade.value
                scale: 0.92 + 0.08 * pop.value

                SpringValue {
                    id: heightSpring
                    target: panel.wantHeight
                    spec: Motion.spatialDefault
                    epsilon: 0.1
                }

                // パネル内のクリックを背景に通さない
                MouseArea {
                    anchors.fill: parent
                }

                Loader {
                    id: loader
                    anchors.fill: parent
                    anchors.margins: root.padding
                    active: win.mine && (root.shown || win.animating)
                    sourceComponent: root.content

                    onLoaded: {
                        panel.settleNext = true;                // 開く瞬間は高さを動かさない
                        if (win.height > 0)
                            panel.settleHeight();
                        if (item.open)
                            item.open();
                    }
                }

                Connections {
                    target: win
                    function onHeightChanged() {
                        if (panel.settleNext && win.height > 0)
                            panel.settleHeight();
                    }
                }

                Connections {
                    target: loader.item
                    ignoreUnknownSignals: true
                    function onCloseRequested() {
                        root.close();
                    }
                }
            }
        }
    }
}
