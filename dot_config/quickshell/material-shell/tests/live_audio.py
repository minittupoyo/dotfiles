#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import tempfile
root=Path(__file__).resolve().parents[1]
fixture='''import Quickshell
import QtQuick
import QtTest
import "@@IMPORT@@"
ShellRoot {
 AudioPanel {
  id:panel
  property bool opened:true
  visible:opened
  screen:Quickshell.screens[Number(Quickshell.env("PANEL_TEST_SCREEN")||"0")]
  onDismissed:opened=false
  VolumeSlider {id:slider;width:300;value:0.5;onAdjusted:v=>value=v}
  TestCase {
   name:"AudioPanel";when:true
   function cleanupTestCase(){console.warn("Audio tests: passed="+qtest_results.passCount+" failed="+qtest_results.failCount);}
   function init(){panel.opened=true;wait(50);}
   function test_escape(){keyClick(Qt.Key_Escape);tryCompare(panel,"visible",false);}
   function test_outside(){mouseClick(panel.contentItem,10,10);tryCompare(panel,"visible",false);}
   function test_slider(){slider.forceActiveFocus();keyClick(Qt.Key_Right);compare(Math.round(slider.value*100),55);keyClick(Qt.Key_End);compare(slider.value,1);keyClick(Qt.Key_Right);compare(slider.value,1);keyClick(Qt.Key_Home);compare(slider.value,0);keyClick(Qt.Key_Left);compare(slider.value,0);}
   function test_devices(){tryVerify(()=>panel.devices.length>0);verify(panel.devices.every(n=>n.audio&&!n.isStream));}
  }
 }
}'''
with tempfile.TemporaryDirectory(prefix='material-audio-tests-') as directory:
 tmp=Path(directory);(tmp/'shell.qml').write_text(fixture.replace('@@IMPORT@@',root.as_uri()))
 result=subprocess.run(['quickshell','-p',str(tmp),'--no-color'],env=dict(os.environ,FONTCONFIG_FILE=str(root/'fonts.conf')),capture_output=True,text=True,timeout=20)
 output=result.stdout+result.stderr
 print(output)
 assert 'Audio tests: passed=5 failed=0' in output
