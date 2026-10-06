#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess

STATE=Path(os.environ.get('XDG_STATE_HOME',str(Path.home()/'.local/state')))/'material-shell'
DB=STATE/'clipboard.db'

def binary(name): return shutil.which(name) or str(Path.home()/'.local/bin'/name)

def command(action): return [binary('cliphist'),'-db-path',str(DB),'-max-items','100',action]

def entries():
    if not DB.exists(): return []
    output=subprocess.check_output(command('list'),text=True,timeout=10)
    result=[]
    for line in output.splitlines():
        identifier,sep,preview=line.partition('\t')
        if sep and identifier.isdigit(): result.append({'id':identifier,'preview':preview})
    return result

def operate(action,identifier=None):
    STATE.mkdir(parents=True,exist_ok=True);os.chmod(STATE,0o700)
    if action=='list': print(json.dumps(entries(),ensure_ascii=False))
    elif action=='store':
        if os.environ.get('CLIPBOARD_STATE') in ('sensitive', 'nil', 'clear'): return
        subprocess.run(command('store'),check=True)
        if DB.exists(): DB.chmod(0o600)
    elif action in ('copy','delete'):
        if not identifier or not identifier.isdigit(): raise ValueError('Invalid clipboard identifier')
        # Decode/delete accepts the numeric ID; avoid passing preview text to a shell.
        payload=identifier.encode()
        if action=='delete': subprocess.run(command('delete'),input=payload,check=True)
        else:
            data=subprocess.check_output(command('decode'),input=payload,timeout=10)
            mime='image/png' if data.startswith(b'\x89PNG\r\n\x1a\n') else 'image/jpeg' if data.startswith(b'\xff\xd8') else 'image/gif' if data.startswith((b'GIF87a', b'GIF89a')) else 'image/webp' if data.startswith(b'RIFF') and data[8:12] == b'WEBP' else 'image/bmp' if data.startswith(b'BM') else None
            args=[binary('wl-copy')]+(['--type',mime] if mime else [])
            subprocess.run(args,input=data,check=True,timeout=10)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['list','store','copy','delete']);p.add_argument('id',nargs='?');a=p.parse_args()
    try: operate(a.action,a.id)
    except (OSError,ValueError,subprocess.SubprocessError) as e:p.exit(1,str(e)+'\n')
