#!/usr/bin/env python3
"""One shared sampler; bounded subprocesses, no third-party Python dependencies."""
import json, pathlib, subprocess, time

def command(args):
    try:
        return subprocess.check_output(args, text=True, timeout=2, stderr=subprocess.DEVNULL).strip()
    except (OSError, subprocess.SubprocessError):
        return ''

def cpu():
    values = list(map(int, pathlib.Path('/proc/stat').read_text().splitlines()[0].split()[1:9]))
    return sum(values), values[3] + values[4]

previous = cpu()
tick = 0
network = {'network': '確認中', 'networkIcon': 'wifi_off'}
while True:
    current = cpu()
    elapsed = current[0] - previous[0]
    usage = round(100 * (1 - (current[1] - previous[1]) / elapsed)) if elapsed else 0
    previous = current
    memory = {line.split(':')[0]: int(line.split()[1]) for line in pathlib.Path('/proc/meminfo').read_text().splitlines()}
    if tick % 5 == 0:
        devices = command(['nmcli', '-t', '-f', 'TYPE,STATE', 'device']).splitlines()
        wifi = any(line == 'wifi:connected' for line in devices)
        wired = any(line == 'ethernet:connected' for line in devices)
        network = {'network': 'Wi-Fi' if wifi else 'Ethernet' if wired else 'オフライン', 'networkIcon': 'wifi' if wifi else 'lan' if wired else 'wifi_off'}
    batteries = []
    for device in pathlib.Path('/sys/class/power_supply').glob('*'):
        try:
            if (device / 'type').read_text().strip() == 'Battery':
                batteries.append({'percentage': int((device / 'capacity').read_text()), 'charging': (device / 'status').read_text().strip() == 'Charging'})
        except OSError:
            pass
    brightness = None
    for backlight in pathlib.Path('/sys/class/backlight').glob('*'):
        try:
            brightness = round(100 * int((backlight / 'brightness').read_text()) / int((backlight / 'max_brightness').read_text()))
            break
        except (OSError, ValueError, ZeroDivisionError): pass
    print(json.dumps({'cpu': max(0, min(100, usage)), 'memory': round(100 * (1 - memory['MemAvailable'] / memory['MemTotal'])), 'battery': batteries[0] if batteries else None, 'brightness': brightness, **network}), flush=True)
    tick += 1
    time.sleep(2)
