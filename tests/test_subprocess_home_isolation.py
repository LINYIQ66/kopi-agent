"""Tests for per-profile subprocess HOME isolation (#4426).

Verifies that subprocesses (terminal, execute_code, background processes)
receive a per-profile HOME directory while the Python process's own HOME
and Path.home() remain unchanged.

See: https://github.com/XingBaoKu/kopi-agent/issues/4426
"""

import os
from pathlib import Path
from unittest.mock import patch

import pytest


# ---------------------------------------------------------------------------
# get_subprocess_home()
# ---------------------------------------------------------------------------

class TestGetSubprocessHome:
    """Unit tests for kopi_constants.get_subprocess_home()."""

    def test_returns_none_when_kopi_home_unset(self, monkeypatch):
        monkeypatch.delenv("KOPI_HOME", raising=False)
        from kopi_constants import get_subprocess_home
        assert get_subprocess_home() is None

    def test_returns_none_when_home_dir_missing(self, tmp_path, monkeypatch):
        kopi_home = tmp_path / ".kopi"
        kopi_home.mkdir()
        monkeypatch.setenv("KOPI_HOME", str(kopi_home))
        # No home/ subdirectory created
        from kopi_constants import get_subprocess_home
        assert get_subprocess_home() is None

    def test_returns_path_when_home_dir_exists(self, tmp_path, monkeypatch):
        kopi_home = tmp_path / ".kopi"
        kopi_home.mkdir()
        profile_home = kopi_home / "home"
        profile_home.mkdir()
        monkeypatch.setenv("KOPI_HOME", str(kopi_home))
        from kopi_constants import get_subprocess_home
        assert get_subprocess_home() == str(profile_home)

    def test_returns_profile_specific_path(self, tmp_path, monkeypatch):
        """Named profiles get their own isolated HOME."""
        profile_dir = tmp_path / ".kopi" / "profiles" / "coder"
        profile_dir.mkdir(parents=True)
        profile_home = profile_dir / "home"
        profile_home.mkdir()
        monkeypatch.setenv("KOPI_HOME", str(profile_dir))
        from kopi_constants import get_subprocess_home
        assert get_subprocess_home() == str(profile_home)

    def test_two_profiles_get_different_homes(self, tmp_path, monkeypatch):
        base = tmp_path / ".kopi" / "profiles"
        for name in ("alpha", "beta"):
            p = base / name
            p.mkdir(parents=True)
            (p / "home").mkdir()

        from kopi_constants import get_subprocess_home

        monkeypatch.setenv("KOPI_HOME", str(base / "alpha"))
        home_a = get_subprocess_home()

        monkeypatch.setenv("KOPI_HOME", str(base / "beta"))
        home_b = get_subprocess_home()

        assert home_a != home_b
        assert home_a.endswith("alpha/home")
        assert home_b.endswith("beta/home")


# ---------------------------------------------------------------------------
# _make_run_env() injection
# ---------------------------------------------------------------------------

class TestMakeRunEnvHomeInjection:
    """Verify _make_run_env() injects HOME into subprocess envs."""

    def test_injects_home_when_profile_home_exists(self, tmp_path, monkeypatch):
        kopi_home = tmp_path / "kopi"
        kopi_home.mkdir()
        (kopi_home / "home").mkdir()
        monkeypatch.setenv("KOPI_HOME", str(kopi_home))
        monkeypatch.setenv("HOME", "/root")
        monkeypatch.setenv("PATH", "/usr/bin:/bin")

        from tools.environments.local import _make_run_env
        result = _make_run_env({})

        assert result["HOME"] == str(kopi_home / "home")

    def test_no_injection_when_home_dir_missing(self, tmp_path, monkeypatch):
        kopi_home = tmp_path / "kopi"
        kopi_home.mkdir()
        # No home/ subdirectory
        monkeypatch.setenv("KOPI_HOME", str(kopi_home))
        monkeypatch.setenv("HOME", "/root")
        monkeypatch.setenv("PATH", "/usr/bin:/bin")

        from tools.environments.local import _make_run_env
        result = _make_run_env({})

        assert result["HOME"] == "/root"

    def test_no_injection_when_kopi_home_unset(self, monkeypatch):
        monkeypatch.delenv("KOPI_HOME", raising=False)
        monkeypatch.setenv("HOME", "/home/user")
        monkeypatch.setenv("PATH", "/usr/bin:/bin")

        from tools.environments.local import _make_run_env
        result = _make_run_env({})

        assert result["HOME"] == "/home/user"


# ---------------------------------------------------------------------------
# _sanitize_subprocess_env() injection
# ---------------------------------------------------------------------------

class TestSanitizeSubprocessEnvHomeInjection:
    """Verify _sanitize_subprocess_env() injects HOME for background procs."""

    def test_injects_home_when_profile_home_exists(self, tmp_path, monkeypatch):
        kopi_home = tmp_path / "kopi"
        kopi_home.mkdir()
        (kopi_home / "home").mkdir()
        monkeypatch.setenv("KOPI_HOME", str(kopi_home))

        base_env = {"HOME": "/root", "PATH": "/usr/bin", "USER": "root"}
        from tools.environments.local import _sanitize_subprocess_env
        result = _sanitize_subprocess_env(base_env)

        assert result["HOME"] == str(kopi_home / "home")

    def test_no_injection_when_home_dir_missing(self, tmp_path, monkeypatch):
        kopi_home = tmp_path / "kopi"
        kopi_home.mkdir()
        monkeypatch.setenv("KOPI_HOME", str(kopi_home))

        base_env = {"HOME": "/root", "PATH": "/usr/bin"}
        from tools.environments.local import _sanitize_subprocess_env
        result = _sanitize_subprocess_env(base_env)

        assert result["HOME"] == "/root"


# ---------------------------------------------------------------------------
# Profile bootstrap
# ---------------------------------------------------------------------------

class TestProfileBootstrap:
    """Verify new profiles get a home/ subdirectory."""

    def test_profile_dirs_includes_home(self):
        from kopi_cli.profiles import _PROFILE_DIRS
        assert "home" in _PROFILE_DIRS

    def test_create_profile_bootstraps_home_dir(self, tmp_path, monkeypatch):
        """create_profile() should create home/ inside the profile dir."""
        home = tmp_path / ".kopi"
        home.mkdir()
        monkeypatch.setattr(Path, "home", lambda: tmp_path)
        monkeypatch.setenv("KOPI_HOME", str(home))

        from kopi_cli.profiles import create_profile
        profile_dir = create_profile("testbot", no_alias=True)
        assert (profile_dir / "home").is_dir()


# ---------------------------------------------------------------------------
# Python process HOME unchanged
# ---------------------------------------------------------------------------

class TestPythonProcessUnchanged:
    """Confirm the Python process's own HOME is never modified."""

    def test_path_home_unchanged_after_subprocess_home_resolved(
        self, tmp_path, monkeypatch
    ):
        kopi_home = tmp_path / "kopi"
        kopi_home.mkdir()
        (kopi_home / "home").mkdir()
        monkeypatch.setenv("KOPI_HOME", str(kopi_home))

        original_home = os.environ.get("HOME")
        original_path_home = str(Path.home())

        from kopi_constants import get_subprocess_home
        sub_home = get_subprocess_home()

        # Subprocess home is set but Python HOME stays the same
        assert sub_home is not None
        assert os.environ.get("HOME") == original_home
        assert str(Path.home()) == original_path_home
