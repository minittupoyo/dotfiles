#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path
import tempfile

CONFIG = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'material-shell/settings.json'
DEFAULTS = {'showCpu': True, 'showMemory': True, 'showNetwork': True, 'showWindowTitle': True,
            'showTray': True, 'clock24': True, 'themeMode': 'dark', 'workspaces': 5, 'dnd': False, 'osd': True,
            'autoLockMinutes': 0, 'screenOffMinutes': 0}


def validate(data):
    if not isinstance(data, dict) or set(data) - set(DEFAULTS): raise ValueError('不明な設定項目です')
    result = dict(DEFAULTS)
    for key, value in data.items():
        if type(value) is not type(DEFAULTS[key]): raise ValueError('設定の形式が不正です: ' + key)
        if key == 'themeMode' and value not in ('light', 'dark'): raise ValueError('テーマはlightまたはdarkを指定してください')
        if key == 'workspaces' and not 1 <= value <= 10: raise ValueError('ワークスペース数は1〜10です')
        if key in ('autoLockMinutes', 'screenOffMinutes') and not 0 <= value <= 240: raise ValueError('時間は0〜240分です')
        result[key] = value
    if result['autoLockMinutes'] and result['screenOffMinutes'] and result['screenOffMinutes'] < result['autoLockMinutes']:
        raise ValueError('消灯時間は自動ロック時間以上にしてください')
    return result


def read():
    try: return validate(json.loads(CONFIG.read_text()))
    except FileNotFoundError: return dict(DEFAULTS)


def save(data):
    data = validate(data)
    CONFIG.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode='w', dir=CONFIG.parent, delete=False) as file:
        json.dump(data, file, indent=2);file.flush();os.fsync(file.fileno());name=file.name
    os.replace(name, CONFIG)
    try:
        import hyprland_theme
        hyprland_theme.apply(mode=data.get('themeMode'))
    except Exception:
        pass
    try:
        import palette
        palette.apply_matugen(mode=data.get('themeMode'))
    except Exception:
        pass
    return data


if __name__ == '__main__':
    parser=argparse.ArgumentParser();parser.add_argument('operation',choices=['get','set']);parser.add_argument('json',nargs='?')
    args=parser.parse_args()
    try: print(json.dumps(save(json.loads(args.json)) if args.operation=='set' else read()))
    except (OSError,ValueError,TypeError) as error: parser.exit(1,str(error)+'\n')
