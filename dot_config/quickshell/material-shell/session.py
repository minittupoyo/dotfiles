#!/usr/bin/env python3
"""Explicit, whitelisted session commands. Only UI confirmation invokes this."""
import argparse
from pathlib import Path
import subprocess
import sys
import time

ROOT=Path(__file__).resolve().parent

def lock():
    subprocess.run([str(ROOT/'lock.sh')],check=True)


def execute(action):
    if action=='lock': lock()
    elif action=='suspend':
        lock()
        subprocess.run(['systemctl','suspend'],check=True)
    elif action=='logout': subprocess.run(['hyprctl','dispatch','hl.dsp.exit()'],check=True)
    elif action in ('reboot','poweroff'): subprocess.run(['systemctl',action],check=True)
    else: raise ValueError('Unknown session action')


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('action',choices=['lock','suspend','logout','reboot','poweroff']);a=p.parse_args()
    try: execute(a.action)
    except (OSError,ValueError,subprocess.SubprocessError) as e: p.exit(1,str(e)+'\n')
