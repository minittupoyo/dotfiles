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

    // FILL = 1 のグリフは輪郭が重なっており、既定の描画 (distance field) では塗りに穴が開く。
    // NativeRendering (FreeType でラスタライズ) だと正しく塗れる。CurveRendering は輪郭線が残る。
    renderType: Text.NativeRendering
    // ヒンティングも切る。小さいサイズでは輪郭の重なりがずれて、塗りの中に細い線が残る (notifications など)。
    font.hintingPreference: Font.PreferNoHinting

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
