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

    def test_update_syncs_hyprland_theme(self):
        raw = {"colors": {
            role: {"light": "#abcdef", "dark": "#123456"}
            for role in palette.ROLES
        }}
        with tempfile.TemporaryDirectory() as directory:
            state_dir = Path(directory) / "state"
            state_dir.mkdir()
            image = Path(directory) / "wallpaper.png"
            image.write_bytes(b"test")
            with patch.object(palette, "STATE", state_dir), \
                 patch.object(palette, "run", return_value=json.dumps(raw)), \
                 patch.object(palette.backend, "save"), \
                 patch.object(palette, "apply_matugen"), \
                 patch("hyprland_theme.apply") as mock_apply:
                palette.update(path=str(image))
                mock_apply.assert_called_once()
                self.assertEqual(mock_apply.call_args.kwargs["palette"]["schemes"]["light"]["surface"], "#abcdef")


    def test_apply_matugen_invokes_command(self):
        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / "wallpaper.png"
            image.write_bytes(b"test")
            config_dir = Path(directory) / "matugen"
            config_dir.mkdir()
            config_file = config_dir / "config.toml"
            config_file.write_text("[config]\n")

            with patch.object(palette.subprocess, "run") as mock_run, \
                 patch.dict(palette.os.environ, {"XDG_CONFIG_HOME": str(directory)}):
                mock_run.return_value.returncode = 0
                result = palette.apply_matugen(path=image, mode="light")
                self.assertTrue(result)
                mock_run.assert_called_once()
                args = mock_run.call_args[0][0]
                self.assertIn("image", args)
                self.assertIn(str(image), args)
                self.assertIn("--mode", args)
                self.assertIn("light", args)
                self.assertIn("--config", args)
                self.assertIn(str(config_file), args)


if __name__ == "__main__":
    unittest.main()

