import QtQuick
import "../tokens"

// Button / IconButton の共通部分: 配色 (variant × checked)、押下・選択での角丸モーフィング、
// ステートレイヤー、ripple、キーボード操作。サイズや中身は派生側が決める。
//
// variant: "filled" | "tonal" | "outlined" | "text" | "standard"
//   standard = 透明 + onSurfaceVariant (選択時 primary)。アイコンが並ぶ場所の既定
// checkable なときは checked で選択状態を持つ。選択でも角丸が変わる (M3 Expressive)。
Item {
    id: root

    property string variant: "filled"
    property bool checkable: false
    property bool checked: false
    // false にすると、クリックで checked を反転しない (選択状態を外部の状態に束縛するとき用。
    // 反転すると束縛が壊れる)。見た目の選択表現 (色・角丸) は checkable のまま使える。
    property bool autoToggle: true

    // 押下時・選択時の角丸 (Shapes のスケールから派生側が与える)。通常時は完全な丸 (height / 2)。
    property real pressedRadius: Shapes.small
    property real squareRadius: Shapes.medium

    readonly property bool pressed: mouse.pressed
    readonly property bool hovered: mouse.containsMouse
    // 0 = 未選択 / 1 = 選択。色と Icon の FILL 軸の補間に使う
    readonly property real checkProgress: check.value
    readonly property real cornerRadius: Math.max(0, radiusSpring.value)

    readonly property color containerColor: _container()
    readonly property color contentColor: _content()

    signal clicked()
    signal rightClicked()

    default property alias content: contentItem.data

    activeFocusOnTab: true

    function _mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }

    function _pair(checked) {
        // [container, content] を返す。checkable でない場合は未選択側だけが使われる
        const clear = Qt.rgba(0, 0, 0, 0);
        switch (variant) {
        case "tonal":
            return checked ? [Colors.m3Secondary, Colors.m3OnSecondary]
                           : [Colors.m3SecondaryContainer, Colors.m3OnSecondaryContainer];
        case "outlined":
            return checked ? [Colors.m3InverseSurface, Colors.m3InverseOnSurface]
                           : [clear, Colors.m3OnSurfaceVariant];
        case "text":
            return [clear, Colors.m3Primary];
        case "standard":
            return checked ? [clear, Colors.m3Primary] : [clear, Colors.m3OnSurfaceVariant];
        default: // filled
            return checked ? [Colors.m3Primary, Colors.m3OnPrimary]
                           : (checkable ? [Colors.m3SurfaceContainer, Colors.m3OnSurfaceVariant]
                                        : [Colors.m3Primary, Colors.m3OnPrimary]);
        }
    }

    function _container() {
        if (!enabled) {
            return (variant === "filled" || variant === "tonal")
                ? Qt.rgba(Colors.m3OnSurface.r, Colors.m3OnSurface.g, Colors.m3OnSurface.b, 0.10)
                : Qt.rgba(0, 0, 0, 0);
        }
        return _mix(_pair(false)[0], _pair(true)[0], checkProgress);
    }

    function _content() {
        if (!enabled)
            return Qt.rgba(Colors.m3OnSurface.r, Colors.m3OnSurface.g, Colors.m3OnSurface.b, 0.38);
        return _mix(_pair(false)[1], _pair(true)[1], checkProgress);
    }

    function _activate() {
        if (!enabled)
            return;
        if (checkable && autoToggle)
            checked = !checked;
        clicked();
    }

    SpringValue {
        id: check
        target: root.checkable && root.checked ? 1 : 0
        spec: Motion.effectsDefault
        epsilon: 0.001
    }

    // 形状モーフィング: 押下 → pressedRadius、選択 → squareRadius、通常 → 完全な丸
    SpringValue {
        id: radiusSpring
        target: root.pressed ? root.pressedRadius
              : (root.checkable && root.checked) ? root.squareRadius
              : root.height / 2
        spec: Motion.spatialFast
        epsilon: 0.05
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.containerColor
        border.width: root.variant === "outlined" && root.enabled ? 1 * (1 - root.checkProgress) : 0
        border.color: Colors.m3Outline
    }

    StateLayer {
        anchors.fill: parent
        radius: root.cornerRadius
        stateColor: root.contentColor
        hovered: root.hovered && root.enabled
        // MouseArea はフォーカスを奪わないので、activeFocus は Tab 等のキーボード由来になる
        focused: root.activeFocus
    }

    Ripple {
        id: ripple
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.contentColor
    }

    Item {
        id: contentItem
        anchors.fill: parent
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
        onPressed: m => ripple.press(m.x, m.y)
        onReleased: ripple.release()
        onCanceled: ripple.release()
        onClicked: m => m.button === Qt.RightButton ? root.rightClicked() : root._activate()
    }

    Keys.onSpacePressed: _activate()
    Keys.onReturnPressed: _activate()
}
