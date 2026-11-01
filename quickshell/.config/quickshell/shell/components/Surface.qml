import QtQuick
import QtQuick.Effects
import "../tokens"

// 色・形・エレベーションを持つ面の土台。子要素は content (default) に入る。
// level は Elevation のレベル (0-5)。影は MultiEffect、トーナルな色は Elevation.color(level)。
Item {
    id: root

    property int level: 0
    property color color: Elevation.color(level)
    property real radius: Shapes.medium
    property color borderColor: "transparent"
    property real borderWidth: 0

    default property alias content: body.data

    // 影の元になる (非表示の) 形。content を含めないので二重描画にならない
    Rectangle {
        id: caster
        anchors.fill: parent
        radius: root.radius
        color: root.color
        visible: false
        layer.enabled: root.level > 0
    }

    MultiEffect {
        anchors.fill: caster
        source: caster
        visible: root.level > 0
        shadowEnabled: true
        shadowColor: Colors.m3Shadow
        shadowOpacity: Elevation.shadow[root.level].opacity
        shadowBlur: Elevation.shadow[root.level].blur / 32
        shadowVerticalOffset: Elevation.shadow[root.level].offsetY
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: root.radius
        color: root.color
        border.color: root.borderColor
        border.width: root.borderWidth
    }
}
