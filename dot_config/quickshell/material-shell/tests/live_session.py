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
 SessionMenu {
  id: panel
  property bool opened:true
  visible:opened
  screen:Quickshell.screens[Number(Quickshell.env("PANEL_TEST_SCREEN")||"0")]
  onDismissed:opened=false
  TestCase {
   name:"SessionConfirmation";when:true
   function cleanupTestCase(){console.warn("Session tests: passed="+qtest_results.passCount+" failed="+qtest_results.failCount);}
   function init(){panel.opened=true;panel.pendingAction="";wait(30);}
   function test_confirmation_does_not_execute(){panel.choose("poweroff");compare(panel.pendingAction,"poweroff");compare(panel.executing,false);panel.pendingAction="";compare(panel.executing,false);}
   function test_cancel_escape(){panel.choose("reboot");keyClick(Qt.Key_Escape);tryCompare(panel,"visible",false);compare(panel.executing,false);}
   function test_outside(){mouseClick(panel.contentItem,10,10);tryCompare(panel,"visible",false);}
   function test_confirm_invokes_fake_backend(){panel.choose("logout");panel.execute();tryCompare(panel,"visible",false);}
   function test_failed_action_shows_error(){panel.choose("reboot");panel.execute();tryVerify(()=>panel.error.includes("Simulated failure"));tryCompare(panel,"executing",false);compare(panel.visible,true);}
  }
 }
}'''
with tempfile.TemporaryDirectory(prefix='material-session-tests-') as directory:
 tmp=Path(directory)
 (tmp/'material-shell').symlink_to(root,target_is_directory=True)
 (tmp/'shell.qml').write_text(fixture.replace('@@IMPORT@@','./material-shell'))
 helper=tmp/'material-session'
 helper.write_text("#!/usr/bin/env python3\nfrom pathlib import Path\nimport sys\nif sys.argv[1]=='reboot':\n print('Simulated failure',file=sys.stderr)\n sys.exit(1)\nPath(__file__).with_name('executed').write_text(sys.argv[1])\n")
 helper.chmod(0o755)
 result=subprocess.run(['quickshell','-p',str(tmp),'--no-color'],env=dict(os.environ,FONTCONFIG_FILE=str(root/'fonts.conf'),MATERIAL_SHELL_CLI_DIR=str(tmp)),capture_output=True,text=True,timeout=20)
 print(result.stdout+result.stderr)
 assert 'passed=6 failed=0' in result.stdout+result.stderr
 assert (tmp/'executed').read_text()=='logout'
