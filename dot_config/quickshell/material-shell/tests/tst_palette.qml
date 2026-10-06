import QtQuick
import QtTest
import ".."

TestCase {
    name: "PaletteValidation"
    property var original: ({})
    property var originalSchemes: ({})
    property string originalMode: "dark"
    function init() { original = Theme.palette; originalSchemes = Theme.schemes; originalMode = Theme.mode; }
    function cleanup() { Theme.mode = originalMode; Theme.schemes = originalSchemes; Theme.palette = original; }
    function test_invalid_input_retains_previous_palette() {
        Theme.palette = {primary: "#abcdef"};
        Theme.acceptPalette("{broken");
        compare(Theme.primary, "#abcdef");
        Theme.acceptPalette(JSON.stringify({version: 1, colors: {primary: "#123456"}}));
        compare(Theme.primary, "#abcdef");
    }
    function test_missing_palette_uses_fallback() {
        Theme.setMode("dark");
        Theme.palette = {};
        compare(Theme.primary, "#b4cea5");
        compare(Theme.surfaceContainer, "#1e211d");
        compare(Theme.outline, "#8e9387");
    }
    function test_light_fallback_and_palette_mode_switch() {
        Theme.schemes = {};
        Theme.palette = {};
        Theme.setMode("light");
        compare(Theme.surface.toString(), "#f8f9ff");
        compare(Theme.surfaceText.toString(), "#191c20");
        const roles = ["surface", "surface_container", "surface_container_high", "surface_container_highest",
            "on_surface", "on_surface_variant", "outline_variant", "primary", "secondary_container",
            "on_secondary_container", "error", "inverse_surface", "inverse_on_surface"];
        const light = {}, dark = {};
        roles.forEach(role => { light[role] = "#abcdef"; dark[role] = "#123456"; });
        Theme.acceptPalette(JSON.stringify({version: 2, schemes: {light: light, dark: dark}}));
        compare(Theme.primary.toString(), "#abcdef");
        Theme.setMode("dark");
        compare(Theme.primary.toString(), "#123456");
    }
    function test_legacy_palette_without_outline_is_accepted() {
        const roles = ["surface", "surface_container", "surface_container_high", "surface_container_highest",
            "on_surface", "on_surface_variant", "outline_variant", "primary", "secondary_container",
            "on_secondary_container", "error", "inverse_surface", "inverse_on_surface"];
        const colors = {};
        roles.forEach(role => colors[role] = "#abcdef");
        Theme.acceptPalette(JSON.stringify({version: 1, colors: colors}));
        compare(Theme.primary.toString(), "#abcdef");
        compare(Theme.outline.toString(), "#8e9387");
        compare(Theme.errorContainer.toString(), "#93000a");
    }
    function test_complete_palette_updates_all_roles() {
        const roles = ["surface", "surface_container", "surface_container_high", "surface_container_highest",
            "on_surface", "on_surface_variant", "outline", "outline_variant", "primary", "secondary_container",
            "on_secondary_container", "error", "on_error", "error_container", "on_error_container", "inverse_surface", "inverse_on_surface"];
        const colors = {};
        roles.forEach(role => colors[role] = "#abcdef");
        Theme.acceptPalette(JSON.stringify({version: 1, colors: colors}));
        compare(Theme.primary, "#abcdef");
        compare(Theme.outline, "#abcdef");
        compare(Theme.errorContainer.toString(), "#abcdef");
        compare(Theme.panelBackground, "#abcdef");
        compare(Theme.inverseSurfaceText, "#abcdef");
        colors.primary = "invalid";
        Theme.acceptPalette(JSON.stringify({version: 1, colors: colors}));
        compare(Theme.primary, "#abcdef");
    }
}
