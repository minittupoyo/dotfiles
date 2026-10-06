#!/usr/bin/env python3
"""Test live panel interaction with an isolated library and fake wallpaper backend."""
import json
import sys
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(root))
import wallpaper_backend
with tempfile.TemporaryDirectory(prefix='material-wallpaper-tests-') as directory:
    tmp = Path(directory)
    source = str(wallpaper_backend.current_wallpaper())
    images = []
    for name in ['success.png', 'failure.png']:
        path = tmp / name; shutil.copyfile(source, path)
        images.append({'name': name, 'path': str(path), 'url': path.as_uri()})
    library = {'images': images, 'current': source, 'directories': [str(tmp)]}
    (tmp / 'wallpapers.py').write_text('print(' + repr(json.dumps(library)) + ')\n')
    (tmp / 'palette.py').write_text("import sys,time\ntime.sleep(.1)\nif sys.argv[1].endswith('failure.png'):\n print('Test generation failure',file=sys.stderr)\n sys.exit(1)\n")
    fixture = '''import Quickshell
import QtQuick
import QtTest
import "@@IMPORT@@"
ShellRoot {
    WallpaperSelector {
        id: panel
        property bool opened: true
        visible: opened
        screen: Quickshell.screens[Number(Quickshell.env("WALLPAPER_TEST_SCREEN") || "0")]
        onDismissed: opened = false
        TestCase {
            name: "LiveWallpaper"
            when: true
            function cleanupTestCase() { console.warn("Wallpaper tests: passed=" + qtest_results.passCount + " failed=" + qtest_results.failCount); }
            function init() {
                panel.opened = true;
                panel.setQuery("");
                tryVerify(() => panel.results.length === 2 && !JSON.parse(panel.status()).scanning);
                wait(30);
                findChild(panel.contentItem, "wallpaperSearch").focusInput();
            }
            function test_escape() {
                keyClick(Qt.Key_Escape);
                tryCompare(panel, "visible", false);
            }
            function test_outside_click() {
                mouseClick(panel.contentItem, 10, 10);
                tryCompare(panel, "visible", false);
            }
            function test_navigation_and_empty_search() {
                panel.setQuery("");
                keyClick(Qt.Key_Down);
                compare(panel.selectedIndex, 1);
                keyClick(Qt.Key_Up);
                compare(panel.selectedIndex, 0);
                panel.setQuery("存在しない壁紙");
                compare(panel.results.length, 0);
                keyClick(Qt.Key_Return);
                compare(panel.busy, false);
                compare(panel.visible, true);
            }
            function test_successful_apply() {
                panel.setQuery("success");
                tryVerify(() => JSON.parse(panel.status()).previewReady);
                keyClick(Qt.Key_Return);
                verify(panel.busy);
                wait(200);
                tryCompare(panel, "busy", false);
                compare(panel.failed, false);
                compare(panel.currentPath, panel.selected.path);
                verify(panel.message.includes("適用しました"));
            }
            function test_failed_apply_retains_current() {
                const current = panel.currentPath;
                panel.setQuery("failure");
                tryVerify(() => JSON.parse(panel.status()).previewReady);
                panel.applySelection();
                verify(panel.busy);
                wait(200);
                tryCompare(panel, "busy", false);
                compare(panel.failed, true);
                compare(panel.currentPath, current);
                verify(panel.message.includes("適用できません"));
            }
        }
    }
}'''
    (tmp / 'shell.qml').write_text(fixture.replace('@@IMPORT@@', root.as_uri()))
    result = subprocess.run(['quickshell', '-p', str(tmp), '--no-color'], env=dict(os.environ, FONTCONFIG_FILE=str(root / 'fonts.conf')),
                            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=25)
    print(result.stdout)
    if result.returncode != 0 or 'passed=6 failed=0' not in result.stdout:
        raise RuntimeError('Live wallpaper tests failed')
