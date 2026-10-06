#!/usr/bin/env python3
"""awww rendering and persistent global wallpaper, independent of Noctalia."""
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import time

STATE = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'material-shell'


def binary(name):
    return shutil.which(name) or str(Path.home() / '.local/bin' / name)


def run(args):
    return subprocess.check_output([binary('awww'), *args], text=True, stderr=subprocess.PIPE, timeout=60).strip()


def query():
    outputs = []
    for line in run(['query']).splitlines():
        parts = line.split(': ', 2)
        if len(parts) >= 2:
            name, description = parts[-2:]
            match = re.search(r'image: (.*)$', description)
            outputs.append((name, match.group(1) if match else ''))
    return outputs


def saved_path():
    for filename in ['wallpaper.json', 'palette.json']:
        try:
            data = json.loads((STATE / filename).read_text())
            path = data['path'] if filename == 'wallpaper.json' else data['wallpaper']['path']
            if Path(path).is_file(): return str(Path(path).resolve())
        except (OSError, ValueError, KeyError, TypeError):
            pass
    raise FileNotFoundError('保存された壁紙がありません。壁紙セレクターから選択してください')


def save(path):
    STATE.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode='w', dir=STATE, prefix='.wallpaper-', delete=False) as file:
        json.dump({'version': 1, 'path': str(path)}, file, ensure_ascii=False)
        file.flush(); os.fsync(file.fileno())
        temporary = file.name
    os.replace(temporary, STATE / 'wallpaper.json')


def ensure_daemon():
    STATE.mkdir(parents=True, exist_ok=True)
    with (STATE / 'awww.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            return query()
        except (OSError, subprocess.SubprocessError):
            pass
        with (STATE / 'awww.log').open('a') as log:
            daemon = subprocess.Popen([binary('awww-daemon'), '--no-cache'],
                                      stdin=subprocess.DEVNULL, stdout=log, stderr=log, start_new_session=True)
        for _ in range(40):
            if daemon.poll() is not None:
                raise RuntimeError('awww-daemonを起動できません: ' + str(STATE / 'awww.log'))
            try:
                return query()
            except (OSError, subprocess.SubprocessError):
                time.sleep(.1)
        raise RuntimeError('awww-daemonの起動がタイムアウトしました')


def render(path, outputs=None):
    args = ['img', str(path), '--resize', 'crop', '--transition-type', 'random']
    if outputs: args += ['--outputs', ','.join(outputs)]
    run(args)


def set_wallpaper(path):
    ensure_daemon()
    render(path)
    save(path)


def current_wallpaper():
    try:
        images = query()
        for _, path in images:
            if path and Path(path).is_file(): return Path(path).resolve()
    except (OSError, subprocess.SubprocessError):
        pass
    return Path(saved_path())


def sync():
    outputs = ensure_daemon()
    missing = [name for name, path in outputs if not path]
    if missing:
        render(saved_path(), missing)


def restore():
    ensure_daemon()
    path = saved_path()
    render(path)
    save(path)


if __name__ == '__main__':
    restore()
