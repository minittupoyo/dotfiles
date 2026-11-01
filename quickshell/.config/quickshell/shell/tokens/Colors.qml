pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// M3 カラートークン。matugen が生成する colors.json を監視して即反映する。
// 生成元: ~/.config/matugen/templates/colors.json (scripts/apply-wallpaper.sh)
// 公開名は m3 接頭辞 (m3Primary, m3OnSurface ...)。
// 注意: QML は on + 大文字で始まる名前 (onSurface 等) をシグナルハンドラとして扱い、
//       プロパティ宣言が黙って無効 (値が #000000) になるため、接頭辞が必須。
// ここ以外で色を直書きしない。初期値はファイル読み込み前のフォールバック(M3 ダーク)。
Singleton {
    id: root

    readonly property string path: Quickshell.env("HOME") + "/.local/state/quickshell/colors.json"

    FileView {
        path: root.path
        watchChanges: true
        onFileChanged: reload()
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

    readonly property color m3Background: j.background
    readonly property color m3Error: j.error
    readonly property color m3ErrorContainer: j.error_container
    readonly property color m3InverseOnSurface: j.inverse_on_surface
    readonly property color m3InversePrimary: j.inverse_primary
    readonly property color m3InverseSurface: j.inverse_surface
    readonly property color m3OnBackground: j.on_background
    readonly property color m3OnError: j.on_error
    readonly property color m3OnErrorContainer: j.on_error_container
    readonly property color m3OnPrimary: j.on_primary
    readonly property color m3OnPrimaryContainer: j.on_primary_container
    readonly property color m3OnPrimaryFixed: j.on_primary_fixed
    readonly property color m3OnPrimaryFixedVariant: j.on_primary_fixed_variant
    readonly property color m3OnSecondary: j.on_secondary
    readonly property color m3OnSecondaryContainer: j.on_secondary_container
    readonly property color m3OnSecondaryFixed: j.on_secondary_fixed
    readonly property color m3OnSecondaryFixedVariant: j.on_secondary_fixed_variant
    readonly property color m3OnSurface: j.on_surface
    readonly property color m3OnSurfaceVariant: j.on_surface_variant
    readonly property color m3OnTertiary: j.on_tertiary
    readonly property color m3OnTertiaryContainer: j.on_tertiary_container
    readonly property color m3OnTertiaryFixed: j.on_tertiary_fixed
    readonly property color m3OnTertiaryFixedVariant: j.on_tertiary_fixed_variant
    readonly property color m3Outline: j.outline
    readonly property color m3OutlineVariant: j.outline_variant
    readonly property color m3Primary: j.primary
    readonly property color m3PrimaryContainer: j.primary_container
    readonly property color m3PrimaryFixed: j.primary_fixed
    readonly property color m3PrimaryFixedDim: j.primary_fixed_dim
    readonly property color m3Scrim: j.scrim
    readonly property color m3Secondary: j.secondary
    readonly property color m3SecondaryContainer: j.secondary_container
    readonly property color m3SecondaryFixed: j.secondary_fixed
    readonly property color m3SecondaryFixedDim: j.secondary_fixed_dim
    readonly property color m3Shadow: j.shadow
    readonly property color m3SourceColor: j.source_color
    readonly property color m3Surface: j.surface
    readonly property color m3SurfaceBright: j.surface_bright
    readonly property color m3SurfaceContainer: j.surface_container
    readonly property color m3SurfaceContainerHigh: j.surface_container_high
    readonly property color m3SurfaceContainerHighest: j.surface_container_highest
    readonly property color m3SurfaceContainerLow: j.surface_container_low
    readonly property color m3SurfaceContainerLowest: j.surface_container_lowest
    readonly property color m3SurfaceDim: j.surface_dim
    readonly property color m3SurfaceTint: j.surface_tint
    readonly property color m3SurfaceVariant: j.surface_variant
    readonly property color m3Tertiary: j.tertiary
    readonly property color m3TertiaryContainer: j.tertiary_container
    readonly property color m3TertiaryFixed: j.tertiary_fixed
    readonly property color m3TertiaryFixedDim: j.tertiary_fixed_dim
}
