import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
spec = importlib.util.spec_from_file_location('wallpapers', Path(__file__).resolve().parents[1] / 'wallpapers.py')
library = importlib.util.module_from_spec(spec)
spec.loader.exec_module(library)


class LibraryTests(unittest.TestCase):
    def test_nested_images_urls_dedup_and_directory_persistence(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            folder = root / '壁紙'; folder.mkdir()
            nested = folder / 'sub'; nested.mkdir()
            image = nested / '日本語 #1.PNG'; image.write_bytes(b'image')
            (folder / 'notes.txt').write_text('not an image')
            (folder / 'loop').symlink_to(folder, target_is_directory=True)
            config = root / 'config/wallpapers.json'
            with patch.object(library, 'CONFIG', config), patch.object(library.backend, 'current_wallpaper', return_value=image):
                result = library.scan(str(folder))
                self.assertEqual(len(result['images']), 1)
                self.assertIn('%23', result['images'][0]['url'])
                self.assertEqual(result['directories'], [str(folder)])
                self.assertEqual(library.scan()['images'], result['images'])
                saved = config.read_bytes()
                with self.assertRaises(OSError): library.scan(str(root / 'missing'))
                self.assertEqual(config.read_bytes(), saved)

    def test_empty_folder_still_contains_current_wallpaper(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp); current = root / 'current.png'; current.write_bytes(b'image')
            empty = root / 'empty'; empty.mkdir()
            with patch.object(library, 'CONFIG', root / 'config.json'), patch.object(library.backend, 'current_wallpaper', return_value=current):
                self.assertEqual(library.scan(str(empty))['images'][0]['path'], str(current))


if __name__ == '__main__': unittest.main()
