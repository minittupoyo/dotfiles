import QtQuick
import "../tokens"

// M3 Expressive のスライダー (太いトラック + 縦長のハンドル)。value は 0〜1。
// ドラッグ・クリック・ホイールで moved(value) を出す。value の外部からの変化は Effects スプリングで追従する。
Item {
    id: root

    property real value: 0
    property real trackHeight: 28
    property real step: 0.05    // ホイール 1 ノッチあたり

    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 44

    readonly property bool pressed: area.pressed
    readonly property real pad: 6

    function _clamp(v) {
        return Math.max(0, Math.min(1, v));
    }

    function _fromX(x) {
        return _clamp((x - pad) / Math.max(1, width - 2 * pad));
    }

    // 表示上の値 (外部変更は滑らかに追従、ドラッグ中は即座に追従)
    SpringValue {
        id: shown
        target: root._clamp(root.value)
        spec: Motion.effectsFast
        epsilon: 0.0005
    }
    onValueChanged: if (pressed) shown.settle()

    readonly property real handleX: pad + shown.value * (width - 2 * pad)

    // 押している間はハンドルが細くなる (M3 Expressive)
    SpringValue {
        id: handleW
        target: root.pressed ? 2 : 4
        spec: Motion.spatialFast
        epsilon: 0.01
    }

    // 非アクティブ側のトラック
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.trackHeight
        radius: Shapes.medium
        color: Colors.m3SecondaryContainer
    }
    // アクティブ側のトラック (ハンドルの手前まで)
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, root.handleX - 6)
        height: root.trackHeight
        radius: Shapes.medium
        color: Colors.m3Primary
    }
    // ハンドル
    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.handleX - width / 2
        width: Math.max(2, handleW.value)
        height: root.height
        radius: Shapes.full
        color: Colors.m3Primary
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: m => root.moved(root._fromX(m.x))
        onPositionChanged: m => { if (pressed) root.moved(root._fromX(m.x)); }
        onWheel: wheel => root.moved(root._clamp(root.value + wheel.angleDelta.y / 120 * root.step))
    }
}
