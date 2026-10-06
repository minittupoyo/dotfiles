#!/usr/bin/env python3
import json
from pathlib import Path
import os
import subprocess
import time
import sys

def main():
    env=dict(os.environ);env.pop('MATERIAL_LOCK_PREVIEW',None)
    env['FONTCONFIG_FILE']=str(Path.home()/'.config/quickshell/material-shell/fonts.conf')
    subprocess.run(['quickshell','-c','material-lock','--no-duplicate','--daemonize'],env=env,check=True)
    for _ in range(100):
        try:
            result=subprocess.check_output(['quickshell','ipc','-c','material-lock','call','lock','status'],text=True,stderr=subprocess.DEVNULL,timeout=1)
            state=json.loads(result)
            if state.get('secure') and not state.get('preview'): return
        except (ValueError,OSError,subprocess.SubprocessError): pass
        time.sleep(.1)
    raise RuntimeError('全画面のロック完了を確認できません。サスペンドは実行しません。')

if __name__=='__main__':
    try: main()
    except (OSError,RuntimeError,subprocess.SubprocessError) as e: print(e,file=sys.stderr);sys.exit(1)
