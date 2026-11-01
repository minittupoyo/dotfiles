import QtQuick
import "../tokens"

// M3 Expressive のボタン。size: "s" | "m" | "l"
// 寸法は公式トークン (ButtonSmall/Medium/LargeTokens) に由来: 高さ 40/56/96、アイコン 20/24/32、
// アイコン-ラベル間 8/8/12、左右余白 16/24/48、押下時の角丸 small/medium/large。
// 選択時の角丸 (square) は S のみ公式 (medium)。M/L は未確認の暫定値。
// ラベルのロールも未確認の暫定 (S=labelLarge / M=titleMedium / L=headlineSmall)。
BaseButton {
    id: root

    property string text
    property string icon
    property string size: "m"

    readonly property var _d: ({
        s: { h: 40, icon: 20, gap: 8,  pad: 16, pressed: Shapes.small,  square: Shapes.medium,     role: Typography.labelLarge },
        m: { h: 56, icon: 24, gap: 8,  pad: 24, pressed: Shapes.medium, square: Shapes.large,      role: Typography.titleMedium },
        l: { h: 96, icon: 32, gap: 12, pad: 48, pressed: Shapes.large,  square: Shapes.extraLarge, role: Typography.headlineSmall }
    })[size]

    implicitHeight: _d.h
    implicitWidth: row.implicitWidth + 2 * _d.pad
    pressedRadius: _d.pressed
    squareRadius: _d.square

    Row {
        id: row
        anchors.centerIn: parent
        spacing: root._d.gap

        Icon {
            visible: root.icon !== ""
            name: root.icon
            size: root._d.icon
            fill: root.checkProgress
            color: root.contentColor
            anchors.verticalCenter: parent.verticalCenter
        }
        Label {
            text: root.text
            role: root._d.role
            color: root.contentColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
