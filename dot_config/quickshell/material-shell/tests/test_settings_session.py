import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path.home()/'.local/lib/material-shell'
sys.path.insert(0,str(ROOT))
import settings
import session
import services
import audio
import display

class HotkeyTests(unittest.TestCase):
    def test_audio_actions_are_fixed_commands(self):
        with patch.object(audio.subprocess, 'run') as run:
            audio.execute('volume-up')
            run.assert_called_once_with([audio.binary('wpctl'), 'set-volume', '-l', '1', '@DEFAULT_AUDIO_SINK@', '5%+'], check=True)
        with self.assertRaises(ValueError): audio.execute('arbitrary command')

    def test_display_actions_are_fixed_commands(self):
        with patch.object(display.subprocess, 'run') as run:
            display.execute('down')
            run.assert_called_once_with([display.binary('brightnessctl'), '-e4', '-n2', 'set', '5%-'], check=True)
        with self.assertRaises(ValueError): display.execute('arbitrary command')

class SettingsTests(unittest.TestCase):
    def test_settings_roundtrip_and_failed_save_retains_file(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(settings,'CONFIG',Path(tmp)/'settings.json'):
            data=dict(settings.DEFAULTS,workspaces=7,showCpu=False)
            settings.save(data)
            self.assertEqual(settings.read(),data)
            original=settings.CONFIG.read_bytes()
            for invalid in [dict(data,workspaces=0),dict(data,showCpu=1),dict(data,autoLockMinutes=20,screenOffMinutes=10),dict(data,unknown=True)]:
                with self.assertRaises(ValueError):settings.save(invalid)
                self.assertEqual(settings.CONFIG.read_bytes(),original)

    def test_idle_settings_produce_timeouts(self):
        args=services.idle_command(dict(settings.DEFAULTS,autoLockMinutes=5,screenOffMinutes=10))
        self.assertIn('300',args);self.assertIn('600',args)
        self.assertIn('before-sleep',args);self.assertIn('lock',args)

class SessionTests(unittest.TestCase):
    def test_suspend_waits_for_secure_lock(self):
        calls=[]
        with patch.object(session,'lock',side_effect=lambda:calls.append('secure')),patch.object(session.subprocess,'run',side_effect=lambda args,**kwargs:calls.append(args)):
            session.execute('suspend')
        self.assertEqual(calls,['secure',['systemctl','suspend']])

    def test_failed_lock_prevents_suspend(self):
        with patch.object(session,'lock',side_effect=RuntimeError('not secure')),patch.object(session.subprocess,'run') as run:
            with self.assertRaises(RuntimeError):session.execute('suspend')
            run.assert_not_called()

    def test_actions_are_whitelisted(self):
        with patch.object(session.subprocess,'run') as run:
            with self.assertRaises(ValueError):session.execute('arbitrary command')
            run.assert_not_called()

if __name__=='__main__':unittest.main()
