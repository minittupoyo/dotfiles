#!/usr/bin/env python3
"""Whitelisted display brightness hotkey actions."""
import argparse
import shutil
import subprocess


def binary(name):
    return shutil.which(name) or '/usr/bin/' + name


def execute(action, percentage=None):
    values = {'up': '5%+', 'down': '5%-'}
    if action == 'set':
        if percentage is None or not 0 <= percentage <= 100:
            raise ValueError('Brightness must be between 0 and 100')
        value = f'{percentage}%'
    elif action in values:
        value = values[action]
    else:
        raise ValueError('Unknown display action')
    subprocess.run([binary('brightnessctl'), '-e4', '-n2', 'set', value], check=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['up', 'down', 'set'])
    parser.add_argument('percentage', nargs='?', type=int)
    try:
        args=parser.parse_args()
        execute(args.action,args.percentage)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        parser.exit(1, str(error) + '\n')
