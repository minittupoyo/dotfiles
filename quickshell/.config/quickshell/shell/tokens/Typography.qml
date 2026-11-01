pragma Singleton

import QtQuick
import Quickshell

// M3 の type scale (出典: androidx.compose.material3 TypeScaleTokens)。scale 1 なので px = dp。
// 各ロールは { size, lineHeight, weight, tracking }。表示は components/Label.qml 経由で行う。
// *Emphasized は M3 Expressive の強調版 (出典側で TODO 付き = 値が変わる可能性あり)。
Singleton {
    // QML の font には複数ファミリー指定 (font.families) がないため、主フォントだけを指定し、
    // 日本語など主フォントに無い字形は fontconfig のフォールバックに任せる。
    // 期待するフォールバック順: Roboto Flex → Noto Sans CJK JP (設定は fontconfig/ 側)。
    readonly property string family: "Google Sans Flex"
    readonly property var fallbackFamilies: ["Roboto Flex", "Noto Sans CJK JP"]
    // M3 の type scale に無い、ロック画面の時計用の特大サイズ (このシェル独自)
    readonly property var displayHuge: ({ size: 128, lineHeight: 144, weight: Font.Normal, tracking: -1 })
    readonly property var displayLarge: ({ size: 57, lineHeight: 64, weight: Font.Normal, tracking: -0.2 })
    readonly property var displayMedium: ({ size: 45, lineHeight: 52, weight: Font.Normal, tracking: 0 })
    readonly property var displaySmall: ({ size: 36, lineHeight: 44, weight: Font.Normal, tracking: 0 })
    readonly property var headlineLarge: ({ size: 32, lineHeight: 40, weight: Font.Normal, tracking: 0 })
    readonly property var headlineMedium: ({ size: 28, lineHeight: 36, weight: Font.Normal, tracking: 0 })
    readonly property var headlineSmall: ({ size: 24, lineHeight: 32, weight: Font.Normal, tracking: 0 })
    readonly property var titleLarge: ({ size: 22, lineHeight: 28, weight: Font.Normal, tracking: 0 })
    readonly property var titleMedium: ({ size: 16, lineHeight: 24, weight: Font.Medium, tracking: 0.2 })
    readonly property var titleSmall: ({ size: 14, lineHeight: 20, weight: Font.Medium, tracking: 0.1 })
    readonly property var bodyLarge: ({ size: 16, lineHeight: 24, weight: Font.Normal, tracking: 0.5 })
    readonly property var bodyMedium: ({ size: 14, lineHeight: 20, weight: Font.Normal, tracking: 0.2 })
    readonly property var bodySmall: ({ size: 12, lineHeight: 16, weight: Font.Normal, tracking: 0.4 })
    readonly property var labelLarge: ({ size: 14, lineHeight: 20, weight: Font.Medium, tracking: 0.1 })
    readonly property var labelMedium: ({ size: 12, lineHeight: 16, weight: Font.Medium, tracking: 0.5 })
    readonly property var labelSmall: ({ size: 11, lineHeight: 16, weight: Font.Medium, tracking: 0.5 })

    readonly property var displayLargeEmphasized: ({ size: 57, lineHeight: 64, weight: Font.Medium, tracking: 0 })
    readonly property var displayMediumEmphasized: ({ size: 45, lineHeight: 52, weight: Font.Medium, tracking: 0 })
    readonly property var displaySmallEmphasized: ({ size: 36, lineHeight: 44, weight: Font.Medium, tracking: 0 })
    readonly property var headlineLargeEmphasized: ({ size: 32, lineHeight: 40, weight: Font.Medium, tracking: 0 })
    readonly property var headlineMediumEmphasized: ({ size: 28, lineHeight: 36, weight: Font.Medium, tracking: 0 })
    readonly property var headlineSmallEmphasized: ({ size: 24, lineHeight: 32, weight: Font.Medium, tracking: 0 })
    readonly property var titleLargeEmphasized: ({ size: 22, lineHeight: 28, weight: Font.Medium, tracking: 0 })
    readonly property var titleMediumEmphasized: ({ size: 16, lineHeight: 24, weight: Font.Bold, tracking: 0.15 })
    readonly property var titleSmallEmphasized: ({ size: 14, lineHeight: 20, weight: Font.Bold, tracking: 0.1 })
    readonly property var bodyLargeEmphasized: ({ size: 16, lineHeight: 24, weight: Font.Medium, tracking: 0.15 })
    readonly property var bodyMediumEmphasized: ({ size: 14, lineHeight: 20, weight: Font.Medium, tracking: 0.25 })
    readonly property var bodySmallEmphasized: ({ size: 12, lineHeight: 16, weight: Font.Medium, tracking: 0.4 })
    readonly property var labelLargeEmphasized: ({ size: 14, lineHeight: 20, weight: Font.Bold, tracking: 0.1 })
    readonly property var labelMediumEmphasized: ({ size: 12, lineHeight: 16, weight: Font.Bold, tracking: 0.5 })
    readonly property var labelSmallEmphasized: ({ size: 11, lineHeight: 16, weight: Font.Bold, tracking: 0.5 })
}
