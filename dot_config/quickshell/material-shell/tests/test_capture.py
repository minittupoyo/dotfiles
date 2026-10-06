import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import Mock, patch
spec=importlib.util.spec_from_file_location('capture',Path(__file__).resolve().parents[1]/'capture.py')
capture=importlib.util.module_from_spec(spec);spec.loader.exec_module(capture)
class CaptureTests(unittest.TestCase):
    def test_real_grim_capture_without_changing_clipboard(self):
        original_run=subprocess.run
        prefix=Path.home()/'.local/bin'
        copies=[]
        def run(args,**kwargs):
            if args[0].endswith('/wl-copy'):
                copies.append(kwargs['input']);return subprocess.CompletedProcess(args,0)
            return original_run(args,**kwargs)
        with tempfile.TemporaryDirectory() as tmp,patch.object(capture.Path,'home',return_value=Path(tmp)),patch.object(capture,'binary',side_effect=lambda name:str(prefix/name)),patch.object(capture.subprocess,'run',side_effect=run):
            path,copied=capture.capture()
            self.assertTrue(copied)
            self.assertTrue(path.is_file());self.assertTrue(path.read_bytes().startswith(b'\x89PNG'))
            self.assertEqual(copies,[path.read_bytes()])
            self.assertEqual(path.stat().st_mode&0o777,0o600)
    def test_cancelled_region_does_not_capture(self):
        selector=Mock();selector.communicate.return_value=('', '');selector.returncode=1
        with patch.object(capture.subprocess,'Popen',return_value=selector) as run:
            self.assertIsNone(capture.capture(True));self.assertEqual(run.call_count,1)
    def test_selected_region_is_captured_and_copied(self):
        original_run=subprocess.run
        prefix=Path.home()/'.local/bin'
        copies=[]
        def run(args,**kwargs):
            if args[0].endswith('/wl-copy'):
                copies.append(kwargs['input']);return subprocess.CompletedProcess(args,0)
            return original_run(args,**kwargs)
        with tempfile.TemporaryDirectory() as tmp:
            home=Path(tmp)
            with patch.object(capture.Path,'home',return_value=home),patch.object(capture,'binary',side_effect=lambda name:str(prefix/name)),patch.object(capture.subprocess,'run',side_effect=run):
                result=capture.capture(True,geometry='0,0 64x64')
            path,copied=result
            self.assertTrue(copied);self.assertTrue(path.is_file())
            self.assertTrue(path.read_bytes().startswith(b'\x89PNG'))
            self.assertEqual(copies,[path.read_bytes()])
if __name__=='__main__':unittest.main()
