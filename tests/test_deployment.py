"""Filesystem regressions; network and package managers are never invoked."""
import os
import hashlib
import io
import json
import tarfile
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class DeploymentTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='lazyvim-test-')
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name)
        self.env = {**os.environ, 'HOME': str(self.home),
                    'XDG_CONFIG_HOME': str(self.home / 'config'),
                    'XDG_DATA_HOME': str(self.home / 'data'),
                    'XDG_STATE_HOME': str(self.home / 'state'),
                    'XDG_CACHE_HOME': str(self.home / 'cache')}
        self.env['PATH'] = '/usr/bin:/bin'
        self.env.pop('NVIM_APPNAME', None)
        self.env.pop('FORCE_INSTALL', None)

    def run_install(self, body):
        return subprocess.run(['bash', '-c', 'source "$1/install.sh"\n' + body,
                               'test', str(ROOT)], env=self.env,
                              capture_output=True, text=True, timeout=20)

    def test_first_install_creates_xdg_parent(self):
        result = self.run_install('install_config')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertTrue((self.home / 'config/nvim/init.lua').is_file())

    def test_backup_uses_config_parent(self):
        old = self.home / 'config/nvim'
        old.mkdir(parents=True)
        (old / 'personal.lua').write_text('personal')
        result = self.run_install('FORCE_INSTALL=true; backup_existing_config')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        backups = list((self.home / 'config').glob('nvim.backup.*/personal.lua'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), 'personal')

    def test_path_binary_is_reused(self):
        bindir = self.home / 'bin'
        bindir.mkdir()
        binary = bindir / 'nvim'
        binary.write_text('#!/bin/sh\necho "NVIM v0.11.7"\n')
        binary.chmod(0o755)
        self.env['PATH'] = str(bindir) + ':' + self.env['PATH']
        result = self.run_install('check_neovim; "$NVIM_BIN" --version')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_plugin_failure_is_fatal(self):
        (self.home / 'data/nvim/lazy/lazy.nvim').mkdir(parents=True)
        result = self.run_install('NVIM_BIN=/bin/false; install_plugins')
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_uninstall_refuses_unmanaged_config(self):
        config = self.home / 'config/nvim'
        config.mkdir(parents=True)
        personal = config / 'personal.lua'
        personal.write_text('keep')
        result = subprocess.run(['bash', str(ROOT / 'uninstall.sh'), '--force'],
                                input='y\n', env=self.env, capture_output=True,
                                text=True, timeout=20)
        self.assertNotEqual(result.returncode, 0)
        self.assertTrue(personal.is_file())

    def test_failure_restores_original_config(self):
        config = self.home / 'config/nvim'
        config.mkdir(parents=True)
        (config / 'personal.lua').write_text('keep original')
        result = self.run_install('''check_os() { :; }
check_arch() { :; }
check_dependencies() { :; }
check_neovim() { NVIM_BIN=/bin/true; }
install_common_tools() { :; }
install_plugins() { return 1; }
main --force --skip-tools
''')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((config / 'personal.lua').read_text(), 'keep original')
        self.assertFalse((config / 'init.lua').exists())
        self.assertFalse(list(config.parent.glob('nvim.stage.*')))

    def test_failed_first_install_removes_new_config(self):
        result = self.run_install('''check_os() { :; }
check_arch() { :; }
check_dependencies() { :; }
check_neovim() { NVIM_BIN=/bin/true; }
install_common_tools() { :; }
install_plugins() { return 1; }
main --force --skip-tools
''')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / 'config/nvim').exists())

    def test_unattended_replacement_requires_force(self):
        config = self.home / 'config/nvim'
        config.mkdir(parents=True)
        (config / 'personal.lua').write_text('keep')
        result = self.run_install('install_config')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual((config / 'personal.lua').read_text(), 'keep')

    def test_uninstall_preserves_data_and_unmanaged_binary(self):
        config = self.home / 'config/nvim'
        config.mkdir(parents=True)
        (config / '.lazyvim-codespaces-managed').touch()
        data = self.home / 'data/nvim'
        data.mkdir(parents=True)
        (data / 'personal').write_text('keep')
        binary = self.home / '.local/bin/nvim'
        binary.parent.mkdir(parents=True)
        binary.write_text('unmanaged binary')
        result = subprocess.run(['bash', str(ROOT / 'uninstall.sh'), '--force'],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(config.exists())
        self.assertEqual((data / 'personal').read_text(), 'keep')
        self.assertEqual(binary.read_text(), 'unmanaged binary')

    def test_explicit_purge_removes_data_but_preserves_backup(self):
        for directory in ('config/nvim', 'data/nvim', 'state/nvim', 'cache/nvim',
                          'config/nvim.backup.saved'):
            (self.home / directory).mkdir(parents=True)
        (self.home / 'config/nvim/.lazyvim-codespaces-managed').touch()
        result = subprocess.run(['bash', str(ROOT / 'uninstall.sh'), '--force', '--purge'],
                                env=self.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        for directory in ('config/nvim', 'data/nvim', 'state/nvim', 'cache/nvim'):
            self.assertFalse((self.home / directory).exists())
        self.assertTrue((self.home / 'config/nvim.backup.saved').exists())

    def prepare_release(self, corrupt=False):
        archive = self.home / 'release.tar.gz'
        with tarfile.open(archive, 'w:gz') as tar:
            payload = b'#!/bin/sh\necho "NVIM v0.11.7"\n'
            info = tarfile.TarInfo('nvim-linux-x86_64/bin/nvim')
            info.size, info.mode = len(payload), 0o755
            tar.addfile(info, io.BytesIO(payload))
            runtime = b'official runtime'
            info = tarfile.TarInfo('nvim-linux-x86_64/share/nvim/runtime/test.vim')
            info.size = len(runtime)
            tar.addfile(info, io.BytesIO(runtime))
        digest = '0' * 64 if corrupt else hashlib.sha256(archive.read_bytes()).hexdigest()
        metadata = self.home / 'release.json'
        metadata.write_text(json.dumps({'assets': [{'name': 'nvim-linux-x86_64.tar.gz',
                                                    'digest': 'sha256:' + digest}]}))
        bindir = self.home / 'fake-network'
        bindir.mkdir()
        curl = bindir / 'curl'
        curl.write_text('''#!/bin/bash
set -eu
while (($#)); do
  case "$1" in
    https://api.github.com/*) src="$RELEASE_META" ;;
    https://github.com/*) src="$RELEASE_ARCHIVE" ;;
    -o) shift; dest="$1" ;;
  esac
  shift
done
cp -- "$src" "$dest"
''')
        curl.chmod(0o755)
        self.env.update(PATH=str(bindir) + ':/usr/bin:/bin', RELEASE_META=str(metadata),
                        RELEASE_ARCHIVE=str(archive))

    def test_download_preserves_runtime_and_reuses_managed_install(self):
        self.prepare_release()
        result = self.run_install('NVIM_ARCH=x86_64; install_neovim; install_neovim')
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        binary = self.home / '.local/bin/nvim'
        self.assertTrue(binary.is_symlink())
        runtime = binary.resolve().parent.parent / 'share/nvim/runtime/test.vim'
        self.assertEqual(runtime.read_text(), 'official runtime')

    def test_checksum_failure_does_not_install_binary(self):
        self.prepare_release(corrupt=True)
        result = self.run_install('NVIM_ARCH=x86_64; install_neovim')
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.home / '.local/bin/nvim').exists())


if __name__ == '__main__':
    unittest.main()
