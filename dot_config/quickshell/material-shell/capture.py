#!/usr/bin/env python3
import argparse
import datetime
import fcntl
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import sys

selection_process = None
RUNTIME = Path(os.environ.get('XDG_RUNTIME_DIR', f'/tmp/material-shell-{os.getuid()}'))
PID_FILE = RUNTIME / 'material-screenshot.pid'
LOCK_FILE = RUNTIME / 'material-screenshot.lock'


def binary(name): return shutil.which(name) or str(Path.home()/'.local/bin'/name)

def terminate(signum, frame):
    global selection_process
    if selection_process and selection_process.poll() is None:
        try: os.killpg(selection_process.pid, signal.SIGTERM)
        except ProcessLookupError: pass
    notify_shell('cancelled')
    raise SystemExit(128 + signum)


def notify_shell(status, copied=False, filename=''):
    try:
        subprocess.run(
            [binary('quickshell'), 'ipc', '-c', 'material-shell', 'call', 'capture', 'result',
             status, 'true' if copied else 'false', filename],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3, check=False)
    except (OSError, subprocess.SubprocessError):
        pass


def cancel_active():
    try: pid = int(PID_FILE.read_text().strip())
    except (OSError, ValueError): return False
    try:
        args=Path(f'/proc/{pid}/cmdline').read_bytes()
        if b'capture.py' not in args: return False
        os.kill(pid,signal.SIGTERM)
        return True
    except (OSError, ProcessLookupError):
        return False


def capture(region=False, output=None, geometry=None):
    global selection_process
    args=[binary('grim')]
    if output: args+=['-o',output]
    if region and geometry is None:
        process=subprocess.Popen([binary('slurp')],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True,start_new_session=True)
        selection_process=process
        try:
            selection_stdout, selection_stderr=process.communicate(timeout=60)
        except subprocess.TimeoutExpired:
            os.killpg(process.pid,signal.SIGTERM)
            process.communicate()
            return None
        finally:
            selection_process=None
        if process.returncode != 0 or not selection_stdout.strip(): return None
        geometry=selection_stdout.strip()
    if region:
        if not geometry: return None
        args+=['-g',geometry]
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
    copied=True
    try:
        subprocess.run([binary('wl-copy'),'--type','image/png'],input=target.read_bytes(),check=True)
    except (OSError,subprocess.SubprocessError):
        copied=False
    return target,copied

if __name__=='__main__':
    signal.signal(signal.SIGTERM,terminate)
    signal.signal(signal.SIGINT,terminate)
    p=argparse.ArgumentParser(prog='material-screenshot');p.add_argument('mode',choices=['all','monitor','region','cancel']);p.add_argument('--output');p.add_argument('--geometry');a=p.parse_args()
    if a.mode=='cancel':
        if not cancel_active(): print(json.dumps({'status':'idle'}))
        sys.exit(0)
    if a.mode=='monitor' and not a.output: p.error('monitor mode requires --output')
    try:
        RUNTIME.mkdir(parents=True,exist_ok=True)
        with LOCK_FILE.open('w') as lock:
            try: fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
            except BlockingIOError: sys.exit(0)
            PID_FILE.write_text(str(os.getpid()))
            os.chmod(PID_FILE,0o600)
            notify_shell('started')
            try:
                result=capture(a.mode=='region',a.output,a.geometry)
                if result is None:
                    notify_shell('cancelled')
                    print(json.dumps({'status':'cancelled'}))
                else:
                    path,copied=result
                    notify_shell('saved',copied,path.name)
                    print(json.dumps({'status':'saved','path':str(path),'copied':copied},ensure_ascii=False))
            finally:
                try:
                    if PID_FILE.read_text().strip()==str(os.getpid()): PID_FILE.unlink()
                except OSError: pass
    except (OSError,subprocess.SubprocessError) as e:
        notify_shell('error')
        p.exit(1,str(e)+'\n')
