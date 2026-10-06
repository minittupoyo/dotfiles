#!/usr/bin/env python3
"""Own clipboard/idle child processes and reconfigure idle when settings change."""
import ctypes
import fcntl
import os
from pathlib import Path
import shlex
import signal
import shutil
import subprocess
import time
import settings

RUNTIME=Path(os.environ['XDG_RUNTIME_DIR'])

def binary(name): return shutil.which(name) or str(Path.home()/'.local/bin'/name)

def idle_command(values):
    lock=shlex.quote(binary('material-lock'))
    args=[binary('swayidle'),'-w','before-sleep',lock,'lock',lock]
    if values['autoLockMinutes']: args+=['timeout',str(values['autoLockMinutes']*60),lock]
    if values['screenOffMinutes']: args+=['timeout',str(values['screenOffMinutes']*60),'hyprctl dispatch \'hl.dsp.dpms({action = "disable"})\'','resume','hyprctl dispatch \'hl.dsp.dpms({action = "enable"})\'']
    return args

def launch(args):
    parent_pid=os.getpid()
    def child_setup():
        # Keep the supervised watchers inside this service's process group.
        # Linux propagates termination to each watcher instead of orphaning it.
        libc=ctypes.CDLL(None)
        if libc.prctl(1,signal.SIGTERM,0,0,0)!=0:os._exit(1)
        if os.getppid()!=parent_pid:os._exit(1)
    return subprocess.Popen(args,start_new_session=True,preexec_fn=child_setup)

def stop(process):
    if process and process.poll() is None:
        os.killpg(process.pid,signal.SIGTERM)
        try:process.wait(timeout=2)
        except subprocess.TimeoutExpired:os.killpg(process.pid,signal.SIGKILL)


def main():
    display=os.environ.get('WAYLAND_DISPLAY','wayland-0').replace('/','_')
    lock=(RUNTIME/('material-shell-services-'+display+'.lock')).open('a')
    try:fcntl.flock(lock,fcntl.LOCK_EX|fcntl.LOCK_NB)
    except BlockingIOError:return
    children={};previous=None;last_good=dict(settings.DEFAULTS)
    def exit_requested(signum,frame):raise SystemExit(0)
    signal.signal(signal.SIGTERM,exit_requested);signal.signal(signal.SIGINT,exit_requested)
    try:
        while True:
            try:last_good=settings.read()
            except (OSError,ValueError):pass
            values=last_good
            for kind in ['text','image']:
                child=children.get(kind)
                if child is None or child.poll() is not None:
                    children[kind]=launch([binary('wl-paste'),'--type',kind,'--watch',binary('material-clipboard'),'store'])
            idle_values={key:values[key] for key in ['autoLockMinutes','screenOffMinutes']}
            if previous is None or idle_values!=previous or children['idle'].poll() is not None:
                stop(children.get('idle'))
                children['idle']=launch(idle_command(values))
                previous=idle_values
            time.sleep(1)
    finally:
        for child in children.values():stop(child)

if __name__=='__main__':main()
