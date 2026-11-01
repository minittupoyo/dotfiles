pragma Singleton

import QtQuick
import Quickshell

// M3 のエレベーション (レベル 0-5)。
// - dp: M3 のレベルに対応する値 (0, 1, 3, 6, 8, 12)
// - shadow: MultiEffect 用の近似 (offsetY[px], blur[px], opacity)。見た目はギャラリーで調整する。
// - color(level): トーナルな面の色 (surface-container 系)。Colors を読むので配色変更に追従する。
// 影の色は Colors.m3Shadow を使う。
Singleton {
    readonly property var dp: [0, 1, 3, 6, 8, 12]

    readonly property var shadow: [
        ({ offsetY: 0, blur: 0,  opacity: 0.00 }),
        ({ offsetY: 1, blur: 3,  opacity: 0.16 }),
        ({ offsetY: 2, blur: 6,  opacity: 0.18 }),
        ({ offsetY: 4, blur: 10, opacity: 0.20 }),
        ({ offsetY: 6, blur: 12, opacity: 0.22 }),
        ({ offsetY: 8, blur: 16, opacity: 0.24 })
    ]

    function color(level) {
        switch (level) {
        case 0: return Colors.m3Surface;
        case 1: return Colors.m3SurfaceContainerLow;
        case 2: return Colors.m3SurfaceContainer;
        case 3: return Colors.m3SurfaceContainerHigh;
        default: return Colors.m3SurfaceContainerHighest;
        }
    }
}
