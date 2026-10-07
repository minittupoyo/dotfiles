#!/usr/bin/env python3
"""Check that panel actions emit OSD messages instead of showing in-panel text."""
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
    id: testRoot
    property string lastMessage: ""
    property bool lastFailed: false
    property int messageCount: 0

    Osd { id: osd }
    QtObject { id: notifications; property var history: [{app:"Test", summary:"Hello", body:"World", timestamp:Date.now()}] }

    ControlPanel {
        id: panel
        opened: true
        screen: Quickshell.screens[0]
        notificationService: notifications
        onDismissed: opened = false
        onMessageRequested: (text, failed) => {
            testRoot.lastMessage = text;
            testRoot.lastFailed = failed;
            testRoot.messageCount++;
            osd.showMessage(text, failed, panel.screen);
        }
    }

    SessionMenu {
        id: session
        screen: panel.screen
        onDismissed: opened = false
        onMessageRequested: (text, failed) => {
            testRoot.lastMessage = text;
            testRoot.lastFailed = failed;
            testRoot.messageCount++;
            osd.showMessage(text, failed, session.screen);
        }
    }

    TestCase {
        name: "PanelOsdFeedback"
        when: true

        function cleanupTestCase() {
            console.warn("Panel OSD tests: passed=" + qtest_results.passCount + " failed=" + qtest_results.failCount);
        }
        function cleanup() {
            console.warn("Function: " + qtest_results.functionName + " failed=" + qtest_results.failCount);
        }

        function init() {
            testRoot.lastMessage = "";
            testRoot.lastFailed = false;
            testRoot.messageCount = 0;
            panel.opened = true;
            session.opened = false;
            wait(50);
        }

        function test_settings_reset_and_revert_emit_osd() {
            panel.selectTab("settings");
            wait(50);
            // Test reset
            panel.draft = Object.assign({}, Settings.values, { workspaces: 9 });
            const resetBtn = findChild(panel, "controlSettingsReset");
            verify(resetBtn !== null);
            resetBtn.clicked();
            tryVerify(() => testRoot.lastMessage.includes("初期値"));
            compare(testRoot.lastFailed, false);
            verify(osd.visible);
            compare(osd.messageMode, true);

            // Test revert
            const revertBtn = findChild(panel, "controlSettingsRevert");
            verify(revertBtn !== null);
            revertBtn.clicked();
            tryVerify(() => testRoot.lastMessage.includes("元に戻しました"));
            compare(testRoot.lastFailed, false);
        }

        function test_notifications_clear_emits_osd() {
            panel.selectTab("notifications");
            wait(50);
            const clearBtn = findChild(panel, "clearNotificationsButton");
            verify(clearBtn !== null);
            mouseClick(clearBtn, clearBtn.width / 2, clearBtn.height / 2);
            tryVerify(() => testRoot.lastMessage.includes("通知履歴を消去しました"));
            compare(testRoot.lastFailed, false);
            verify(osd.visible);
            compare(osd.label, "通知履歴を消去しました");
        }

        function test_clipboard_copy_emits_osd() {
            panel.selectTab("clipboard");
            wait(100);
            const clipPage = findChild(panel, "clipboardContent") || panel;
            clipPage.messageRequested("クリップボードにコピーしました", false);
            tryVerify(() => testRoot.lastMessage === "クリップボードにコピーしました");
            compare(testRoot.lastFailed, false);
            verify(osd.visible);
            compare(osd.label, "クリップボードにコピーしました");
        }

        function test_network_scan_emits_osd() {
            panel.selectTab("network");
            wait(50);
            panel.messageRequested("Wi-Fiネットワークを更新しました", false);
            tryVerify(() => testRoot.lastMessage === "Wi-Fiネットワークを更新しました");
            compare(testRoot.lastFailed, false);
            verify(osd.visible);
            compare(osd.label, "Wi-Fiネットワークを更新しました");
        }

        function test_session_error_emits_osd() {
            panel.opened = false;
            session.opened = true;
            wait(50);
            session.messageRequested("操作を実行できませんでした", true);
            tryVerify(() => testRoot.lastMessage === "操作を実行できませんでした");
            compare(testRoot.lastFailed, true);
            verify(osd.visible);
            compare(osd.messageMode, true);
            compare(osd.messageFailed, true);
        }
    }
}
'''

with tempfile.TemporaryDirectory(prefix="material-panel-osd-tests-") as directory:
    tmp = Path(directory)
    (tmp / "material-shell").symlink_to(root, target_is_directory=True)
    (tmp / "shell.qml").write_text(fixture)
    helpers = tmp / "bin"
    helpers.mkdir()
    state = {"wifi": False, "wifiAvailable": False, "wifiConnected": "", "wifiNetworks": [],
             "bluetooth": False, "bluetoothAvailable": False, "bluetoothDevices": []}
    for name, data in {"material-control": state, "material-clipboard": [],
                       "material-wallpapers": {"images": [], "directories": [], "current": ""}}.items():
        helper = helpers / name
        helper.write_text("#!/usr/bin/env python3\nimport json\nprint(" + repr(json.dumps(data)) + ")\n")
        helper.chmod(0o755)
    env = dict(os.environ, MATERIAL_SHELL_CLI_DIR=str(helpers),
               FONTCONFIG_FILE=str(root / "fonts.conf"),
               XDG_CONFIG_HOME=str(tmp / "config"), XDG_STATE_HOME=str(tmp / "state"))
    result = subprocess.run(["quickshell", "-p", str(tmp), "--no-color"],
                            env=env, capture_output=True, text=True, timeout=30)
    output = result.stdout + result.stderr
    print(output)
    if result.returncode or "Panel OSD tests: passed=" not in output or "failed=0" not in output:
        raise SystemExit("Panel OSD tests failed")
