import QtQuick
import "../tokens"

// hover / pressed / focused のステートレイヤー。親の形に合わせて radius を渡す。
// 不透明度は M3 の値 (hover 0.08 / focus 0.10 / pressed 0.10)。変化は Effects スプリング。
// ripple を併用する部品 (Button 等) は pressed を渡さず、押下表現を Ripple に任せる。
Rectangle {
    id: root

    property bool hovered: false
    property bool pressed: false
    property bool focused: false
    property color stateColor: Colors.m3OnSurface

    color: stateColor
    opacity: level.value
    visible: opacity > 0.001

    SpringValue {
        id: level
        target: root.pressed ? 0.10 : root.focused ? 0.10 : root.hovered ? 0.08 : 0
        spec: Motion.effectsFast
        epsilon: 0.0005
    }
}
