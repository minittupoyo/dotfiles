#!/usr/bin/env python3
"""Generate validated MD3 tokens; wallpaper rendering remains a separate backend."""
import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time
import wallpaper_backend as backend

STATE = Path(os.environ.get('XDG_STATE_HOME', str(Path.home() / '.local/state'))) / 'material-shell'
ROLES = ('surface', 'surface_container', 'surface_container_high', 'surface_container_highest',
         'on_surface', 'on_surface_variant', 'outline', 'outline_variant', 'primary', 'on_primary', 'primary_container', 'on_primary_container',
         'secondary_container', 'on_secondary_container', 'error', 'on_error', 'error_container', 'on_error_container',
         'inverse_surface', 'inverse_on_surface')


def run(command):
    return subprocess.run(command, check=True, capture_output=True, text=True, timeout=60).stdout.strip()


def current_wallpaper():
    return backend.current_wallpaper()

def signature(path):
    st = path.stat()
    return {'path': str(path), 'mtime_ns': st.st_mtime_ns, 'size': st.st_size}


def generate(path):
    binary = shutil.which('matugen') or str(Path.home() / '.local/bin/matugen')
    raw = json.loads(run([binary, 'image', str(path), '--dry-run', '--source-color-index', '0',
                          '--mode', 'dark', '--type', 'scheme-tonal-spot', '--contrast', '0',
                          '--json', 'hex', '--old-json-output']))
    schemes = {mode: {role: raw['colors'][role][mode] for role in ROLES}
               for mode in ('light', 'dark')}
    if not all(isinstance(value, str) and re.fullmatch(r'#[0-9a-fA-F]{6}', value)
               for colors in schemes.values() for value in colors.values()):
        raise ValueError('Matugen returned invalid colors')
    return {'version': 2, 'wallpaper': signature(path), 'scheme': 'scheme-tonal-spot',
            'contrast': 0, 'schemes': schemes}


def update(path=None, set_wallpaper=False):
    STATE.mkdir(parents=True, exist_ok=True)
    with (STATE / 'palette.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        path = Path(path).expanduser().resolve(strict=True) if path else current_wallpaper()
        if not path.is_file():
            raise ValueError('Wallpaper must be a file')
        if not set_wallpaper:
            try:
                saved = json.loads((STATE / 'palette.json').read_text())
                if (saved.get('version') == 2 and saved['wallpaper'] == signature(path)
                        and all(re.fullmatch(r'#[0-9a-fA-F]{6}', saved['schemes'][mode][r])
                                for mode in ('light', 'dark') for r in ROLES)):
                    backend.save(path)
                    return
            except (OSError, ValueError, KeyError, TypeError):
                pass
        palette = generate(path)
        if set_wallpaper:
            backend.set_wallpaper(path)
        name = None
        try:
            with tempfile.NamedTemporaryFile(mode='w', dir=STATE, prefix='.palette-', delete=False) as file:
                name = file.name
                json.dump(palette, file, indent=2)
                file.write('\n')
                file.flush()
                os.fsync(file.fileno())
            os.replace(name, STATE / 'palette.json')
        finally:
            if name and os.path.exists(name):
                os.unlink(name)
        backend.save(path)
        try:
            import hyprland_theme
            hyprland_theme.apply(palette=palette)
        except Exception:
            pass
        print(f'Palette updated: {path}', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('image', nargs='?', help='Set wallpaper and palette together')
    parser.add_argument('--watch', action='store_true', help='Follow awww wallpaper changes and restore missing outputs')
    args = parser.parse_args()
    if args.watch and args.image:
        parser.error('--watch cannot be combined with image')
    previous_error = None
    while True:
        try:
            if args.watch:
                backend.sync()
            update(args.image, set_wallpaper=bool(args.image))
            previous_error = None
        except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError, RuntimeError) as error:
            message = str(error)
            if message != previous_error:
                print(f'Palette unchanged: {message}', file=sys.stderr, flush=True)
            previous_error = message
            if not args.watch:
                return 1
        if not args.watch:
            return 0
        time.sleep(5)


if __name__ == '__main__':
    sys.exit(main())
