pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// M3 カラートークン。matugen が生成する colors.json を監視して反映する。
// 生成元: ~/.config/matugen/templates/colors.json (scripts/apply-wallpaper.sh)
//
// 公開名は m3 接頭辞 (m3Primary, m3OnSurface ...)。
// 注意: QML は on + 大文字で始まる名前 (onSurface 等) をシグナルハンドラとして扱い、
//       プロパティ宣言が黙って無効 (値が #000000) になるため、接頭辞が必須。
// ここ以外で色を直書きしない。初期値はファイル読み込み前のフォールバック(M3 ダーク)。
//
// 配色が変わると、切り替え前の色から新しい色へ Motion.effectsSlow のスプリングで補間する。
// 進行度のスプリングは 1 つだけで、各ロールは (切り替え前, 新しい色) の混合にしている。
// 起動時の初回読み込みでは補間しない (fileChanged が出ないため)。
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.local/state/quickshell/colors.json"

    // 補間の進行度 (0 = 切り替え前 / 1 = 新しい色)
    readonly property real progress: spring.value
    // 補間を止めたいとき (負荷の計測など) は false にする
    property bool animate: true

    property var _prev: ({})

    SpringValue {
        id: spring
        target: 1
        value: 1
        spec: Motion.effectsSlow
        epsilon: 0.001
    }

    function _mix(a, b, t) {
        if (t >= 1 || !a)
            return b;
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
    }

    // 今表示している色 (補間の途中でも連続になる) を丸ごと控える。
    // 表示用プロパティを明示的に読む (JsonAdapter への動的キー参照は undefined になった)
    function _snapshot() {
        const o = {};
        o.background = m3Background;
        o.error = m3Error;
        o.error_container = m3ErrorContainer;
        o.inverse_on_surface = m3InverseOnSurface;
        o.inverse_primary = m3InversePrimary;
        o.inverse_surface = m3InverseSurface;
        o.on_background = m3OnBackground;
        o.on_error = m3OnError;
        o.on_error_container = m3OnErrorContainer;
        o.on_primary = m3OnPrimary;
        o.on_primary_container = m3OnPrimaryContainer;
        o.on_primary_fixed = m3OnPrimaryFixed;
        o.on_primary_fixed_variant = m3OnPrimaryFixedVariant;
        o.on_secondary = m3OnSecondary;
        o.on_secondary_container = m3OnSecondaryContainer;
        o.on_secondary_fixed = m3OnSecondaryFixed;
        o.on_secondary_fixed_variant = m3OnSecondaryFixedVariant;
        o.on_surface = m3OnSurface;
        o.on_surface_variant = m3OnSurfaceVariant;
        o.on_tertiary = m3OnTertiary;
        o.on_tertiary_container = m3OnTertiaryContainer;
        o.on_tertiary_fixed = m3OnTertiaryFixed;
        o.on_tertiary_fixed_variant = m3OnTertiaryFixedVariant;
        o.outline = m3Outline;
        o.outline_variant = m3OutlineVariant;
        o.primary = m3Primary;
        o.primary_container = m3PrimaryContainer;
        o.primary_fixed = m3PrimaryFixed;
        o.primary_fixed_dim = m3PrimaryFixedDim;
        o.scrim = m3Scrim;
        o.secondary = m3Secondary;
        o.secondary_container = m3SecondaryContainer;
        o.secondary_fixed = m3SecondaryFixed;
        o.secondary_fixed_dim = m3SecondaryFixedDim;
        o.shadow = m3Shadow;
        o.source_color = m3SourceColor;
        o.surface = m3Surface;
        o.surface_bright = m3SurfaceBright;
        o.surface_container = m3SurfaceContainer;
        o.surface_container_high = m3SurfaceContainerHigh;
        o.surface_container_highest = m3SurfaceContainerHighest;
        o.surface_container_low = m3SurfaceContainerLow;
        o.surface_container_lowest = m3SurfaceContainerLowest;
        o.surface_dim = m3SurfaceDim;
        o.surface_tint = m3SurfaceTint;
        o.surface_variant = m3SurfaceVariant;
        o.tertiary = m3Tertiary;
        o.tertiary_container = m3TertiaryContainer;
        o.tertiary_fixed = m3TertiaryFixed;
        o.tertiary_fixed_dim = m3TertiaryFixedDim;
        _prev = o;
    }

    FileView {
        path: root.path
        watchChanges: true
        // 起動時の初回読み込みでは fileChanged が出ないので、そこでは補間されない
        onFileChanged: {
            if (root.animate) {
                root._snapshot();
                spring.snap(0);          // 表示は切り替え前の色のまま (進行度 0)
            }
            reload();
        }
        // 新しい値が入ったら 0 → 1 に動かす。loaded は変更が空振りしたとき 0 で止まらないための保険
        onAdapterUpdated: spring.target = 1
        onLoaded: spring.target = 1
        onLoadFailed: error => console.warn("Colors: failed to load", root.path, FileViewError.toString(error))

        JsonAdapter {
            id: j
            property color background: "#0f141a"
            property color error: "#ffb4ab"
            property color error_container: "#93000a"
            property color inverse_on_surface: "#2c3137"
            property color inverse_primary: "#596414"
            property color inverse_surface: "#dfe2eb"
            property color on_background: "#dfe2eb"
            property color on_error: "#690005"
            property color on_error_container: "#ffdad6"
            property color on_primary: "#2d3400"
            property color on_primary_container: "#ddea8c"
            property color on_primary_fixed: "#191e00"
            property color on_primary_fixed_variant: "#424b00"
            property color on_secondary: "#412742"
            property color on_secondary_container: "#fdd7fa"
            property color on_secondary_fixed: "#2a132c"
            property color on_secondary_fixed_variant: "#593d5a"
            property color on_surface: "#dfe2eb"
            property color on_surface_variant: "#bfc7d5"
            property color on_tertiary: "#043256"
            property color on_tertiary_container: "#d1e4ff"
            property color on_tertiary_fixed: "#001d36"
            property color on_tertiary_fixed_variant: "#24496e"
            property color outline: "#89919e"
            property color outline_variant: "#3f4753"
            property color primary: "#c1ce73"
            property color primary_container: "#424b00"
            property color primary_fixed: "#ddea8c"
            property color primary_fixed_dim: "#c1ce73"
            property color scrim: "#000000"
            property color secondary: "#e0bbde"
            property color secondary_container: "#593d5a"
            property color secondary_fixed: "#fdd7fa"
            property color secondary_fixed_dim: "#e0bbde"
            property color shadow: "#000000"
            property color source_color: "#0286bb"
            property color surface: "#0f141a"
            property color surface_bright: "#353940"
            property color surface_container: "#1b2026"
            property color surface_container_high: "#262a31"
            property color surface_container_highest: "#30353c"
            property color surface_container_low: "#171c22"
            property color surface_container_lowest: "#0a0f14"
            property color surface_dim: "#0f141a"
            property color surface_tint: "#c1ce73"
            property color surface_variant: "#3f4753"
            property color tertiary: "#a6c9f6"
            property color tertiary_container: "#24496e"
            property color tertiary_fixed: "#d1e4ff"
            property color tertiary_fixed_dim: "#a6c9f6"
        }
    }

    readonly property color m3Background: _mix(_prev.background, j.background, spring.value)
    readonly property color m3Error: _mix(_prev.error, j.error, spring.value)
    readonly property color m3ErrorContainer: _mix(_prev.error_container, j.error_container, spring.value)
    readonly property color m3InverseOnSurface: _mix(_prev.inverse_on_surface, j.inverse_on_surface, spring.value)
    readonly property color m3InversePrimary: _mix(_prev.inverse_primary, j.inverse_primary, spring.value)
    readonly property color m3InverseSurface: _mix(_prev.inverse_surface, j.inverse_surface, spring.value)
    readonly property color m3OnBackground: _mix(_prev.on_background, j.on_background, spring.value)
    readonly property color m3OnError: _mix(_prev.on_error, j.on_error, spring.value)
    readonly property color m3OnErrorContainer: _mix(_prev.on_error_container, j.on_error_container, spring.value)
    readonly property color m3OnPrimary: _mix(_prev.on_primary, j.on_primary, spring.value)
    readonly property color m3OnPrimaryContainer: _mix(_prev.on_primary_container, j.on_primary_container, spring.value)
    readonly property color m3OnPrimaryFixed: _mix(_prev.on_primary_fixed, j.on_primary_fixed, spring.value)
    readonly property color m3OnPrimaryFixedVariant: _mix(_prev.on_primary_fixed_variant, j.on_primary_fixed_variant, spring.value)
    readonly property color m3OnSecondary: _mix(_prev.on_secondary, j.on_secondary, spring.value)
    readonly property color m3OnSecondaryContainer: _mix(_prev.on_secondary_container, j.on_secondary_container, spring.value)
    readonly property color m3OnSecondaryFixed: _mix(_prev.on_secondary_fixed, j.on_secondary_fixed, spring.value)
    readonly property color m3OnSecondaryFixedVariant: _mix(_prev.on_secondary_fixed_variant, j.on_secondary_fixed_variant, spring.value)
    readonly property color m3OnSurface: _mix(_prev.on_surface, j.on_surface, spring.value)
    readonly property color m3OnSurfaceVariant: _mix(_prev.on_surface_variant, j.on_surface_variant, spring.value)
    readonly property color m3OnTertiary: _mix(_prev.on_tertiary, j.on_tertiary, spring.value)
    readonly property color m3OnTertiaryContainer: _mix(_prev.on_tertiary_container, j.on_tertiary_container, spring.value)
    readonly property color m3OnTertiaryFixed: _mix(_prev.on_tertiary_fixed, j.on_tertiary_fixed, spring.value)
    readonly property color m3OnTertiaryFixedVariant: _mix(_prev.on_tertiary_fixed_variant, j.on_tertiary_fixed_variant, spring.value)
    readonly property color m3Outline: _mix(_prev.outline, j.outline, spring.value)
    readonly property color m3OutlineVariant: _mix(_prev.outline_variant, j.outline_variant, spring.value)
    readonly property color m3Primary: _mix(_prev.primary, j.primary, spring.value)
    readonly property color m3PrimaryContainer: _mix(_prev.primary_container, j.primary_container, spring.value)
    readonly property color m3PrimaryFixed: _mix(_prev.primary_fixed, j.primary_fixed, spring.value)
    readonly property color m3PrimaryFixedDim: _mix(_prev.primary_fixed_dim, j.primary_fixed_dim, spring.value)
    readonly property color m3Scrim: _mix(_prev.scrim, j.scrim, spring.value)
    readonly property color m3Secondary: _mix(_prev.secondary, j.secondary, spring.value)
    readonly property color m3SecondaryContainer: _mix(_prev.secondary_container, j.secondary_container, spring.value)
    readonly property color m3SecondaryFixed: _mix(_prev.secondary_fixed, j.secondary_fixed, spring.value)
    readonly property color m3SecondaryFixedDim: _mix(_prev.secondary_fixed_dim, j.secondary_fixed_dim, spring.value)
    readonly property color m3Shadow: _mix(_prev.shadow, j.shadow, spring.value)
    readonly property color m3SourceColor: _mix(_prev.source_color, j.source_color, spring.value)
    readonly property color m3Surface: _mix(_prev.surface, j.surface, spring.value)
    readonly property color m3SurfaceBright: _mix(_prev.surface_bright, j.surface_bright, spring.value)
    readonly property color m3SurfaceContainer: _mix(_prev.surface_container, j.surface_container, spring.value)
    readonly property color m3SurfaceContainerHigh: _mix(_prev.surface_container_high, j.surface_container_high, spring.value)
    readonly property color m3SurfaceContainerHighest: _mix(_prev.surface_container_highest, j.surface_container_highest, spring.value)
    readonly property color m3SurfaceContainerLow: _mix(_prev.surface_container_low, j.surface_container_low, spring.value)
    readonly property color m3SurfaceContainerLowest: _mix(_prev.surface_container_lowest, j.surface_container_lowest, spring.value)
    readonly property color m3SurfaceDim: _mix(_prev.surface_dim, j.surface_dim, spring.value)
    readonly property color m3SurfaceTint: _mix(_prev.surface_tint, j.surface_tint, spring.value)
    readonly property color m3SurfaceVariant: _mix(_prev.surface_variant, j.surface_variant, spring.value)
    readonly property color m3Tertiary: _mix(_prev.tertiary, j.tertiary, spring.value)
    readonly property color m3TertiaryContainer: _mix(_prev.tertiary_container, j.tertiary_container, spring.value)
    readonly property color m3TertiaryFixed: _mix(_prev.tertiary_fixed, j.tertiary_fixed, spring.value)
    readonly property color m3TertiaryFixedDim: _mix(_prev.tertiary_fixed_dim, j.tertiary_fixed_dim, spring.value)
}
