"""Run with xvfb-run on Debian; exercises real GTK callbacks, mocks Flatpak only."""
import importlib.machinery
import importlib.util
import io
import os
from pathlib import Path
import tempfile
import time
import sys
from unittest.mock import Mock, patch
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib
root = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader('welcome', str(root / 'config/includes.chroot/usr/local/libexec/ttablet-welcome'))
spec = importlib.util.spec_from_loader(loader.name, loader)
w = importlib.util.module_from_spec(spec)
loader.exec_module(w)
catalog = root / 'config/includes.chroot/usr/share/ttablet/optional-apps.json'
load = w.load_catalog


def exercise():
    window = next(x for x in Gtk.Window.list_toplevels() if x.get_title() == 'TTablet Welcome')
    assert len(window.options) == 3
    assert not any(b.get_active() for b, _ in window.options)
    window.start()
    assert 'No downloads' in window.status.get_text()
    window.options[0][0].set_active(True)
    with patch.object(Gtk.Dialog, 'run', return_value=Gtk.ResponseType.CANCEL), patch.object(w.subprocess, 'Popen') as spawn:
        window.start()
        spawn.assert_not_called()
    for code in (1, 0):
        process = Mock(stdout=io.StringIO('test transaction\n'))
        process.wait.return_value = code
        with patch.object(Gtk.Dialog, 'run', return_value=Gtk.ResponseType.OK), patch.object(w.subprocess, 'Popen', return_value=process) as spawn:
            window.start()
            deadline = time.monotonic() + 5
            while window.busy and time.monotonic() < deadline:
                GLib.MainContext.default().iteration(False)
                time.sleep(.01)
            assert not window.busy
            assert spawn.call_count == 1
            assert spawn.call_args.args[0][-1] == 'org.gnome.Papers'
            assert ('did not finish' if code else 'Apps are ready') in window.status.get_text()
    window.close()
    assert w.STATE.exists()
    window.destroy()

with tempfile.TemporaryDirectory() as temporary:
    os.environ['XDG_RUNTIME_DIR'] = temporary
    w.STATE = Path(temporary) / 'first/complete'
    with patch.object(w, 'load_catalog', side_effect=lambda: load(catalog)), patch.object(w, 'installed_scope', return_value=None), patch.object(Gtk, 'main', side_effect=exercise), patch.object(Gtk, 'main_quit'), patch.object(sys, 'argv', ['welcome']):
        w.main()
    assert not (Path(temporary) / 'second/complete').exists()
    print('PASS: GTK zero-selection, confirmation cancel, failed install, retry, completion and per-user dismissal')
