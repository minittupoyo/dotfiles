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
  anchors {top:true;bottom:true;left:true;right:true}
  WlrLayershell.keyboardFocus:WlrKeyboardFocus.OnDemand
  Rectangle {id:target;width:100;height:32}
 ControlMedia {
  id:panel;service:service
  active:true;width:400;height:500
  TestCase {
   name:"ControlMedia";when:true
   function cleanupTestCase(){console.warn("Media tests: passed="+qtest_results.passCount+" failed="+qtest_results.failCount);}
   function cleanup(){console.warn("Completed "+qtest_results.functionName+" failures="+qtest_results.failCount);}
   function init(){fake.isPlaying=false;fake.position=30;service.players=[fake];panel.refresh();wait(100);}
   function test_controls(){const play=findChild(panel,"mediaPlay");mouseClick(play,play.width/2,play.height/2);compare(fake.isPlaying,true);const next=findChild(panel,"mediaNext");mouseClick(next,next.width/2,next.height/2);compare(fake.nextCount,1);compare(findChild(panel,"mediaPrevious").enabled,false);}
   function test_embedded(){verify(panel.visible);verify(panel.active);compare(panel.width,400);}
   function test_animation(){const progress=findChild(panel,"mediaProgress");fake.isPlaying=true;fake.position=90;panel.refresh();tryCompare(progress,"animationRunning",true);const initial=progress.phase;wait(80);verify(progress.phase!==initial);fake.isPlaying=false;tryCompare(progress,"animationRunning",false);const paused=progress.phase;wait(80);compare(progress.phase,paused);Theme.reducedMotion=true;fake.isPlaying=true;compare(progress.animationRunning,false);Theme.reducedMotion=false;}
   function test_progress(){const progress=findChild(panel,"mediaProgress");verify(progress.visible);compare(progress.wavy,true);compare(progress.fraction,30/180);verify(progress.interactive);verify(progress.activeFocusOnTab);fake.position=90;panel.refresh();compare(progress.fraction,0.5);mouseClick(progress,progress.width*0.75,progress.height/2);compare(fake.position,135);verify(!progress.activeFocus);verify(!findChild(progress,"progressFocusIndicator").visible);mousePress(progress,progress.width*0.25,progress.height/2);mouseMove(progress,progress.width*0.5,progress.height/2,100);mouseRelease(progress,progress.width*0.5,progress.height/2);compare(fake.position,90);progress.focus=false;fake.canSeek=false;verify(!progress.interactive);}
   function test_empty(){service.players=[];compare(panel.player,null);compare(findChild(panel,"mediaPlay").enabled,false);const empty=findChild(panel,"mediaEmptyState");verify(!!empty);verify(empty.visible);verify(!!findChild(panel,"mediaEmptyTitle"));verify(!!findChild(panel,"mediaEmptyDescription"));}
   function test_selection_removed(){service.select(fake.dbusName);compare(service.player,fake);service.players=[];compare(service.selectedName,"");compare(service.player,null);}
  }
 }
 }
}'''
for screen in (0, 1):
 with tempfile.TemporaryDirectory(prefix='material-media-tests-') as directory:
  tmp=Path(directory);(tmp/'material-shell').symlink_to(root,target_is_directory=True);(tmp/'shell.qml').write_text(fixture.replace('@@IMPORT@@','./material-shell'))
  result=subprocess.run(['quickshell','-p',str(tmp),'--no-color'],env=dict(os.environ,FONTCONFIG_FILE=str(root/'fonts.conf'),PANEL_TEST_SCREEN=str(screen)),capture_output=True,text=True,timeout=20)
  output=f'Screen {screen}:\n'+result.stdout+result.stderr
  print(output)
  assert 'Media tests: passed=' in output and 'failed=0' in output
