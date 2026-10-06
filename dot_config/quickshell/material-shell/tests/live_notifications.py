#!/usr/bin/env python3
"""Run under dbus-run-session to test only synthetic notifications on a private bus."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
root=Path(__file__).resolve().parents[1]
assert os.environ.get('MATERIAL_NOTIFICATION_TEST_PRIVATE')=='1','Run using dbus-run-session with MATERIAL_NOTIFICATION_TEST_PRIVATE=1'
fixture='''import Quickshell
import Quickshell.Io
import QtQuick
import "@@IMPORT@@"
ShellRoot {
 NotificationService { id:service; screen:Quickshell.screens[0] }
 IpcHandler {
  target:"test"
  function status():string{return JSON.stringify({history:service.history,active:service.notifications.length,toasts:service.toasts.length});}
  function dnd():void{Settings.values=Object.assign({},Settings.values,{dnd:true});}
  function action():void{const n=service.notifications[0];n.actions[0].invoke();}
  function clear():void{service.clearHistory();}
 }
}'''
with tempfile.TemporaryDirectory(prefix='material-notification-tests-') as directory:
 tmp=Path(directory);(tmp/'shell.qml').write_text(fixture.replace('@@IMPORT@@',root.as_uri()))
 (tmp/'material-shell').mkdir()
 env=dict(os.environ,XDG_STATE_HOME=str(tmp),FONTCONFIG_FILE=str(root/'fonts.conf'))
 with (tmp/'log').open('w+') as log:
  process=subprocess.Popen(['quickshell','-p',str(tmp),'--no-color'],env=env,stdout=log,stderr=subprocess.STDOUT)
  def ipc(method):return subprocess.check_output(['quickshell','ipc','-p',str(tmp),'call','test',method],text=True)
  def status():return json.loads(ipc('status'))
  def wait(predicate):
   for _ in range(60):
    try:
     if predicate():return
    except (ValueError,subprocess.SubprocessError):pass
    time.sleep(.05)
   raise AssertionError('Notification condition timed out')
  def notify(summary,replaces=0,timeout=10000,actions=()):
   args=['busctl','--user','call','org.freedesktop.Notifications','/org/freedesktop/Notifications','org.freedesktop.Notifications','Notify','susssasa{sv}i','Material Shell Test',str(replaces),'',summary,'テスト本文',str(len(actions)),*actions,'0',str(timeout)]
   return int(subprocess.check_output(args,text=True).split()[1])
  try:
   wait(lambda:status()['active']==0)
   identifier=notify('通知テスト')
   wait(lambda:status()['active']==1 and status()['toasts']==1)
   assert notify('置換テスト',identifier)==identifier
   wait(lambda:status()['history'][0]['summary']=='置換テスト')
   assert len(status()['history'])==1
   # Close the synthetic notification through its standard D-Bus API.
   subprocess.run(['busctl','--user','call','org.freedesktop.Notifications','/org/freedesktop/Notifications','org.freedesktop.Notifications','CloseNotification','u',str(identifier)],check=True)
   wait(lambda:status()['active']==0)
   notify('期限切れテスト',timeout=150)
   wait(lambda:status()['active']==0 and len(status()['history'])==2)
   notify('アクションテスト',actions=('default','開く'))
   wait(lambda:status()['active']==1)
   ipc('action');wait(lambda:status()['active']==0)
   ipc('dnd');notify('DNDテスト')
   wait(lambda:status()['active']==1)
   assert status()['toasts']==0
   time.sleep(.35)
   saved=json.loads((tmp/'material-shell/notifications.json').read_text())
   assert len(saved)==4
   (tmp/'shell.qml').write_text(fixture.replace('@@IMPORT@@',root.as_uri())+'\n// reload history test\n')
   wait(lambda:len(status()['history'])==4 and status()['active']==1)
   time.sleep(.2)
   assert len(status()['history'])==4
   ipc('clear');wait(lambda:len(status()['history'])==0)
   print('Notifications: receive, replace, close, expire, actions, DND, clear: PASS')
  finally:
   process.terminate();process.wait(timeout=5);log.seek(0);print(log.read())
