pragma Singleton

import Quickshell

// M3 Expressive のモーショントークン (スプリング)。
// 値の出典: androidx.compose.material3 ExpressiveMotionTokens
//   Spatial = 位置・大きさ・形状 (オーバーシュートあり) / Effects = 色・不透明度 (オーバーシュートなし)
// stiffness は物理的な剛性 (質量1)、damping は減衰比。components/SpringValue.qml がそのまま解く。
// 個別に Easing や固定 duration を書かず、必ずここの仕様を渡す。
Singleton {
    readonly property var spatialFast:    ({ stiffness: 800,  damping: 0.6 })
    readonly property var spatialDefault: ({ stiffness: 380,  damping: 0.8 })
    readonly property var spatialSlow:    ({ stiffness: 200,  damping: 0.8 })

    readonly property var effectsFast:    ({ stiffness: 3800, damping: 1.0 })
    readonly property var effectsDefault: ({ stiffness: 1600, damping: 1.0 })
    readonly property var effectsSlow:    ({ stiffness: 800,  damping: 1.0 })
}
