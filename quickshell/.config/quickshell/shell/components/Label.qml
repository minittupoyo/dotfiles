import QtQuick
import "../tokens"

// Typography のロールで描画するテキスト。フォント・サイズ・行高・字間はすべてロールから決まる。
//   Label { text: "Hello"; role: Typography.titleMedium }
Text {
    property var role: Typography.bodyMedium

    color: Colors.m3OnSurface
    font.family: Typography.family
    font.pixelSize: role.size
    font.weight: role.weight
    font.letterSpacing: role.tracking
    lineHeight: role.lineHeight
    lineHeightMode: Text.FixedHeight
    verticalAlignment: Text.AlignVCenter
}
