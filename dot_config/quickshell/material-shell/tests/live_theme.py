#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

root = Path(__file__).resolve().parents[1]
fixture = '''import Quickshell
import Quickshell.Io
import QtQuick
import QtTest
import "./material-shell"
ShellRoot {
 Connections {
  target: Settings
  function onValuesChanged() { Theme.setMode(Settings.values.themeMode || "dark"); }
  function onSaveRequested(data) { worker.command = ["@@PYTHON@@", "@@SETTINGS@@", "set", JSON.stringify(data)]; worker.running = true; }
 }
 Process { id: worker; stdout: SplitParser { onRead: data => Settings.values = JSON.parse(data) } stderr: SplitParser { onRead: data => console.warn("Settings helper:", data) } onExited: (code, status) => { if (code !== 0) console.warn("Settings helper failed:", code); Settings.saving = false; } }
 FileView { path: "@@PALETTE@@"; preload: true; printErrors: false; onLoaded: Theme.acceptPalette(text()) }
 ControlPanel {
  id: panel
  opened: true
  screen: Quickshell.screens[Number(Quickshell.env("PANEL_TEST_SCREEN") || "0")]
  tab: "settings"
 }
 TestCase {
  name: "ThemeSwitch"; when: true
  function cleanupTestCase() { console.warn("Theme tests: passed=" + qtest_results.passCount + " failed=" + qtest_results.failCount); }
  function test_light_mode_saves_and_applies_wallpaper_palette() {
   const button = findChild(panel, "themeModeLight");
   verify(!!button); compare(Theme.mode, "dark");
   tryVerify(() => !!Theme.schemes.light && !!Theme.schemes.dark);
   compare(Theme.surface.toString(), "#18212a");
   tryCompare(panel, "offsetScale", 0);
   mouseClick(button, button.width / 2, button.height / 2);
   tryCompare(Settings, "saving", false);
   tryVerify(() => Settings.values.themeMode === "light");
   tryVerify(() => Theme.mode === "light");
   compare(Theme.surface.toString(), "#e7eef5");
   verify(button.emphasized);
   const darkButton = findChild(panel, "themeModeDark");
   mouseClick(darkButton, darkButton.width / 2, darkButton.height / 2);
   tryVerify(() => Settings.values.themeMode === "dark");
   tryCompare(Settings, "saving", false);
   compare(Theme.mode, "dark");
   compare(Theme.surface.toString(), "#18212a");
   verify(darkButton.emphasized); verify(!button.emphasized);
  }
 }
}'''

settings_source = root.parents[2] / "dot_local/lib/material-shell/settings.py"
if not settings_source.is_file():
    settings_source = Path.home() / ".local/lib/material-shell/settings.py"
roles = ("surface", "surface_container", "surface_container_high", "surface_container_highest",
         "on_surface", "on_surface_variant", "outline_variant", "primary", "secondary_container",
         "on_secondary_container", "error", "inverse_surface", "inverse_on_surface")
palette = {"version": 2, "schemes": {
    "light": dict.fromkeys(roles, "#e7eef5"),
    "dark": dict.fromkeys(roles, "#18212a"),
}}
for screen in (0, 1):
    with tempfile.TemporaryDirectory(prefix="material-theme-tests-") as directory:
        tmp = Path(directory)
        module_dir = tmp / "material-shell"
        module_dir.symlink_to(root, target_is_directory=True)
        config_dir = tmp / "config"
        config_dir.mkdir()
        state_dir = tmp / "state/material-shell"
        state_dir.mkdir(parents=True)
        palette_path = state_dir / "palette.json"
        palette_path.write_text(json.dumps(palette))
        (tmp / "shell.qml").write_text(fixture.replace("@@PYTHON@@", sys.executable)
                                      .replace("@@SETTINGS@@", str(settings_source))
                                      .replace("@@PALETTE@@", str(palette_path)))
        env = dict(os.environ, XDG_CONFIG_HOME=str(config_dir), XDG_STATE_HOME=str(tmp / "state"),
                   FONTCONFIG_FILE=str(root / "fonts.conf"), PANEL_TEST_SCREEN=str(screen))
        result = subprocess.run(["quickshell", "-p", str(tmp), "--no-color"], env=env,
                                capture_output=True, text=True, timeout=25)
        output = f"Screen {screen}:\n" + result.stdout + result.stderr
        print(output)
        if result.returncode != 0 or "Theme tests: passed=" not in output or "failed=0" not in output:
            raise SystemExit(f"Theme tests failed on screen {screen}")
        saved = json.loads((config_dir / "material-shell/settings.json").read_text())
        if saved.get("themeMode") != "dark":
            raise SystemExit(f"Theme preference was not saved on screen {screen}")
