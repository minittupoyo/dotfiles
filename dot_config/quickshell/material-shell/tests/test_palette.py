import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path.home() / ".local/lib/material-shell"))
import palette


class PaletteTests(unittest.TestCase):
    def test_generate_keeps_both_matugen_schemes(self):
        raw = {"colors": {
            role: {"light": "#abcdef", "dark": "#123456"}
            for role in palette.ROLES
        }}
        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "wallpaper.png"
            image.write_bytes(b"test")
            with patch.object(palette, "run", return_value=json.dumps(raw)) as run:
                result = palette.generate(image)
        self.assertEqual(result["version"], 2)
        self.assertEqual(result["schemes"]["light"]["surface"], "#abcdef")
        self.assertEqual(result["schemes"]["dark"]["surface"], "#123456")
        self.assertIn("--mode", run.call_args.args[0])

    def test_generate_rejects_incomplete_scheme(self):
        raw = {"colors": {
            role: {"light": "#abcdef", "dark": "not-a-color"}
            for role in palette.ROLES
        }}
        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "wallpaper.png"
            image.write_bytes(b"test")
            with patch.object(palette, "run", return_value=json.dumps(raw)):
                with self.assertRaises(ValueError):
                    palette.generate(image)


if __name__ == "__main__":
    unittest.main()
