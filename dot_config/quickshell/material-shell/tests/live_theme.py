#!/usr/bin/env python3
import json
import os
from pathlib import Path
import shutil
import subprocess
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
  function onSaveRequested(data) { worker.command = ["@@HELPER@@", "set", JSON.stringify(data)]; worker.running = true; }
 }
 Process { id: worker; stdout: SplitParser { onRead: data => Settings.values = JSON.parse(data) } onExited: (code, status) => Settings.saving = false }
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
   mouseClick(button, button.width / 2, button.height / 2);
   tryCompare(Settings, "saving", false);
   tryVerify(() => Settings.values.themeMode === "light");
   tryVerify(() => Theme.mode === "light");
   compare(Theme.surface.toString(), "#f8f9ff");
   verify(button.emphasized);
  }
 }
}'''

palette_source = Path.home() / ".local/state/material-shell/palette.json"
for screen in (0, 1):
    with tempfile.TemporaryDirectory(prefix="material-theme-tests-") as directory:
        tmp = Path(directory)
        module_dir = tmp / "material-shell"
        module_dir.symlink_to(root, target_is_directory=True)
        state_dir = tmp / "state/material-shell"
        state_dir.mkdir(parents=True)
        shutil.copy2(palette_source, state_dir / "palette.json")
        palette_path = state_dir / "palette.json"
        (tmp / "shell.qml").write_text(fixture.replace("@@HELPER@@", str(Path.home() / ".local/bin/material-settings"))
                                      .replace("@@PALETTE@@", str(palette_path)))
        env = dict(os.environ, XDG_CONFIG_HOME=str(tmp), XDG_STATE_HOME=str(tmp / "state"),
                   FONTCONFIG_FILE=str(root / "fonts.conf"), PANEL_TEST_SCREEN=str(screen))
        result = subprocess.run(["quickshell", "-p", str(tmp), "--no-color"], env=env,
                                capture_output=True, text=True, timeout=25)
        output = f"Screen {screen}:\n" + result.stdout + result.stderr
        print(output)
        if "Theme tests: passed=" not in output or "failed=0" not in output:
            raise SystemExit(f"Theme tests failed on screen {screen}")
        saved = json.loads((tmp / "material-shell/settings.json").read_text())
        if saved.get("themeMode") != "light":
            raise SystemExit(f"Theme preference was not saved on screen {screen}")
