import QtQuick
import "../tokens"

// Typography のロールで描画するテキスト。フォント・サイズ・行高・字間はすべてロールから決まる。
//   Label { text: "Hello"; role: Typography.titleMedium }
Text {
    id: root

    property var role: Typography.bodyMedium

    color: Colors.m3OnSurface

    // 日本語を含む行は、フォールバックフォント (Noto Sans CJK) の行メトリクスに引っ張られて、行全体が下に描かれる
    // (14px で約 2.5px。大きいほど増える)。描画だけを上げて、Latin だけの行と、上下の中心を揃える。
    // transform なので、レイアウトの高さには影響しない。
    readonly property bool hasCjk: /[\u3000-\u30ff\u3400-\u9fff\uff00-\uffef]/.test(text)
    transform: Translate { y: root.hasCjk ? -role.size * 0.16 : 0 }

    font.family: Typography.family
    font.pixelSize: role.size
    font.weight: role.weight
    font.letterSpacing: role.tracking
    lineHeight: role.lineHeight
    lineHeightMode: Text.FixedHeight
    verticalAlignment: Text.AlignVCenter
}
