#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
fixture = '''import Quickshell
import Quickshell.Wayland
import QtQuick
import QtTest
import "./material-shell"

ShellRoot {
 property int buttonClicks: 0
 property int disabledClicks: 0
 property int tabChoices: 0
 property real sliderValue: 0.5
 PanelWindow {
  screen: Quickshell.screens[Number(Quickshell.env("PANEL_TEST_SCREEN") || "0")]
  anchors { top: true; bottom: true; left: true; right: true }
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  Rectangle { id: target; width: 100; height: 32 }
  Column {
   anchors.centerIn: parent
   spacing: 12
   ShellButton { id: tonalButton; objectName: "tonalButton"; text: "通常操作"; onClicked: buttonClicks++ }
   ShellButton { id: disabledButton; objectName: "disabledButton"; text: "無効"; enabled: false; onClicked: disabledClicks++ }
   Toggle { id: toggle; objectName: "expressiveSwitch"; Accessible.name: "テストスイッチ"; onToggled: checked = !checked }
   ControlTab { id: tab; objectName: "audioTab"; name: "audio"; label: "音声"; icon: "volume_up"; onChosen: { tabChoices++; selected = !selected; } }
   VolumeSlider { id: volumeSlider; objectName: "testVolumeSlider"; width: 300; value: sliderValue; onAdjusted: adjustedValue => sliderValue = adjustedValue }
  }
  TestCase {
   name: "ExpressiveControls"; when: true
   function cleanupTestCase() { console.warn("Controls tests: passed=" + qtest_results.passCount + " failed=" + qtest_results.failCount); }
   function cleanup() { console.warn("Completed " + qtest_results.functionName + " failures=" + qtest_results.failCount); }
   function init() { buttonClicks = 0; disabledClicks = 0; tabChoices = 0; sliderValue = 0.5; volumeSlider.keyboardFocus = false; volumeSlider.focus = false; tonalButton.emphasized = false; disabledButton.enabled = false; toggle.enabled = true; toggle.checked = false; tab.selected = false; Theme.reducedMotion = false; wait(40); }
   function test_button_roles_and_disabled_input() {
    compare(tonalButton.color.toString(), Theme.secondaryContainer.toString());
    tonalButton.emphasized = true; wait(200); compare(tonalButton.color.toString(), Theme.primary.toString());
    tonalButton.destructive = true; wait(200); compare(tonalButton.color.toString(), Theme.error.toString());
    tonalButton.emphasized = false; wait(200); compare(tonalButton.color.toString(), Theme.errorContainer.toString());
    disabledButton.enabled = true; disabledButton.forceActiveFocus(); disabledButton.enabled = false; keyClick(Qt.Key_Return);
    compare(disabledClicks, 0);
    mouseClick(tonalButton, tonalButton.width / 2, tonalButton.height / 2);
    compare(buttonClicks, 1);
   }
   function test_switch_mouse_and_keyboard() {
    compare(toggle.checked, false);
    mouseClick(toggle, toggle.width / 2, toggle.height / 2); compare(toggle.checked, true);
    wait(200); compare(toggle.color.toString(), Theme.primary.toString());
    toggle.forceActiveFocus(); toggle.enabled = false; keyClick(Qt.Key_Space);
    compare(toggle.checked, true);
   }
   function test_tab_visible_label_and_activation() {
    const label = findChild(tab, "controlTabLabel");
    verify(!!label); compare(label.text, "音声"); compare(tab.Accessible.name, "音声");
    verify(tab.width >= Theme.quickTabWidth); verify(tab.height >= Theme.quickTabHeight);
    tab.forceActiveFocus(); keyClick(Qt.Key_Return); compare(tabChoices, 1); compare(tab.selected, true);
    mouseClick(tab, tab.width / 2, tab.height / 2); compare(tabChoices, 2); compare(tab.selected, false); verify(!tab.activeFocus);
   }
   function test_slider_pointer_clears_focus_ring() {
    volumeSlider.forceActiveFocus(); keyClick(Qt.Key_Right);
    compare(volumeSlider.keyboardFocus, true); verify(findChild(volumeSlider, "sliderFocusIndicator").visible);
    mouseClick(volumeSlider, volumeSlider.width * 0.75, volumeSlider.height / 2);
    compare(sliderValue, (volumeSlider.width * 0.75 - volumeSlider.trackStart) / volumeSlider.trackWidth);
    verify(!volumeSlider.activeFocus); verify(!findChild(volumeSlider, "sliderFocusIndicator").visible);
   }
  }
 }
}'''

for screen in (0, 1):
    with tempfile.TemporaryDirectory(prefix="material-controls-tests-") as directory:
        tmp = Path(directory)
        (tmp / "material-shell").symlink_to(root, target_is_directory=True)
        (tmp / "shell.qml").write_text(fixture)
        env = dict(os.environ, FONTCONFIG_FILE=str(root / "fonts.conf"), PANEL_TEST_SCREEN=str(screen))
        result = subprocess.run(["quickshell", "-p", str(tmp), "--no-color"], env=env,
                                capture_output=True, text=True, timeout=20)
        output = result.stdout + result.stderr
        print(f"Screen {screen}:\n{output}")
        if "Controls tests: passed=" not in output or "failed=0" not in output:
            raise SystemExit(f"Control component tests failed on screen {screen}")
