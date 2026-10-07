#!/usr/bin/env python3
import os
import json
from pathlib import Path
import subprocess
import tempfile
root=Path(__file__).resolve().parents[1]
fixture='''import Quickshell
import Quickshell.Io
import QtQuick
import QtTest
import "@@IMPORT@@"
ShellRoot {
 Connections {target:Settings;function onSaveRequested(data){worker.command=["@@HELPER@@","set",JSON.stringify(data)];worker.running=true;}}
 Process {id:worker;stdout:SplitParser{onRead:data=>Settings.values=JSON.parse(data)} onExited:(code,status)=>Settings.saving=false}
 SettingsPanel {
  id:panel
  opened:true
  visible:opened
  screen:Quickshell.screens[Number(Quickshell.env("PANEL_TEST_SCREEN")||"0")]
  onDismissed:opened=false
  TestCase {
   name:"SettingsPersistence";when:true
   function cleanupTestCase(){console.warn("Settings tests: passed="+qtest_results.passCount+" failed="+qtest_results.failCount);}
   function init(){panel.opened=true;panel.draft=Object.assign({},Settings.values);wait(30);}
   function test_draft_is_separate(){const toggle=findChild(panel.contentItem,"setting-showCpu");mouseClick(toggle,toggle.width/2,toggle.height/2);compare(panel.draft.showCpu,false);compare(Settings.values.showCpu,true);}
   function test_escape(){keyClick(Qt.Key_Escape);tryCompare(panel,"visible",false);}
   function test_outside(){mouseClick(panel.contentItem,10,10);tryCompare(panel,"visible",false);}
   function test_save_persists(){const toggle=findChild(panel.contentItem,"setting-showCpu");mouseClick(toggle,toggle.width/2,toggle.height/2);const save=findChild(panel.contentItem,"settingsSave");mouseClick(save,save.width/2,save.height/2);tryCompare(Settings,"saving",false);tryVerify(()=>Settings.values.showCpu===false);verify(panel.message.includes("保存しました"));}
  }
 }
}'''
with tempfile.TemporaryDirectory(prefix='material-settings-tests-') as directory:
 tmp=Path(directory);(tmp/'material-shell').symlink_to(root, target_is_directory=True);(tmp/'shell.qml').write_text(fixture.replace('@@IMPORT@@','./material-shell').replace('@@HELPER@@',str(Path.home()/'.local/bin/material-settings')))
 result=subprocess.run(['quickshell','-p',str(tmp),'--no-color'],env=dict(os.environ,XDG_CONFIG_HOME=str(tmp),FONTCONFIG_FILE=str(root/'fonts.conf')),capture_output=True,text=True,timeout=20)
 print(result.stdout+result.stderr)
 assert 'passed=5 failed=0' in result.stdout+result.stderr
 assert json.loads((tmp/'material-shell/settings.json').read_text())['showCpu'] is False
