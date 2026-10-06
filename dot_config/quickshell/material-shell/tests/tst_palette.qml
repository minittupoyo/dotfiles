import QtQuick
import QtTest
import ".."

TestCase {
    name: "PaletteValidation"
    property var original: ({})
    function init() { original = Theme.palette; }
    function cleanup() { Theme.palette = original; }
    function test_invalid_input_retains_previous_palette() {
        Theme.palette = {primary: "#abcdef"};
        Theme.acceptPalette("{broken");
        compare(Theme.primary, "#abcdef");
        Theme.acceptPalette(JSON.stringify({version: 1, colors: {primary: "#123456"}}));
        compare(Theme.primary, "#abcdef");
    }
    function test_missing_palette_uses_fallback() {
        Theme.palette = {};
        compare(Theme.primary, "#b4cea5");
        compare(Theme.surfaceContainer, "#1e211d");
    }
    function test_complete_palette_updates_all_roles() {
        const roles = ["surface", "surface_container", "surface_container_high", "surface_container_highest",
            "on_surface", "on_surface_variant", "outline_variant", "primary", "secondary_container",
            "on_secondary_container", "error", "inverse_surface", "inverse_on_surface"];
        const colors = {};
        roles.forEach(role => colors[role] = "#abcdef");
        Theme.acceptPalette(JSON.stringify({version: 1, colors: colors}));
        compare(Theme.primary, "#abcdef");
        compare(Theme.panelBackground, "#abcdef");
        compare(Theme.inverseSurfaceText, "#abcdef");
        colors.primary = "invalid";
        Theme.acceptPalette(JSON.stringify({version: 1, colors: colors}));
        compare(Theme.primary, "#abcdef");
    }
}
