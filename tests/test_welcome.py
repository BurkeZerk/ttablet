import importlib.machinery
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

root = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader('welcome', str(root / 'config/includes.chroot/usr/local/libexec/ttablet-welcome'))
spec = importlib.util.spec_from_loader(loader.name, loader)
w = importlib.util.module_from_spec(spec)
loader.exec_module(w)

class WelcomeTests(unittest.TestCase):
    def test_live_and_other_sessions_never_autostart(self):
        self.assertFalse(w.first_run_allowed('quiet boot=live persistence', 'Phosh', False))
        self.assertFalse(w.first_run_allowed('quiet', 'GNOME', False))
        self.assertFalse(w.first_run_allowed('quiet', 'Phosh', True))
        self.assertTrue(w.first_run_allowed('quiet', 'GNOME:Phosh', False))
        self.assertTrue(w.first_run_allowed('quiet', 'Phosh', False))

    def test_existing_user_app_is_preserved(self):
        with patch.object(w.subprocess, 'run') as run:
            run.return_value.returncode = 0
            self.assertEqual(w.installed_scope(w.BAZAAR), 'system')
            self.assertEqual(run.call_count, 1)
            run.reset_mock()
            run.side_effect = [type('Result', (), {'returncode': 1})(), type('Result', (), {'returncode': 0})()]
            self.assertEqual(w.installed_scope(w.BAZAAR), 'user')
            self.assertEqual(run.call_args.args[0], ['flatpak', 'info', '--user', w.BAZAAR])

    def test_missing_apps_and_catalog(self):
        with patch.object(w.subprocess, 'run') as run:
            run.return_value.returncode = 1
            self.assertIsNone(w.installed_scope(w.BAZAAR))
        catalog = root / 'config/includes.chroot/usr/share/ttablet/optional-apps.json'
        self.assertEqual(len(w.load_catalog(catalog)), 3)
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / 'apps.json'
            for ids in [['--delete-data'], ['org.test.App', 'org.test.App'], ['bad app']]:
                path.write_text(json.dumps({'version': 1, 'apps': [{'id': x} for x in ids]}))
                with self.assertRaises(ValueError):
                    w.load_catalog(path)

if __name__ == '__main__':
    unittest.main()
