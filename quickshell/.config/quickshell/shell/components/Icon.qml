import QtQuick
import "../tokens"

// Material Symbols Rounded。name は合字名 (例: "home", "search")。
// fill は FILL 軸 (0 = 線, 1 = 塗り)。実数なので SpringValue で連続的に変化させられる。
Text {
    id: root

    property string name
    property real size: 24
    property real fill: 0
    property real weight: 400

    text: name
    color: Colors.m3OnSurface
    width: size
    height: size
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter

    font.family: "Material Symbols Rounded"
    font.pixelSize: size
    font.variableAxes: ({
        "FILL": fill,
        "wght": weight,
        "GRAD": 0,
        "opsz": Math.max(20, Math.min(48, size))
    })
}
