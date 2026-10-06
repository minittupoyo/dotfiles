#!/usr/bin/env python3
"""Exercise real Wayland panels and desktop-entry launches using disposable apps."""
import os
from pathlib import Path
import subprocess
import tempfile
import uuid

root = Path(__file__).resolve().parents[1]
appdir = Path(os.environ.get('XDG_DATA_HOME', str(Path.home() / '.local/share'))) / 'applications'
appdir.mkdir(parents=True, exist_ok=True)
identifier = uuid.uuid4().hex
entries = []
try:
    with tempfile.TemporaryDirectory(prefix='material-shell-tests-') as directory:
        tmp = Path(directory)
        probe = tmp / 'probe.py'
        probe.write_text("from pathlib import Path\nimport os,sys\nPath(sys.argv[1] + '.ok').write_text(os.getcwd())\n")
        for mode in ['regular', 'terminal']:
            entry = appdir / f'material-shell-test-{identifier}-{mode}.desktop'
            entries.append(entry)
            entry.write_text(f'[Desktop Entry]\nType=Application\nName=Material Shell Test {identifier} {mode}\n'
                             f'Exec=/usr/bin/python3 {probe} {mode}\nPath={tmp}\n'
                             f'Terminal={str(mode == "terminal").lower()}\nIcon=utilities-terminal\n')
        fixture = (root / 'tests/live-launcher.qml.in').read_text()
        fixture = fixture.replace('@@IMPORT@@', root.as_uri())
        fixture = fixture.replace('@@REGULAR@@', f'Material Shell Test {identifier} regular')
        fixture = fixture.replace('@@TERMINAL@@', f'Material Shell Test {identifier} terminal')
        (tmp / 'shell.qml').write_text(fixture)
        env = dict(os.environ, FONTCONFIG_FILE=str(root / 'fonts.conf'))
        result = subprocess.run(['quickshell', '-p', str(tmp), '--no-color'], env=env,
                                stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=20)
        print(result.stdout)
        if result.returncode != 0 or 'passed=6 failed=0' not in result.stdout:
            raise RuntimeError('Live launcher tests failed')
        # Terminal startup may finish after the panel process exits.
        import time
        for mode in ['regular', 'terminal']:
            marker = tmp / (mode + '.ok')
            deadline = time.monotonic() + 5
            while not marker.exists() and time.monotonic() < deadline:
                time.sleep(0.05)
            assert marker.read_text() == str(tmp), f'Invalid working directory for {mode}'
        print('Regular and terminal entry launches: PASS')
finally:
    for entry in entries:
        entry.unlink(missing_ok=True)
