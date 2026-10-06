import importlib.util
from pathlib import Path
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location("controls", Path.home() / ".local/lib/material-shell/controls.py")
controls = importlib.util.module_from_spec(spec)
spec.loader.exec_module(controls)


class ControlTests(unittest.TestCase):
    def test_nmcli_terse_escaping(self):
        self.assertEqual(controls.split_nmcli(r"*:Cafe\: East:WPA2\:WPA3:85"),
                         ["*", "Cafe: East", "WPA2:WPA3", "85"])

    def test_wifi_rows_are_deduplicated_and_sorted(self):
        output = "*:Home\\: Office:WPA2:48\n:Guest:--:90\n:Home\\: Office:WPA2:76"
        with patch.object(controls, "run", return_value=output):
            rows = controls.wifi_networks(True, True, {"Home: Office": "saved-uuid"})
        self.assertEqual([row["ssid"] for row in rows], ["Home: Office", "Guest"])
        self.assertTrue(rows[0]["connected"])
        self.assertEqual(rows[0]["signal"], 48)
        self.assertEqual(rows[0]["savedConnection"], "saved-uuid")
        self.assertFalse(rows[1]["secured"])

    def test_bluetooth_lists_connection_and_pairing_state(self):
        def fake_run(args, timeout=6, input_text=None):
            return {
                ("devices",): "Device AA:BB:CC:DD:EE:FF Headphones\nDevice 11:22:33:44:55:66 Keyboard",
                ("devices", "Paired"): "Device AA:BB:CC:DD:EE:FF Headphones",
                ("devices", "Connected"): "Device AA:BB:CC:DD:EE:FF Headphones",
            }.get(tuple(args[1:]), "")
        with patch.object(controls.shutil, "which", return_value="/usr/bin/bluetoothctl"), patch.object(controls, "run", side_effect=fake_run):
            devices = controls.bluetooth_devices(True)
        self.assertEqual(devices[0]["name"], "Headphones")
        self.assertTrue(devices[0]["paired"])
        self.assertTrue(devices[0]["connected"])
        self.assertFalse(devices[1]["paired"])

    def test_status_marks_missing_wifi_hardware_unavailable(self):
        def fake_run(args, timeout=6, input_text=None):
            if args[0] == "nmcli" and args[-1] == "radio":
                return "enabled"
            if args[0] == "nmcli" and args[-1] == "status":
                return "enp5s0:ethernet:connected:Wired"
            if args[0] == "bluetoothctl" and args[1] == "show":
                return "Controller AA:BB:CC:DD:EE:FF\n\tPowered: no"
            return ""
        with patch.object(controls.shutil, "which", return_value="/usr/bin/bluetoothctl"), patch.object(controls, "run", side_effect=fake_run):
            state = controls.status()
        self.assertFalse(state["wifiAvailable"])
        self.assertEqual(state["wifiNetworks"], [])
        self.assertFalse(state["bluetooth"])
        self.assertTrue(state["bluetoothAvailable"])

    def test_password_is_sent_on_stdin_and_not_in_command_arguments(self):
        with patch.object(controls, "execute") as execute:
            controls.action("wifi-connect", ["Secure Wi-Fi"], "secret-value")
        self.assertEqual(execute.call_args.args[0], ["nmcli", "--ask", "device", "wifi", "connect", "Secure Wi-Fi"])
        self.assertEqual(execute.call_args.kwargs["input_text"], "secret-value\n")

    def test_wifi_toggle_switches_existing_radio_state(self):
        with patch.object(controls, "status", side_effect=[{"wifi": True, "wifiAvailable": True}, {"wifi": False}]), patch.object(controls, "execute") as execute:
            controls.action("toggle", ["wifi"])
        execute.assert_called_once_with(["nmcli", "radio", "wifi", "off"])

    def test_invalid_bluetooth_address_is_rejected_before_command(self):
        with patch.object(controls, "execute") as execute:
            with self.assertRaises(ValueError):
                controls.action("bluetooth-connect", ["not-an-address"])
        execute.assert_not_called()


if __name__ == "__main__":
    unittest.main()
