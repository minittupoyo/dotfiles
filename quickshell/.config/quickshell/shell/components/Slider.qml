import QtQuick
import QtQuick.Shapes
import "../tokens"

// M3 Expressive のスライダー (太いトラック + 縦長のハンドル)。value は 0〜1。
// ドラッグ・クリック・ホイールで moved(value) を出す。value の外部からの変化は Effects スプリングで追従する。
Item {
    id: root

    property real value: 0
    property real trackHeight: 24
    property real step: 0.05    // ホイール 1 ノッチあたり

    // 再生位置のような進捗向け: 有効側のトラックが波打つ (M3 Expressive)。waving が false だと直線に戻る
    property bool wavy: false
    property bool waving: true
    property real waveLength: 36
    property real waveAmplitude: 3
    property real waveWidth: 4    // 波の線の太さ

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

    readonly property real gap: 6   // ハンドルとトラックの間隔

    // ---- 波 (wavy のとき) ----
    SpringValue {
        id: amp
        target: root.wavy && root.waving ? root.waveAmplitude : 0
        spec: Motion.spatialDefault
        epsilon: 0.01
    }
    property real _phase: 0
    FrameAnimation {
        running: root.wavy && amp.value > 0.02 && root.visible
        onTriggered: root._phase += frameTime * 5.0    // 波が右へ流れる速さ (rad/s)
    }
    readonly property var _wavePoints: {
        if (!wavy)
            return [];
        const end = handleX - gap - waveWidth / 2;
        const cy = height / 2;
        const a = Math.max(0, amp.value);
        const k = 2 * Math.PI / waveLength;
        const pts = [];
        for (let x = waveWidth / 2; x < end; x += 2)
            pts.push(Qt.point(x, cy + a * Math.sin(k * x - _phase)));
        pts.push(Qt.point(Math.max(waveWidth / 2, end), cy + a * Math.sin(k * end - _phase)));
        return end > waveWidth / 2 ? pts : [];
    }

    Shape {
        anchors.fill: parent
        visible: root.wavy
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Colors.m3Primary
            strokeWidth: root.waveWidth
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathPolyline {
                path: root._wavePoints
            }
        }
    }
    // 波のときの非アクティブ側 (細い直線)
    Rectangle {
        visible: root.wavy
        anchors.verticalCenter: parent.verticalCenter
        x: root.handleX + root.gap
        width: Math.max(0, root.width - x)
        height: root.waveWidth
        radius: height / 2
        color: Colors.m3SecondaryContainer
    }

    // 非アクティブ側のトラック (ハンドルの先から右端まで。内側の角は小さく、外側は完全に丸める)
    Rectangle {
        visible: !root.wavy
        anchors.verticalCenter: parent.verticalCenter
        x: root.handleX + root.gap
        width: Math.max(0, root.width - x)
        height: root.trackHeight
        topLeftRadius: Shapes.extraSmall
        bottomLeftRadius: Shapes.extraSmall
        topRightRadius: height / 2
        bottomRightRadius: height / 2
        color: Colors.m3SecondaryContainer
    }
    // アクティブ側のトラック (左端からハンドルの手前まで)
    Rectangle {
        visible: !root.wavy
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, root.handleX - root.gap)
        height: root.trackHeight
        topLeftRadius: height / 2
        bottomLeftRadius: height / 2
        topRightRadius: Shapes.extraSmall
        bottomRightRadius: Shapes.extraSmall
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
