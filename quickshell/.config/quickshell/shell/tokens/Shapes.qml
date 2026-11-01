pragma Singleton

import Quickshell

// M3 の角丸スケール (出典: androidx.compose.material3 ShapeTokens)。
// scale 1 なので px = dp。角丸はここのスケールだけを使う。
// full は Rectangle が短辺/2 に丸めるので十分大きい値でよい。
Singleton {
    readonly property real none: 0
    readonly property real extraSmall: 4
    readonly property real small: 8
    readonly property real medium: 12
    readonly property real large: 16
    readonly property real largeIncreased: 20
    readonly property real extraLarge: 28
    readonly property real extraLargeIncreased: 32
    readonly property real extraExtraLarge: 48
    readonly property real full: 9999
}
