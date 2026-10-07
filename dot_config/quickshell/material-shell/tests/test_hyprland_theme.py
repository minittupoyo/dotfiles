#!/usr/bin/env python3
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch, MagicMock

sys.path.insert(0, str(Path.home() / ".local/lib/material-shell"))
import hyprland_theme
import palette
import settings


class HyprlandThemeTests(unittest.TestCase):
    def test_hex_to_rgba(self):
        self.assertEqual(hyprland_theme.hex_to_rgba("#112233", "ee"), "rgba(112233ee)")
        self.assertEqual(hyprland_theme.hex_to_rgba("aabbcc", "aa"), "rgba(aabbccaa)")
        self.assertIsNone(hyprland_theme.hex_to_rgba("invalid"))
        self.assertIsNone(hyprland_theme.hex_to_rgba(None))

    def test_resolve_colors_from_palette_light(self):
        sample_palette = {
            "version": 2,
            "schemes": {
                "light": {
                    "primary": "#123456",
                    "primary_container": "#abcdef",
                    "outline": "#789abc",
                },
                "dark": {
                    "primary": "#654321",
                    "primary_container": "#fedcba",
                    "outline": "#cba987",
                },
            },
        }
        colors = hyprland_theme.resolve_colors(palette=sample_palette, mode="light")
        self.assertEqual(colors["active_border_1"], "rgba(123456ee)")
        self.assertEqual(colors["active_border_2"], "rgba(abcdefee)")
        self.assertEqual(colors["inactive_border"], "rgba(789abcaa)")

    def test_resolve_colors_from_palette_dark(self):
        sample_palette = {
            "version": 2,
            "schemes": {
                "light": {
                    "primary": "#123456",
                    "primary_container": "#abcdef",
                    "outline": "#789abc",
                },
                "dark": {
                    "primary": "#654321",
                    "primary_container": "#fedcba",
                    "outline": "#cba987",
                },
            },
        }
        colors = hyprland_theme.resolve_colors(palette=sample_palette, mode="dark")
        self.assertEqual(colors["active_border_1"], "rgba(654321ee)")
        self.assertEqual(colors["active_border_2"], "rgba(fedcbaee)")
        self.assertEqual(colors["inactive_border"], "rgba(cba987aa)")

    def test_resolve_colors_fallback(self):
        colors_dark = hyprland_theme.resolve_colors(palette={}, mode="dark")
        fb_dark = hyprland_theme.FALLBACK["dark"]
        self.assertEqual(colors_dark["active_border_1"], hyprland_theme.hex_to_rgba(fb_dark["primary"], "ee"))
        self.assertEqual(colors_dark["active_border_2"], hyprland_theme.hex_to_rgba(fb_dark["primary_container"], "ee"))
        self.assertEqual(colors_dark["inactive_border"], hyprland_theme.hex_to_rgba(fb_dark["outline"], "aa"))

        colors_light = hyprland_theme.resolve_colors(palette={}, mode="light")
        fb_light = hyprland_theme.FALLBACK["light"]
        self.assertEqual(colors_light["active_border_1"], hyprland_theme.hex_to_rgba(fb_light["primary"], "ee"))
        self.assertEqual(colors_light["active_border_2"], hyprland_theme.hex_to_rgba(fb_light["primary_container"], "ee"))
        self.assertEqual(colors_light["inactive_border"], hyprland_theme.hex_to_rgba(fb_light["outline"], "aa"))

    def test_generate_lua(self):
        colors = {
            "active_border_1": "rgba(111111ee)",
            "active_border_2": "rgba(222222ee)",
            "inactive_border": "rgba(333333aa)",
        }
        lua = hyprland_theme.generate_lua(colors)
        self.assertIn('colors = { "rgba(111111ee)", "rgba(222222ee)" }', lua)
        self.assertIn('angle = 45', lua)
        self.assertIn('inactive_border = "rgba(333333aa)"', lua)

    def test_save_config(self):
        colors = {
            "active_border_1": "rgba(111111ee)",
            "active_border_2": "rgba(222222ee)",
            "inactive_border": "rgba(333333aa)",
        }
        with tempfile.TemporaryDirectory() as tmp_dir:
            hyprland_theme.save_config(colors, config_dir=tmp_dir)
            target = Path(tmp_dir) / "theme.lua"
            self.assertTrue(target.is_file())
            content = target.read_text()
            self.assertIn("rgba(111111ee)", content)

    def test_apply_runtime_calls_hyprctl(self):
        colors = {
            "active_border_1": "rgba(111111ee)",
            "active_border_2": "rgba(222222ee)",
            "inactive_border": "rgba(333333aa)",
        }
        with patch("shutil.which", return_value="/fake/hyprctl"), \
             patch("subprocess.run") as mock_run:
            mock_run.return_value = MagicMock(returncode=0)
            success = hyprland_theme.apply_runtime(colors)
            self.assertTrue(success)
            mock_run.assert_called_once()
            args = mock_run.call_args[0][0]
            self.assertEqual(args[0], "/fake/hyprctl")
            self.assertEqual(args[1], "eval")
            self.assertIn("rgba(111111ee)", args[2])

    def test_apply_runtime_handles_failure(self):
        colors = {
            "active_border_1": "rgba(111111ee)",
            "active_border_2": "rgba(222222ee)",
            "inactive_border": "rgba(333333aa)",
        }
        with patch("shutil.which", return_value="/fake/hyprctl"), \
             patch("subprocess.run", side_effect=subprocess.SubprocessError("timeout")):
            success = hyprland_theme.apply_runtime(colors)
            self.assertFalse(success)

    def test_settings_save_triggers_hyprland_theme(self):
        with tempfile.TemporaryDirectory() as tmp, \
             patch.object(settings, "CONFIG", Path(tmp) / "settings.json"), \
             patch.object(hyprland_theme, "apply") as mock_apply:
            data = dict(settings.DEFAULTS, themeMode="light")
            settings.save(data)
            mock_apply.assert_called_once_with(mode="light")


if __name__ == "__main__":
    unittest.main()
