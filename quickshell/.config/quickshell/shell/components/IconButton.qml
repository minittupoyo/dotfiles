import QtQuick
import "../tokens"

// アイコンだけのボタン。size: "s" | "m" | "l"
// 注意: container 寸法 (40/56/96) とアイコン 24/24/32 は M3 仕様の記憶に基づく暫定値で、
//       公式トークンでの確認ができていない (アイコン 24dp が標準であることのみ確認済み)。
//       差し替えはこの _d だけで済む。
BaseButton {
    id: root

    property string icon
    property string size: "m"

    readonly property var _d: ({
        s: { box: 40, icon: 24, pressed: Shapes.small,  square: Shapes.medium },
        m: { box: 56, icon: 24, pressed: Shapes.medium, square: Shapes.large },
        l: { box: 96, icon: 32, pressed: Shapes.large,  square: Shapes.extraLarge }
    })[size]

    implicitWidth: _d.box
    implicitHeight: _d.box
    pressedRadius: _d.pressed
    squareRadius: _d.square

    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: root._d.icon
        fill: root.checkProgress
        color: root.contentColor
    }
}
