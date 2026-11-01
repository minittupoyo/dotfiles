import QtQuick
import "../tokens"

// Typography のロールで描画するテキスト。フォント・サイズ・行高・字間はすべてロールから決まる。
//   Label { text: "Hello"; role: Typography.titleMedium }
Text {
    id: root

    property var role: Typography.bodyMedium

    color: Colors.m3OnSurface

    // 主フォント (Google Sans Flex) に字形がなく、フォールバックフォント (Noto Sans CJK など) で描かれる文字を含む行は、
    // その行メトリクスに引っ張られて、行全体が下に描かれる (14px で約 2.5px。大きいほど増える)。
    // 対象: 日本語 (かな・漢字・全角・半角カナ・記号)、℃ № などの文字様記号、矢印、丸数字、罫線・図形・記号 (★ ← ① ■ ✓ など)。
    // 影響しない: · — – ° … ’ × • % € é µ など (実測)。描画だけを上げて、Latin だけの行と上下の中心を揃える。
    // transform なので、レイアウトの高さには影響しない。
    readonly property bool hasCjk: /[\u2100-\u214f\u2190-\u21ff\u2460-\u27bf\u3000-\u30ff\u3400-\u9fff\uff00-\uffef]/.test(text)
    transform: Translate { y: root.hasCjk ? -role.size * 0.16 : 0 }

    font.family: Typography.family
    font.pixelSize: role.size
    font.weight: role.weight
    font.letterSpacing: role.tracking
    lineHeight: role.lineHeight
    lineHeightMode: Text.FixedHeight
    verticalAlignment: Text.AlignVCenter
}
