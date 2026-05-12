"""Shared helpers for direct xAI HTTP integrations."""

from __future__ import annotations


def kopi_xai_user_agent() -> str:
    """Return a stable Kopi-specific User-Agent for xAI HTTP calls."""
    try:
        from kopi_cli import __version__
    except Exception:
        __version__ = "unknown"
    return f"Kopi-Agent/{__version__}"
