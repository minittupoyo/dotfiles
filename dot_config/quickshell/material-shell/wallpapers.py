#!/usr/bin/env python3
"""Wallpaper library index; persist only a successfully scanned folder."""
import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile
import wallpaper_backend as backend

CONFIG = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'material-shell/wallpapers.json'
EXTENSIONS = {'.png', '.jpg', '.jpeg', '.webp', '.bmp'}


def scan(directory=None):
    try:
        current = str(backend.current_wallpaper())
    except (OSError, subprocess.SubprocessError):
        current = ''
    defaults = [str(Path.home() / 'Pictures/Wallpapers'), str(Path.home() / 'Wallpapers'), '/usr/share/backgrounds']
    try:
        roots = json.loads(CONFIG.read_text())['directories']
        if not isinstance(roots, list) or not all(isinstance(r, str) for r in roots):
            raise ValueError('Invalid directory configuration')
    except (OSError, ValueError, KeyError):
        roots = defaults
    if directory:
        folder = Path(directory).expanduser().resolve(strict=True)
        if not folder.is_dir():
            raise ValueError('フォルダーを指定してください')
        roots = [str(folder)]
    paths = set()
    warnings = []
    for root in roots:
        if not Path(root).is_dir():
            continue
        def failed(error):
            warnings.append(str(error))
        for base, dirs, files in os.walk(root, onerror=failed, followlinks=False):
            dirs[:] = sorted(d for d in dirs if not d.startswith('.'))
            for name in files:
                path = Path(base) / name
                if not name.startswith('.') and path.suffix.lower() in EXTENSIONS and path.is_file():
                    paths.add(path.resolve())
    if directory and warnings:
        raise ValueError('フォルダーを読み込めません: ' + warnings[0])
    if current and Path(current).is_file():
        paths.add(Path(current).resolve())
    if directory:
        CONFIG.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(mode='w', dir=CONFIG.parent, delete=False) as f:
            json.dump({'directories': roots}, f, ensure_ascii=False)
            temporary = f.name
        os.replace(temporary, CONFIG)
    return {'directories': roots, 'current': current, 'warnings': warnings,
            'images': [{'name': p.name, 'path': str(p), 'url': p.as_uri()} for p in sorted(paths, key=lambda p: (p.name.casefold(), str(p)))]}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--directory')
    args = parser.parse_args()
    try:
        print(json.dumps(scan(args.directory), ensure_ascii=False))
    except (OSError, ValueError) as error:
        parser.exit(1, f'{error}\n')
