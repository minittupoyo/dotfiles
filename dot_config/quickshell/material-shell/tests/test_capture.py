import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
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
            path=capture.capture()
            self.assertTrue(path.is_file());self.assertTrue(path.read_bytes().startswith(b'\x89PNG'))
            self.assertEqual(copies,[path.read_bytes()])
            self.assertEqual(path.stat().st_mode&0o777,0o600)
    def test_cancelled_region_does_not_capture(self):
        with patch.object(capture.subprocess,'run',return_value=subprocess.CompletedProcess([],1)) as run:
            self.assertIsNone(capture.capture(True));self.assertEqual(run.call_count,1)
if __name__=='__main__':unittest.main()
