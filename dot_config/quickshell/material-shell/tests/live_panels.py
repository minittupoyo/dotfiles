#!/usr/bin/env python3
"""Check panel geometry and empty/confirmation states with isolated backends."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
fixture = '''import Quickshell
import QtQuick
import QtTest
import "./material-shell"
ShellRoot {
 QtObject { id: notifications; property var history: [] }
 ControlPanel { id: panel; opened: true; screen: Quickshell.screens[Number(Quickshell.env("PANEL_TEST_SCREEN"))]; notificationService: notifications; onDismissed: opened = false }
 SessionMenu { id: session; screen: panel.screen; onDismissed: opened = false }
 Launcher { id: launcher; screen: panel.screen; onDismissed: opened = false }
 WallpaperSelector { id: wallpaper; screen: panel.screen; onDismissed: opened = false }
 TestCase {
  name: "PanelLayouts"; when: true
  function cleanupTestCase() { console.warn("Panel tests: passed=" + qtest_results.passCount + " failed=" + qtest_results.failCount); }
  function cleanup() { console.warn("Completed " + qtest_results.functionName + " failures=" + qtest_results.failCount); }
  function init() { session.opened = false; launcher.opened = false; wallpaper.opened = false; panel.opened = true; panel.tab = "quick"; wait(400); }
  function test_quick_groups_stay_together() {
   const grid = findChild(panel, "quickTiles"), volume = findChild(panel, "quickVolume");
   verify(grid.y <= Theme.space4);
   compare(Math.round(volume.y - grid.y - grid.height), Theme.space16);
   verify(grid.height <= Theme.quickSettingTileHeight * 2 + Theme.space8);
  }
  function test_tabs_keep_usable_content_width() {
   const body = findChild(panel, "controlBody");
   for (const tab of panel.tabs) { panel.selectTab(tab.name); wait(100); verify(body.width >= Theme.mediaEmptyContentWidth); verify(body.height > Theme.listRowHeight * 3); }
  }
  function test_notification_empty_state_fills_view() {
   panel.tab = "notifications"; wait(100);
   const empty = findChild(panel, "notificationEmptyState");
   verify(empty.visible); verify(empty.width > Theme.emptyStateContentWidth); verify(empty.height >= empty.implicitHeight);
  }
  function test_session_confirmation_does_not_execute() {
   panel.opened = false; session.opened = true; wait(400);
   session.choose("poweroff"); compare(session.pendingAction, "poweroff"); compare(session.executing, false);
   session.pendingAction = ""; compare(session.executing, false);
  }
  function test_launcher_empty_search() {
   panel.opened = false; launcher.opened = true; wait(400);
   launcher.setQuery("__material_panel_no_application__"); compare(launcher.results.length, 0); verify(launcher.visible);
  }
  function test_wallpaper_empty_library() {
   panel.opened = false; wallpaper.opened = true; wait(400);
   tryVerify(() => !JSON.parse(wallpaper.status()).scanning); compare(wallpaper.results.length, 0); compare(wallpaper.busy, false);
  }
 }
}'''
state = {"wifi": False, "wifiAvailable": False, "wifiConnected": "", "wifiNetworks": [],
         "bluetooth": False, "bluetoothAvailable": False, "bluetoothDevices": []}
for screen in (0, 1):
    with tempfile.TemporaryDirectory(prefix="material-panel-tests-") as directory:
        tmp = Path(directory)
        (tmp / "material-shell").symlink_to(root, target_is_directory=True)
        (tmp / "shell.qml").write_text(fixture)
        helpers = tmp / "bin"
        helpers.mkdir()
        for name, data in {"material-control": state, "material-clipboard": [],
                           "material-wallpapers": {"images": [], "directories": [], "current": ""}}.items():
            helper = helpers / name
            helper.write_text("#!/usr/bin/env python3\nprint(" + repr(json.dumps(data)) + ")\n")
            helper.chmod(0o755)
        env = dict(os.environ, MATERIAL_SHELL_CLI_DIR=str(helpers),
                   FONTCONFIG_FILE=str(root / "fonts.conf"), PANEL_TEST_SCREEN=str(screen),
                   XDG_CONFIG_HOME=str(tmp / "config"), XDG_STATE_HOME=str(tmp / "state"))
        result = subprocess.run(["quickshell", "-p", str(tmp), "--no-color"],
                                env=env, capture_output=True, text=True, timeout=30)
        output = result.stdout + result.stderr
        print(f"Screen {screen}:\n{output}")
        if result.returncode or "Panel tests: passed=" not in output or "failed=0" not in output:
            raise SystemExit(f"Panel tests failed on screen {screen}")
