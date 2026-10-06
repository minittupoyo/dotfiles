import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('backend', Path(__file__).resolve().parents[1] / 'wallpaper_backend.py')
backend = importlib.util.module_from_spec(spec)
spec.loader.exec_module(backend)


class BackendTests(unittest.TestCase):
    def test_query_names_paths_and_unset_output(self):
        text = ': DP-2: 2560x1440, scale: 1, currently displaying: image: /壁紙/a b.jpg\n: DP-3: 2560x1440, scale: 1, currently displaying: color: 000000'
        with patch.object(backend, 'run', return_value=text):
            self.assertEqual(backend.query(), [('DP-2', '/壁紙/a b.jpg'), ('DP-3', '')])

    def test_sync_restores_only_unset_outputs(self):
        with patch.object(backend, 'ensure_daemon', return_value=[('DP-2', '/current.png'), ('DP-3', '')]), patch.object(backend, 'saved_path', return_value='/saved.png'), patch.object(backend, 'render') as render:
            backend.sync()
            render.assert_called_once_with('/saved.png', ['DP-3'])

    def test_successful_render_persists_and_failed_render_retains_state(self):
        with tempfile.TemporaryDirectory() as tmp:
            state = Path(tmp); image = state / 'image.png'; image.write_bytes(b'image')
            with patch.object(backend, 'STATE', state), patch.object(backend, 'ensure_daemon'), patch.object(backend, 'render') as render:
                backend.set_wallpaper(image)
                self.assertEqual(backend.saved_path(), str(image))
                saved = (state / 'wallpaper.json').read_bytes()
                render.side_effect = OSError('Render failed')
                with self.assertRaises(OSError): backend.set_wallpaper(state / 'other.png')
                self.assertEqual((state / 'wallpaper.json').read_bytes(), saved)


if __name__ == '__main__': unittest.main()
