#!/usr/bin/env python3
"""Compile the real locker in explicit preview mode; never lock or authenticate."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import time
root=Path(__file__).resolve().parents[1]
with tempfile.TemporaryFile(mode='w+') as log:
 process=subprocess.Popen(['quickshell','-c','material-lock','--no-duplicate','--no-color'],env=dict(os.environ,MATERIAL_LOCK_PREVIEW='1',FONTCONFIG_FILE=str(root/'fonts.conf')),stdout=log,stderr=subprocess.STDOUT)
 try:
  for _ in range(50):
   if process.poll() is not None:break
   result=subprocess.run(['quickshell','ipc','-c','material-lock','call','lock','status'],capture_output=True,text=True)
   try:state=json.loads(result.stdout)
   except ValueError:time.sleep(.1);continue
   assert state=={'secure':False,'locked':False,'preview':True},state
   print('Locker preview compiled; session remained unlocked; PAM not started: PASS')
   break
  else:raise RuntimeError('Preview did not become ready')
  if process.poll() is not None:raise RuntimeError('Preview failed to load')
 finally:
  process.terminate();process.wait(timeout=5)
  log.seek(0);print(log.read())
