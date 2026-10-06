#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
state = {
    "wifi": True,
    "wifiAvailable": True,
    "wifiConnected": "Office Wi-Fi",
    "wifiNetworks": [
        {"ssid": "Office Wi-Fi", "security": "WPA2", "secured": True, "signal": 86,
         "connected": True, "hidden": False, "savedConnection": "office-profile"},
        {"ssid": "Guest Network", "security": "WPA2", "secured": True, "signal": 62,
         "connected": False, "hidden": False, "savedConnection": ""},
    ],
    "bluetooth": True,
    "bluetoothAvailable": True,
    "bluetoothDevices": [
        {"address": "AA:BB:CC:DD:EE:FF", "name": "Headphones", "paired": True,
         "connected": True, "available": True},
        {"address": "11:22:33:44:55:66", "name": "Keyboard", "paired": True,
         "connected": False, "available": True},
        {"address": "22:33:44:55:66:77", "name": "New speaker", "paired": False,
         "connected": False, "available": True},
    ],
}

fixture = '''import Quickshell
import Quickshell.Wayland
import QtQuick
import QtTest
import "./material-shell"
ShellRoot {
 PanelWindow {
  screen: Quickshell.screens[Number(Quickshell.env("PANEL_TEST_SCREEN") || "0")]
  anchors { top: true; bottom: true; left: true; right: true }
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  Rectangle { id: target; width: 100; height: 32 }
  ControlNetwork { id: panel; objectName: "networkPanel"; active: true; width: 440; height: 600 }
  TestCase {
   name: "ControlNetwork"; when: true
   function cleanupTestCase() { console.warn("Network tests: passed=" + qtest_results.passCount + " failed=" + qtest_results.failCount); }
   function cleanup() { console.warn("Completed " + qtest_results.functionName + " failures=" + qtest_results.failCount); }
   function init() { panel.selectedWifiSsid = ""; panel.revealPassword = false; panel.error = ""; panel.message = ""; panel.refresh(); tryCompare(findChild(panel, "wifiNetworks"), "count", 2); tryCompare(panel, "busy", false); }
   function test_network_lists_and_status() {
    verify(panel.implicitHeight < 500);
    compare(panel.state.wifiConnected, "Office Wi-Fi");
    compare(findChild(panel, "wifiNetworks").count, 2);
    compare(findChild(panel, "bluetoothDevices").count, 3);
    verify(findChild(panel, "wifiToggle").checked);
    verify(findChild(panel, "bluetoothToggle").checked);
    verify(findChild(panel, "bluetoothRemoveButton").visible);
   }
   function test_secured_network_opens_password_entry() {
    const row = findChild(findChild(panel, "wifiNetworks").itemAtIndex(1), "wifiConnectButton");
    verify(!!row); mouseClick(row, row.width / 2, row.height / 2);
    verify(findChild(panel, "wifiPasswordPrompt").visible);
    verify(findChild(panel, "wifiPasswordInput").visible);
    compare(panel.selectedWifiSsid, "Guest Network");
   }
   function test_refresh_and_scan_keep_actions_live() {
    verify(findChild(panel, "wifiScan").enabled);
    verify(findChild(panel, "bluetoothScan").enabled);
    panel.scanWifi(); tryCompare(panel, "message", "Wi-Fiネットワークを更新しました", 3000);
    verify(findChild(panel, "wifiConnectButton").enabled);
   }
   function test_z_network_lists_adapt_to_available_height() {
    const originalState = panel.state;
    panel.state = Object.assign({}, originalState, {
     wifiNetworks: Array.from({length: 8}, (_, index) => Object.assign({}, panel.state.wifiNetworks[index % 2], {ssid: "Network " + index, connected: index === 0})),
     bluetoothDevices: Array.from({length: 8}, (_, index) => Object.assign({}, panel.state.bluetoothDevices[index % 3], {name: "Device " + index}))
    });
    const wifi = findChild(panel, "wifiNetworks");
    const bluetooth = findChild(panel, "bluetoothDevices");
    tryCompare(wifi, "count", 8);
    tryCompare(bluetooth, "count", 8);
    tryVerify(() => wifi.height > Theme.listRowHeight * 2 + Theme.space4);
    tryVerify(() => bluetooth.height > Theme.listRowHeight * 2 + Theme.space4);
    verify(wifi.height <= wifi.contentHeight);
    verify(bluetooth.height <= bluetooth.contentHeight);
    panel.state = originalState;
    wait(50);
   }
  }
 }
}'''

for screen in (0, 1):
    with tempfile.TemporaryDirectory(prefix="material-network-tests-") as directory:
        tmp = Path(directory)
        module_dir = tmp / "material-shell"
        module_dir.symlink_to(root, target_is_directory=True)
        (tmp / "shell.qml").write_text(fixture)
        binary_dir = tmp / "bin"
        binary_dir.mkdir()
        helper = binary_dir / "material-control"
        helper.write_text("#!/usr/bin/env python3\nimport json\nprint(" + repr(json.dumps(state, ensure_ascii=False)) + ")\n")
        helper.chmod(0o755)
        env = dict(os.environ, FONTCONFIG_FILE=str(root / "fonts.conf"),
                   MATERIAL_SHELL_CLI_DIR=str(binary_dir), PANEL_TEST_SCREEN=str(screen))
        result = subprocess.run(["quickshell", "-p", str(tmp), "--no-color"], env=env,
                                capture_output=True, text=True, timeout=25)
        output = f"Screen {screen}:\n" + result.stdout + result.stderr
        print(output)
        if "Network tests: passed=" not in output or "failed=0" not in output:
            raise SystemExit(f"Network control tests failed on screen {screen}")
