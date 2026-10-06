#!/usr/bin/env python3
"""Network and Bluetooth actions for the Material Shell control panel."""
import argparse
import json
import re
import shutil
import subprocess
import sys


def run(args, timeout=6, input_text=None):
    try:
        result = subprocess.run(args, check=True, capture_output=True, text=True,
                                timeout=timeout, input=input_text)
        return result.stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return None


def split_nmcli(line):
    """Split one nmcli terse row while decoding its backslash escapes."""
    fields, value, escaped = [], [], False
    for char in line:
        if escaped:
            value.append(char)
            escaped = False
        elif char == "\\":
            escaped = True
        elif char == ":":
            fields.append("".join(value))
            value = []
        else:
            value.append(char)
    if escaped:
        value.append("\\")
    fields.append("".join(value))
    return fields


def wifi_profiles():
    rows = run(["nmcli", "--terse", "--escape", "yes", "--fields", "UUID,TYPE",
                "connection", "show"])
    profiles = {}
    for row in (rows or "").splitlines():
        values = split_nmcli(row)
        if len(values) < 2 or values[1] != "802-11-wireless":
            continue
        ssid = run(["nmcli", "--get-values", "802-11-wireless.ssid", "connection",
                    "show", values[0]])
        if ssid:
            profiles.setdefault(ssid, values[0])
    return profiles


def wifi_networks(available, powered, profiles):
    if not available or not powered:
        return []
    rows = run(["nmcli", "--terse", "--escape", "yes", "--fields",
                "IN-USE,SSID,SECURITY,SIGNAL", "device", "wifi", "list"])
    networks = {}
    for row in (rows or "").splitlines():
        values = split_nmcli(row)
        if len(values) < 4:
            continue
        active, ssid, security, signal = values[:4]
        hidden = not ssid
        ssid = ssid or "非公開ネットワーク"
        try:
            signal = max(0, min(100, int(signal)))
        except ValueError:
            signal = 0
        candidate = {
            "ssid": ssid,
            "security": security,
            "secured": bool(security and security != "--"),
            "signal": signal,
            "connected": active == "*",
            "hidden": hidden,
            "savedConnection": profiles.get(ssid, ""),
        }
        existing = networks.get(ssid)
        if (existing is None or (candidate["connected"] and not existing["connected"])
                or (candidate["connected"] == existing["connected"] and signal > existing["signal"])):
            networks[ssid] = candidate
    return sorted(networks.values(), key=lambda item: (not item["connected"], -item["signal"], item["ssid"].casefold()))


def bluetooth_devices(powered):
    if not shutil.which("bluetoothctl"):
        return []
    all_text = run(["bluetoothctl", "devices"])
    paired_text = run(["bluetoothctl", "devices", "Paired"])
    connected_text = run(["bluetoothctl", "devices", "Connected"])
    pattern = re.compile(r"^Device\s+([0-9A-Fa-f:]{17})\s+(.+?)\s*$")

    def parse(text):
        found = {}
        for line in (text or "").splitlines():
            match = pattern.match(line)
            if match:
                found[match.group(1).upper()] = match.group(2)
        return found

    all_devices = parse(all_text)
    paired = parse(paired_text)
    connected = parse(connected_text)
    for address, name in paired.items():
        all_devices.setdefault(address, name)
    for address, name in connected.items():
        all_devices.setdefault(address, name)
    return sorted(({
        "address": address,
        "name": name,
        "paired": address in paired,
        "connected": address in connected,
        "available": bool(powered),
    } for address, name in all_devices.items()),
        key=lambda item: (not item["connected"], not item["paired"], item["name"].casefold()))


def status():
    wifi_radio = run(["nmcli", "--terse", "--fields", "WIFI", "radio"])
    device_rows = run(["nmcli", "--terse", "--escape", "yes", "--fields",
                       "DEVICE,TYPE,STATE,CONNECTION", "device", "status"])
    wifi_available = bool(device_rows is not None and any(
        len(split_nmcli(row)) > 1 and split_nmcli(row)[1] == "wifi"
        for row in device_rows.splitlines()))
    wifi = wifi_radio == "enabled" if wifi_radio is not None else None
    profiles = wifi_profiles() if wifi_available else {}
    networks = wifi_networks(wifi_available, wifi is True, profiles)
    active = next((item["ssid"] for item in networks if item["connected"]), "")

    bluetooth_text = run(["bluetoothctl", "show"]) if shutil.which("bluetoothctl") else None
    powered_match = re.search(r"^\s*Powered:\s*(yes|no)\s*$", bluetooth_text or "", re.MULTILINE)
    bluetooth = powered_match.group(1) == "yes" if powered_match else None
    return {
        "wifi": wifi,
        "wifiAvailable": wifi_available,
        "wifiConnected": active,
        "wifiNetworks": networks,
        "bluetooth": bluetooth,
        "bluetoothAvailable": bluetooth is not None,
        "bluetoothDevices": bluetooth_devices(bluetooth is True),
    }


def execute(args, timeout=12, input_text=None):
    try:
        subprocess.run(args, check=True, capture_output=True, text=True,
                       timeout=timeout, input=input_text)
    except (OSError, subprocess.SubprocessError) as error:
        detail = getattr(error, "stderr", "") or str(error)
        raise RuntimeError(detail.strip() or "操作に失敗しました") from error


def action(name, args, password=""):
    if name == "toggle":
        if args[0] not in ("wifi", "bluetooth"):
            raise ValueError("Unknown control")
        current = status()
        control = args[0]
        if not current[control + "Available"]:
            raise RuntimeError(f"{control} is unavailable")
        enabled = "on" if not current[control] else "off"
        command = ["nmcli", "radio", "wifi", enabled] if control == "wifi" else ["bluetoothctl", "power", enabled]
        execute(command)
    elif name == "scan-wifi":
        if not status()["wifiAvailable"]:
            raise RuntimeError("Wi-Fiアダプターを利用できません")
        execute(["nmcli", "--wait", "12", "device", "wifi", "list", "--rescan", "yes"], timeout=15)
    elif name == "scan-bluetooth":
        current = status()
        if not current["bluetoothAvailable"]:
            raise RuntimeError("Bluetoothアダプターを利用できません")
        if not current["bluetooth"]:
            raise RuntimeError("先にBluetoothをオンにしてください")
        execute(["bluetoothctl", "--timeout", "10", "scan", "on"], timeout=14)
    elif name == "wifi-connect":
        ssid = args[0]
        profile = args[1] if len(args) > 1 else ""
        if profile:
            execute(["nmcli", "--ask", "connection", "up", "uuid", profile], timeout=30,
                    input_text=(password + "\n") if password else "")
        else:
            execute(["nmcli", "--ask", "device", "wifi", "connect", ssid], timeout=30,
                    input_text=(password + "\n") if password else "")
    elif name == "wifi-disconnect":
        rows = run(["nmcli", "--terse", "--escape", "yes", "--fields", "DEVICE,TYPE",
                    "device", "status"])
        interface = next((split_nmcli(row)[0] for row in (rows or "").splitlines()
                          if len(split_nmcli(row)) > 1 and split_nmcli(row)[1] == "wifi"), "")
        if not interface:
            raise RuntimeError("Wi-Fiアダプターを利用できません")
        execute(["nmcli", "device", "disconnect", "ifname", interface])
    elif name in ("bluetooth-connect", "bluetooth-disconnect", "bluetooth-pair", "bluetooth-remove"):
        address = args[0].upper()
        if not re.fullmatch(r"[0-9A-F]{2}(?::[0-9A-F]{2}){5}", address):
            raise ValueError("Invalid Bluetooth address")
        operation = name.removeprefix("bluetooth-")
        execute(["bluetoothctl", operation, address], timeout=30)
        if operation == "pair":
            execute(["bluetoothctl", "trust", address])
            execute(["bluetoothctl", "connect", address], timeout=30)
    else:
        raise ValueError("Unknown action")
    return status()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="action", required=True)
    subparsers.add_parser("status")
    toggle = subparsers.add_parser("toggle")
    toggle.add_argument("control", choices=("wifi", "bluetooth"))
    subparsers.add_parser("scan-wifi")
    subparsers.add_parser("scan-bluetooth")
    connect = subparsers.add_parser("wifi-connect")
    connect.add_argument("ssid")
    connect.add_argument("profile", nargs="?")
    connect.add_argument("--password-stdin", action="store_true")
    subparsers.add_parser("wifi-disconnect")
    for action_name in ("bluetooth-connect", "bluetooth-disconnect", "bluetooth-pair", "bluetooth-remove"):
        device = subparsers.add_parser(action_name)
        device.add_argument("address")
    args = parser.parse_args()
    password = sys.stdin.readline().rstrip("\r\n") if args.action == "wifi-connect" and args.password_stdin else ""
    try:
        if args.action == "status":
            result = status()
        else:
            if args.action == "toggle":
                arguments = [args.control]
            elif args.action == "wifi-connect":
                arguments = [args.ssid, args.profile] if args.profile else [args.ssid]
            elif args.action.startswith("bluetooth-"):
                arguments = [args.address]
            else:
                arguments = []
            result = action(args.action, arguments, password)
        print(json.dumps(result, ensure_ascii=False))
    except (OSError, RuntimeError, ValueError, subprocess.SubprocessError) as error:
        parser.exit(1, str(error) + "\n")


if __name__ == "__main__":
    main()
