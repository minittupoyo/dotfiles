import QtQuick
import QtQuick.Shapes
import "../tokens"

// 円弧のゲージ (270°、下が開いている)。value は 0〜1 で、変化はスプリングで追従する。
// 中央に text (大きく) と subtitle (小さく) を出し、warnAt を超えると警告色になる。
//   Gauge { size: 144; value: 0.42; text: "42%"; subtitle: "58 ℃" }
Item {
    id: root

    property real value: 0
    property string text
    property string subtitle
    property real size: 144
    property real thickness: 12
    property real warnAt: 0.9

    implicitWidth: size
    implicitHeight: size

    SpringValue {
        id: shown
        target: Math.max(0, Math.min(1, root.value))
        spec: Motion.effectsDefault
        epsilon: 0.0005
    }

    readonly property real _r: (size - thickness) / 2
    readonly property color _accent: shown.value >= warnAt ? Colors.m3Error : Colors.m3Primary

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        // 土台
        ShapePath {
            strokeColor: Colors.m3SecondaryContainer
            strokeWidth: root.thickness
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root._r
                radiusY: root._r
                startAngle: 135
                sweepAngle: 270
            }
        }
        // 値
        ShapePath {
            strokeColor: root._accent
            strokeWidth: shown.value > 0.004 ? root.thickness : 0
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: root.size / 2
                centerY: root.size / 2
                radiusX: root._r
                radiusY: root._r
                startAngle: 135
                sweepAngle: 270 * shown.value
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 0
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.text
            role: Typography.headlineSmall
            color: Colors.m3OnSurface
        }
        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.subtitle !== ""
            text: root.subtitle
            role: Typography.labelMedium
            color: Colors.m3OnSurfaceVariant
        }
    }
}
