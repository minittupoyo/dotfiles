#!/usr/bin/env python3
"""Private-bus StatusNotifierItem + DBusMenu integration, no actual app actions."""
import os
import json
from pathlib import Path
import subprocess
import tempfile
import time
assert os.environ.get('MATERIAL_NOTIFICATION_TEST_PRIVATE')=='1'
root=Path(__file__).resolve().parents[1]
mock='''import gi
from gi.repository import Gio,GLib
from pathlib import Path
bus=Gio.bus_get_sync(Gio.BusType.SESSION,None)
xml="""<node><interface name="org.kde.StatusNotifierItem">
<property name="Category" type="s" access="read"/><property name="Id" type="s" access="read"/><property name="Title" type="s" access="read"/><property name="Status" type="s" access="read"/><property name="WindowId" type="i" access="read"/><property name="IconName" type="s" access="read"/><property name="ItemIsMenu" type="b" access="read"/><property name="Menu" type="o" access="read"/>
<method name="Activate"><arg type="i" direction="in"/><arg type="i" direction="in"/></method>
</interface><interface name="com.canonical.dbusmenu">
<method name="GetLayout"><arg type="i" direction="in"/><arg type="i" direction="in"/><arg type="as" direction="in"/><arg type="u" direction="out"/><arg type="(ia{sv}av)" direction="out"/></method>
<method name="GetGroupProperties"><arg type="ai" direction="in"/><arg type="as" direction="in"/><arg type="a(ia{sv})" direction="out"/></method>
<method name="Event"><arg type="i" direction="in"/><arg type="s" direction="in"/><arg type="v" direction="in"/><arg type="u" direction="in"/></method>
<method name="AboutToShow"><arg type="i" direction="in"/><arg type="b" direction="out"/></method>
<property name="Version" type="u" access="read"/><property name="Status" type="s" access="read"/><property name="TextDirection" type="s" access="read"/><property name="IconThemePath" type="as" access="read"/>
</interface></node>"""
info=Gio.DBusNodeInfo.new_for_xml(xml)
def prop(connection,sender,path,iface,name):
 values={'Category':('s','ApplicationStatus'),'Id':('s','material-test'),'Title':('s','Test Tray'),'Status':('s','Active' if iface=='org.kde.StatusNotifierItem' else 'normal'),'WindowId':('i',0),'IconName':('s','utilities-terminal'),'ItemIsMenu':('b',True),'Menu':('o','/Menu'),'Version':('u',3),'TextDirection':('s','ltr'),'IconThemePath':('as',[])}
 return GLib.Variant(*values[name])
def attrs(label,submenu=False):
 value={'label':GLib.Variant('s',label),'enabled':GLib.Variant('b',True),'visible':GLib.Variant('b',True)}
 if submenu:value['children-display']=GLib.Variant('s','submenu')
 return value
child=GLib.Variant('(ia{sv}av)',(3,attrs('Nested action'),[]))
first=GLib.Variant('(ia{sv}av)',(1,attrs('Test action'),[]))
sub=GLib.Variant('(ia{sv}av)',(2,attrs('Submenu',True),[child]))
def method(connection,sender,path,iface,name,args,invocation):
 values=args.unpack()
 if name=='GetLayout':
  layout=(2,attrs('Submenu',True),[child]) if values[0]==2 else (0,{},[first,sub])
  invocation.return_value(GLib.Variant('(u(ia{sv}av))',(1,layout)))
 elif name=='GetGroupProperties':invocation.return_value(GLib.Variant('(a(ia{sv}))',([] ,)))
 elif name=='AboutToShow':invocation.return_value(GLib.Variant('(b)',(False,)))
 elif name=='Event':
  if values[1]=='clicked':Path(__file__).with_name('event').write_text(str(values[0]))
  invocation.return_value(None)
 else:invocation.return_value(None)
bus.register_object('/StatusNotifierItem',info.interfaces[0],method,prop,None)
bus.register_object('/Menu',info.interfaces[1],method,prop,None)
bus.call_sync('org.kde.StatusNotifierWatcher','/StatusNotifierWatcher','org.kde.StatusNotifierWatcher','RegisterStatusNotifierItem',GLib.Variant('(s)',('/StatusNotifierItem',)),None,Gio.DBusCallFlags.NONE,3000,None)
GLib.MainLoop().run()
'''
fixture='''import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick
import "@@IMPORT@@"
ShellRoot {
 property bool opened:false
 TrayMenu {id:menu;visible:opened;screen:Quickshell.screens[0];onDismissed:opened=false}
 IpcHandler {
 target:"test"
 function status():string{return JSON.stringify({count:SystemTray.items.values.length,entries:menu.entries.map(e=>e.text),visible:opened,depth:menu.stack.length});}
 function open():void {menu.openEntry(SystemTray.items.values[0].menu,"Test Tray");opened=true;}
 function submenu():void {menu.choose(menu.entries[1]);}
 function invoke():void {menu.choose(menu.entries[0]);}
 }
}'''
with tempfile.TemporaryDirectory(prefix='material-tray-tests-') as directory:
 tmp=Path(directory);(tmp/'shell.qml').write_text(fixture.replace('@@IMPORT@@',root.as_uri()));(tmp/'mock.py').write_text(mock)
 with (tmp/'log').open('w+') as log:
  process=subprocess.Popen(['quickshell','-p',str(tmp),'--no-color'],stdout=log,stderr=subprocess.STDOUT)
  mock_process=None
  def ipc(method):return subprocess.check_output(['quickshell','ipc','-p',str(tmp),'call','test',method],text=True,stderr=subprocess.DEVNULL)
  def status():return json.loads(ipc('status'))
  def wait(predicate):
   for _ in range(60):
    try:
     if predicate():return
    except (ValueError,subprocess.SubprocessError):pass
    time.sleep(.05)
   raise AssertionError('Tray integration condition timed out')
  try:
   wait(lambda:status()['count']==0)
   mock_process=subprocess.Popen(['python3',str(tmp/'mock.py')],stdout=log,stderr=subprocess.STDOUT)
   wait(lambda:status()['count']==1)
   ipc('open');wait(lambda:len(status()['entries'])==2)
   ipc('submenu');wait(lambda:status()['entries']==['Nested action'])
   assert status()['depth']==1
   ipc('invoke');wait(lambda:(tmp/'event').exists())
   assert (tmp/'event').read_text()=='3'
   assert not status()['visible']
   print('Tray registration, custom menu, submenu, remote action: PASS')
  finally:
   if mock_process:mock_process.terminate();mock_process.wait(timeout=5)
   process.terminate();process.wait(timeout=5);log.seek(0);print(log.read())
