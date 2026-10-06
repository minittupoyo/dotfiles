pragma Singleton
import QtQuick

QtObject {
    id: theme
    property var palette: ({})
    property var schemes: ({})
    property string mode: "dark"
    property bool reducedMotion: false
    property string palettePath: ""
    readonly property var fallbackPalette: mode === "light" ? ({
        surface: "#f8f9ff", surface_container: "#eceef4", surface_container_high: "#e6e8ee",
        surface_container_highest: "#e1e2e8", on_surface: "#191c20", on_surface_variant: "#42474e",
        outline: "#73777f", outline_variant: "#c3c7cf", primary: "#35618e", on_primary: "#ffffff",
        primary_container: "#d1e4ff", on_primary_container: "#001d36", secondary_container: "#d6e3f7",
        on_secondary_container: "#101c2b", error: "#ba1a1a", on_error: "#ffffff",
        error_container: "#ffdad6", on_error_container: "#410002", inverse_surface: "#2e3135",
        inverse_on_surface: "#eff0f7"
    }) : ({
        surface: "#121411", surface_container: "#1e211d", surface_container_high: "#282b26",
        surface_container_highest: "#333630", on_surface: "#e2e3dc", on_surface_variant: "#c3c8bd",
        outline: "#8e9387", outline_variant: "#43483f", primary: "#b4cea5", on_primary: "#263422",
        primary_container: "#3c4b37", on_primary_container: "#d8e7cc", secondary_container: "#3c4b37",
        on_secondary_container: "#d8e7cc", error: "#ffb4ab", on_error: "#690005",
        error_container: "#93000a", on_error_container: "#ffdad6", inverse_surface: "#e2e3dc",
        inverse_on_surface: "#2f322c"
    })
    function setMode(value) {
        if (value !== "light" && value !== "dark") return;
        mode = value;
        palette = schemes[mode] || {};
    }
    function validColors(colors) {
        const required = ["surface", "surface_container", "surface_container_high", "surface_container_highest",
            "on_surface", "on_surface_variant", "outline_variant", "primary", "secondary_container",
            "on_secondary_container", "error", "inverse_surface", "inverse_on_surface"];
        if (!colors || !required.every(key => typeof colors[key] === "string" && /^#[0-9a-fA-F]{6}$/.test(colors[key]))) return false;
        const optional = ["outline", "on_primary", "primary_container", "on_primary_container", "on_error", "error_container", "on_error_container"];
        return optional.every(key => colors[key] === undefined || (typeof colors[key] === "string" && /^#[0-9a-fA-F]{6}$/.test(colors[key])));
    }
    function acceptPalette(text) {
        try {
            const data = JSON.parse(text);
            let nextSchemes;
            if (data.version === 2 && data.schemes && validColors(data.schemes.light) && validColors(data.schemes.dark)) {
                nextSchemes = data.schemes;
            } else if (data.version === 1 && validColors(data.colors)) {
                nextSchemes = data.mode === "light" ? {light: data.colors} : {dark: data.colors};
            } else throw new Error("Incomplete palette");
            schemes = nextSchemes;
            palette = schemes[mode] || {};
        } catch (error) { console.warn("Keeping previous palette:", error); }
    }
    readonly property string fontFamily: "Inter"

    // Primitives: approved spacing, type and shape scales.
    readonly property int space4: 4
    readonly property int space8: 8
    readonly property int space12: 12
    readonly property int space16: 16
    readonly property int space24: 24
    readonly property int space32: 32
    readonly property int displayLargeSize: 57
    readonly property int headlineSmallSize: 24
    readonly property int titleLargeSize: 22
    readonly property int titleMediumSize: 16
    readonly property int titleSmallSize: 14
    readonly property int bodyLargeSize: 16
    readonly property int bodyMediumSize: 14
    readonly property int bodySmallSize: 12
    readonly property int labelLargeSize: 14
    readonly property int labelMediumSize: 12
    readonly property int labelSmallSize: 11
    readonly property int displayLargeLineHeight: 64
    readonly property int headlineSmallLineHeight: 32
    readonly property int titleLargeLineHeight: 28
    readonly property int titleMediumLineHeight: 24
    readonly property int titleSmallLineHeight: 20
    readonly property int bodyLargeLineHeight: 24
    readonly property int bodyMediumLineHeight: 20
    readonly property int bodySmallLineHeight: 16
    readonly property int labelLargeLineHeight: 20
    readonly property int labelMediumLineHeight: 16
    readonly property int labelSmallLineHeight: 16
    readonly property int bodySize: bodyMediumSize
    readonly property int inputSize: bodyLargeSize
    readonly property int titleSize: titleLargeSize
    readonly property int iconSize: 20
    readonly property int appIconSize: 28
    readonly property int shapeSmall: 8
    readonly property int shapeMedium: 12
    readonly property int shapeExtraLarge: 32

    // Semantic roles: wallpaper-derived MD3 light/dark, mode-specific fallback.
    readonly property color surface: palette.surface || fallbackPalette.surface
    readonly property color surfaceContainer: palette.surface_container || fallbackPalette.surface_container
    readonly property color surfaceContainerHigh: palette.surface_container_high || fallbackPalette.surface_container_high
    readonly property color surfaceContainerHighest: palette.surface_container_highest || fallbackPalette.surface_container_highest
    readonly property color scrim: "#52000000"
    readonly property color surfaceText: palette.on_surface || fallbackPalette.on_surface
    readonly property color surfaceVariantText: palette.on_surface_variant || fallbackPalette.on_surface_variant
    readonly property color outline: palette.outline || fallbackPalette.outline
    readonly property color outlineVariant: palette.outline_variant || fallbackPalette.outline_variant
    readonly property color primary: palette.primary || fallbackPalette.primary
    readonly property color primaryText: palette.on_primary || fallbackPalette.on_primary
    readonly property color primaryContainer: palette.primary_container || fallbackPalette.primary_container
    readonly property color primaryContainerText: palette.on_primary_container || fallbackPalette.on_primary_container
    readonly property color secondaryContainer: palette.secondary_container || fallbackPalette.secondary_container
    readonly property color secondaryContainerText: palette.on_secondary_container || fallbackPalette.on_secondary_container
    readonly property color error: palette.error || fallbackPalette.error
    readonly property color errorText: palette.on_error || fallbackPalette.on_error
    readonly property color errorContainer: palette.error_container || fallbackPalette.error_container
    readonly property color errorContainerText: palette.on_error_container || fallbackPalette.on_error_container
    readonly property color inverseSurface: palette.inverse_surface || fallbackPalette.inverse_surface
    readonly property color inverseSurfaceText: palette.inverse_on_surface || fallbackPalette.inverse_on_surface

    // Component tokens.
    readonly property color panelBackground: surfaceContainerHigh
    readonly property color inputBackground: surfaceContainerHighest
    readonly property int panelPadding: space24
    readonly property int panelScreenMargin: space24
    readonly property int panelRadius: shapeExtraLarge
    readonly property int inputRadius: 24
    readonly property int popupRadius: 24
    readonly property int pressedRadius: 8
    readonly property int mediaActionWidth: 64
    readonly property int mediaEmptyContainerSize: 80
    readonly property int mediaEmptySymbolSize: 36
    readonly property int mediaEmptyContentWidth: 320
    readonly property int sessionPanelHeight: 208
    readonly property int sessionConfirmHeight: 280
    readonly property int sessionActionWidth: 88
    readonly property int sessionActionHeight: 96
    readonly property int sessionActionIconSize: 32
    readonly property int sessionActionLabelSize: 12
    readonly property int sessionActionLabelHeight: 16
    readonly property int sessionActionSpacing: space8
    readonly property int quickSettingTileHeight: 72
    readonly property int quickSettingIconSize: 24
    readonly property int quickSettingsWidth: 560
    readonly property int quickSettingsHeight: 680
    readonly property int quickTabWidth: 72
    readonly property int quickTabHeight: 56
    readonly property int quickTabIndicatorWidth: 56
    readonly property int quickTabIndicatorHeight: 32
    readonly property real motionSpring: 4
    readonly property real motionDamping: 0.85
    readonly property real motionEpsilon: 0.1
    readonly property int mediaPopupWidth: 400
    readonly property int mediaArtworkSize: 160
    readonly property int mediaBarWidth: 200
    readonly property int mediaPositionInterval: 1000
    readonly property int sliderHeight: 48
    readonly property int sliderTrackHeight: 16
    readonly property int sliderHandleWidth: 4
    readonly property int sliderHandlePressedWidth: 2
    readonly property int sliderHandleHeight: 44
    readonly property int sliderGap: 6
    readonly property int sliderInsideRadius: 2
    readonly property int sliderStopSize: 4
    readonly property int progressTrackHeight: 4
    readonly property int progressGap: 4
    readonly property int progressStopSize: 4
    readonly property int progressAmplitude: 3
    readonly property int progressWavelength: 40
    readonly property int progressWaveSpeed: 40
    readonly property int progressAmplitudeDuration: 500
    readonly property real progressAmplitudeStart: 0.1
    readonly property real progressAmplitudeEnd: 0.9
    readonly property real progressSpring: 4
    readonly property real progressDamping: 1
    readonly property real progressEpsilon: 0.0001
    readonly property int switchWidth: 48
    readonly property int switchHeight: 28
    readonly property int switchThumb: 20
    readonly property int notificationWidth: 360
    readonly property int osdWidth: 320
    readonly property int mediaOsdWidth: 400
    readonly property int mediaOsdArtworkSize: 56
    readonly property int osdVerticalPadding: space16
    readonly property int osdDuration: 1400
    readonly property int mediaOsdDuration: 4000
    readonly property int notificationDuration: 6000
    readonly property int notificationHistoryLimit: 100
    readonly property int wallpaperWidth: 880
    readonly property int wallpaperMaxHeight: 680
    readonly property int wallpaperRowHeight: 72
    readonly property int wallpaperThumbnailWidth: 80
    readonly property int wallpaperThumbnailHeight: 48
    readonly property int wallpaperCompactWidth: 600
    readonly property int launcherWidth: 560
    readonly property int launcherMaxHeight: 640
    readonly property int listRowHeight: 56
    readonly property int inputHeight: 48
    readonly property int buttonHeight: 40
    readonly property int barSidePadding: space16
    readonly property int launcherIconPadding: 6
    readonly property int separatorPadding: space12
    readonly property int workspaceSpacing: space4
    readonly property int barIconSize: 16
    readonly property int tooltipDelay: 500
    readonly property int barHeight: 48
    readonly property int controlHeight: 32
    readonly property int shapeFull: 16
    readonly property int shapeExtraSmall: 4
    readonly property int labelSize: 12
    readonly property int motionDuration: reducedMotion ? 0 : 160
    readonly property int panelMotionDuration: reducedMotion ? 0 : 320
    readonly property color hoverState: Qt.rgba(surfaceText.r, surfaceText.g, surfaceText.b, 0.08)
    readonly property color pressedState: Qt.rgba(surfaceText.r, surfaceText.g, surfaceText.b, 0.10)
}
