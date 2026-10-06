#!/usr/bin/env python3
import argparse
import datetime
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def binary(name): return shutil.which(name) or str(Path.home()/'.local/bin'/name)

def capture(region=False):
    args=[binary('grim')]
    if region:
        geometry=subprocess.run([binary('slurp')],capture_output=True,text=True)
        if geometry.returncode: return None
        args+=['-g',geometry.stdout.strip()]
    directory=Path.home()/'Pictures/Screenshots';directory.mkdir(parents=True,exist_ok=True)
    target=directory/('screenshot_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S_%f')+'.png')
    descriptor, name = tempfile.mkstemp(dir=directory, suffix='.png')
    os.close(descriptor)
    try:
        subprocess.run(args+[name],check=True)
        os.replace(name,target)
    finally:
        Path(name).unlink(missing_ok=True)
    target.chmod(0o600)
    subprocess.run([binary('wl-copy'),'--type','image/png'],input=target.read_bytes(),check=True)
    return target

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('mode',choices=['all','region']);a=p.parse_args()
    try:
        path=capture(a.mode=='region')
        if path: print(path)
    except (OSError,subprocess.SubprocessError) as e:p.exit(1,str(e)+'\n')
