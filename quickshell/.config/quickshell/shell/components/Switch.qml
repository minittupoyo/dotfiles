import QtQuick
import "../tokens"

// M3 Expressive のスイッチ (52x32)。状態は checked を外部が持ち、クリックで toggled() を出す。
// ハンドルは、オフで小さく・オンで大きく・押している間はさらに大きくなる。位置と大きさは Spatial スプリング、色は Effects スプリング。
//   Switch { checked: Wifi.powered; onToggled: Wifi.setPower(!Wifi.powered) }
Item {
    id: root

    property bool checked: false
    property bool showIcon: true    // オンのときハンドルにチェックを出す

    signal toggled()

    implicitWidth: 52
    implicitHeight: 32

    readonly property bool pressed: area.pressed
    activeFocusOnTab: true
    Keys.onSpacePressed: root.toggled()

    // 0 = オフ / 1 = オン (色の混ぜ具合)
    SpringValue {
        id: on
        target: root.checked ? 1 : 0
        spec: Motion.effectsDefault
        epsilon: 0.002
    }
    SpringValue {
        id: handleSize
        target: root.pressed ? 28 : root.checked ? 24 : 16
        spec: Motion.spatialFast
        epsilon: 0.01
    }
    SpringValue {
        id: handleCx
        // 中心の x: オフ = 左寄り (16)、オン = 右寄り (width - 16)
        target: root.checked ? root.width - 16 : 16
        spec: Motion.spatialFast
        epsilon: 0.01
    }

    function _blend(a, b, p) {
        return Qt.tint(a, Qt.rgba(b.r, b.g, b.b, p));
    }

    // トラック
    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root._blend(Colors.m3SurfaceContainerHighest, Colors.m3Primary, on.value)
        border.width: 2
        border.color: root._blend(Colors.m3Outline, Colors.m3Primary, on.value)
    }

    // ハンドルのステートレイヤー (hover / pressed / focus)
    StateLayer {
        width: 40
        height: 40
        radius: 20
        x: handleCx.value - width / 2
        y: (root.height - height) / 2
        hovered: area.containsMouse
        pressed: root.pressed
        focused: root.activeFocus
        stateColor: root.checked ? Colors.m3Primary : Colors.m3OnSurface
    }

    // ハンドル
    Rectangle {
        width: handleSize.value
        height: width
        radius: width / 2
        x: handleCx.value - width / 2
        y: (root.height - height) / 2
        color: root._blend(Colors.m3Outline, Colors.m3OnPrimary, on.value)

        Icon {
            anchors.centerIn: parent
            visible: root.showIcon && on.value > 0.05
            opacity: on.value
            name: "check"
            size: 16
            color: Colors.m3Primary
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.forceActiveFocus();
            root.toggled();
        }
    }
}
