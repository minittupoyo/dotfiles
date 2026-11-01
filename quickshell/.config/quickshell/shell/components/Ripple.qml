import QtQuick
import QtQuick.Effects
import "../tokens"

// 押下位置から広がる波紋。radius の角丸でクリップされる。
//   onPressed: ripple.press(mouse.x, mouse.y)    onReleased/onCanceled: ripple.release()
Item {
    id: root

    property real radius: 0
    property color color: Colors.m3OnSurface
    property real pressedOpacity: 0.10

    function press(px, py) {
        circle.cx = px;
        circle.cy = py;
        const dx = Math.max(px, width - px);
        const dy = Math.max(py, height - py);
        grow.snap(0);
        grow.target = Math.sqrt(dx * dx + dy * dy);
        fade.snap(0);
        fade.target = pressedOpacity;
    }

    function release() {
        fade.target = 0;
    }

    SpringValue { id: grow; spec: Motion.effectsSlow; epsilon: 0.1 }
    SpringValue { id: fade; spec: Motion.effectsDefault; epsilon: 0.0005 }

    // クリップ用マスク (maskSource は layer が必要)
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }

    Item {
        anchors.fill: parent
        visible: fade.value > 0.001
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: mask
        }

        Rectangle {
            id: circle
            property real cx: 0
            property real cy: 0
            x: cx - width / 2
            y: cy - height / 2
            width: Math.max(0, grow.value) * 2
            height: width
            radius: width / 2
            color: root.color
            opacity: fade.value
        }
    }
}
