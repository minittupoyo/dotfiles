#!/usr/bin/env python3
"""Whitelisted audio hotkey actions."""
import argparse
import shutil
import subprocess


def binary(name):
    return shutil.which(name) or '/usr/bin/' + name


def execute(action):
    commands = {
        'volume-up': ['wpctl', 'set-volume', '-l', '1', '@DEFAULT_AUDIO_SINK@', '5%+'],
        'volume-down': ['wpctl', 'set-volume', '@DEFAULT_AUDIO_SINK@', '5%-'],
        'mute-toggle': ['wpctl', 'set-mute', '@DEFAULT_AUDIO_SINK@', 'toggle'],
        'mic-mute-toggle': ['wpctl', 'set-mute', '@DEFAULT_AUDIO_SOURCE@', 'toggle'],
    }
    if action not in commands:
        raise ValueError('Unknown audio action')
    command = commands[action]
    subprocess.run([binary(command[0]), *command[1:]], check=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['volume-up', 'volume-down', 'mute-toggle', 'mic-mute-toggle'])
    try:
        execute(parser.parse_args().action)
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        parser.exit(1, str(error) + '\n')
