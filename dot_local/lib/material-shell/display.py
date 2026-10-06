#!/usr/bin/env python3
"""Whitelisted display brightness hotkey actions."""
import argparse
import shutil
import subprocess


def binary(name):
    return shutil.which(name) or '/usr/bin/' + name


def execute(action):
    values = {'up': '5%+', 'down': '5%-'}
    if action not in values:
        raise ValueError('Unknown display action')
    subprocess.run([binary('brightnessctl'), '-e4', '-n2', 'set', values[action]], check=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['up', 'down'])
    try:
        execute(parser.parse_args().action)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        parser.exit(1, str(error) + '\n')
