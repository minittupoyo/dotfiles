#!/usr/bin/env python3
import os
from pathlib import Path
import subprocess
import tempfile
root=Path(__file__).resolve().parents[1]
fixture='''import Quickshell
import Quickshell.Wayland
import QtQuick
import QtTest
import "@@IMPORT@@"
ShellRoot {
 QtObject {
  id:fake
  property string dbusName:"mock.player"
  property string identity:"Test Player"
  property string trackTitle:"日本語の曲名"
  property string trackArtist:"Artist"
  property string trackAlbum:"Album"
  property string trackArtUrl:""
  property bool isPlaying:false
  property bool canTogglePlaying:true
  property bool canGoPrevious:false
  property bool canGoNext:true
  property bool canSeek:true
  property bool lengthSupported:true
  property bool positionSupported:true
  property real length:180
  property real position:30
  property int nextCount:0
  signal postTrackChanged()
  function togglePlaying(){isPlaying=!isPlaying;}
  function next(){nextCount++;}
  function previous(){throw new Error("unsupported");}
 }
 MediaService {id:service;players:[fake]}
 PanelWindow {
  id:host
  screen:Quickshell.screens[Number(Quickshell.env("PANEL_TEST_SCREEN")||"0")]
  anchors {top:true;left:true;right:true}
  implicitHeight:48
  WlrLayershell.keyboardFocus:WlrKeyboardFocus.OnDemand
  Rectangle {id:target;width:100;height:32}
 NowPlaying {
  id:panel;service:service
  opened:false
  anchor.item:target
  onDismissed:opened=false
  TestCase {
   name:"NowPlaying";when:true
   function cleanupTestCase(){console.warn("Media tests: passed="+qtest_results.passCount+" failed="+qtest_results.failCount);}
   function cleanup(){console.warn("Completed "+qtest_results.functionName+" failures="+qtest_results.failCount);}
   function init(){fake.isPlaying=false;fake.position=30;service.players=[fake];mouseClick(target,10,10);panel.opened=true;wait(100);}
   function test_controls(){const play=findChild(panel.contentItem,"mediaPlay");mouseClick(play,play.width/2,play.height/2);compare(fake.isPlaying,true);const next=findChild(panel.contentItem,"mediaNext");mouseClick(next,next.width/2,next.height/2);compare(fake.nextCount,1);compare(findChild(panel.contentItem,"mediaPrevious").enabled,false);}
   function test_escape(){keyClick(Qt.Key_Escape);tryCompare(panel,"visible",false);}
   function test_anchor(){compare(panel.anchor.item,target);verify(panel.height<=640);compare(panel.grabFocus,true);}
   function test_animation(){const progress=findChild(panel.contentItem,"mediaProgress");fake.isPlaying=true;fake.position=90;panel.refresh();tryCompare(progress,"animationRunning",true);const initial=progress.phase;wait(80);verify(progress.phase!==initial);fake.isPlaying=false;tryCompare(progress,"animationRunning",false);const paused=progress.phase;wait(80);compare(progress.phase,paused);Theme.reducedMotion=true;fake.isPlaying=true;compare(progress.animationRunning,false);Theme.reducedMotion=false;}
   function test_progress(){const progress=findChild(panel.contentItem,"mediaProgress");verify(progress.visible);compare(progress.wavy,true);compare(progress.fraction,30/180);fake.position=90;panel.refresh();compare(progress.fraction,0.5);verify(!progress.activeFocusOnTab);}
   function test_empty(){service.players=[];compare(panel.player,null);compare(findChild(panel.contentItem,"mediaPlay").enabled,false);}
   function test_selection_removed(){service.select(fake.dbusName);compare(service.player,fake);service.players=[];compare(service.selectedName,"");compare(service.player,null);}
  }
 }
 }
}'''
with tempfile.TemporaryDirectory(prefix='material-media-tests-') as directory:
 tmp=Path(directory);(tmp/'shell.qml').write_text(fixture.replace('@@IMPORT@@',root.as_uri()))
 result=subprocess.run(['quickshell','-p',str(tmp),'--no-color'],env=dict(os.environ,FONTCONFIG_FILE=str(root/'fonts.conf')),capture_output=True,text=True,timeout=20)
 output=result.stdout+result.stderr
 print(output)
 assert 'Media tests: passed=8 failed=0' in output
