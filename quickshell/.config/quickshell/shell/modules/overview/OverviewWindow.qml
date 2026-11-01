import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../../components"
import "../../tokens"

// カードの中の 1 つのウィンドウ。実際の絵 (ライブ) を、実際の位置・大きさで縮小して出す。
// クリックでそのウィンドウへ移動、ドラッグで別のワークスペースへ。位置は親 (パネル) が与える。
Item {
    id: win

    required property var client    // { address, appClass, title, toplevel }
    // ドラッグしていないときの位置と大きさ (パネルが計算する)
    property real homeX: 0
    property real homeY: 0
    property real homeW: 100
    property real homeH: 60

    readonly property bool dragging: area.drag.active

    // ドラッグ中、カードのどこに乗っているか知らせる / 離したときに知らせる
    signal dragMoved(real cx, real cy)
    signal dropped(real cx, real cy)
    signal clicked()

    // 位置・大きさは、パネルが与える目標へスプリングで追従する (移動先で並べ直されたレイアウトにも滑らかに動く)。
    // ドラッグ中は、ポインタに付いてくる。
    SpringValue { id: sx; target: win.homeX; spec: Motion.spatialDefault; epsilon: 0.05 }
    SpringValue { id: sy; target: win.homeY; spec: Motion.spatialDefault; epsilon: 0.05 }
    SpringValue { id: sw; target: win.homeW; spec: Motion.spatialDefault; epsilon: 0.05 }
    SpringValue { id: sh; target: win.homeH; spec: Motion.spatialDefault; epsilon: 0.05 }
    SpringValue { id: lift; target: win.dragging ? 1 : 0; spec: Motion.spatialFast; epsilon: 0.002 }

    Binding on x { value: sx.value; when: !win.dragging }
    Binding on y { value: sy.value; when: !win.dragging }
    width: Math.max(1, sw.value)
    height: Math.max(1, sh.value)
    z: dragging || lift.value > 0.01 ? 10 : 0
    scale: 1 + 0.06 * lift.value

    readonly property string iconSource: {
        const e = DesktopEntries.heuristicLookup(client.appClass);
        return Quickshell.iconPath(e && e.icon ? e.icon : client.appClass.toLowerCase(), true);
    }

    Rectangle {
        id: mask
        anchors.fill: parent
        radius: Shapes.small
        visible: false
        layer.enabled: true
    }
    Rectangle {
        anchors.fill: parent
        radius: Shapes.small
        color: Colors.m3SurfaceContainerHighest
        border.width: win.dragging || area.containsMouse ? 2 : 0
        border.color: Colors.m3Primary
    }
    Image {
        anchors.centerIn: parent
        width: Math.min(40, parent.width * 0.6, parent.height * 0.6)
        height: width
        visible: !view.hasContent && source !== ""
        source: win.iconSource
        sourceSize: Qt.size(80, 80)
        asynchronous: true
    }
    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
        }
        ScreencopyView {
            id: view
            anchors.fill: parent
            captureSource: win.client.toplevel ? win.client.toplevel.wayland : null
            constraintSize: Qt.size(640, 400)
            live: true
            visible: hasContent
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        drag.target: win
        drag.threshold: 8
        property bool moved: false

        onPressed: () => moved = false
        onPositionChanged: () => {
            if (area.drag.active) {
                moved = true;
                win.dragMoved(win.x + win.width / 2, win.y + win.height / 2);
            }
        }
        onReleased: () => {
            if (moved) {
                // 離した位置から、目標 (元の場所か移動先) へスプリングで動かす
                sx.value = win.x;
                sy.value = win.y;
                win.dropped(win.x + win.width / 2, win.y + win.height / 2);
                sx.wake();
                sy.wake();
            }
        }
        onClicked: () => { if (!moved) win.clicked(); }
    }
}
