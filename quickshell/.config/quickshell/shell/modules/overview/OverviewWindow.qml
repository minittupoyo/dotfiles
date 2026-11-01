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

    Binding on x { value: win.homeX; when: !win.dragging && !settle.running }
    Binding on y { value: win.homeY; when: !win.dragging && !settle.running }
    width: homeW
    height: homeH
    z: dragging ? 10 : 0
    scale: dragging ? 1.06 : 1
    Behavior on scale { NumberAnimation { duration: 120 } }

    // ドロップ後に元の位置 (または新しいカード) へ戻る
    ParallelAnimation {
        id: settle
        NumberAnimation { target: win; property: "x"; to: win.homeX; duration: 150; easing.type: Easing.OutCubic }
        NumberAnimation { target: win; property: "y"; to: win.homeY; duration: 150; easing.type: Easing.OutCubic }
    }

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
                win.dropped(win.x + win.width / 2, win.y + win.height / 2);
                settle.restart();
            }
        }
        onClicked: () => { if (!moved) win.clicked(); }
    }
}
