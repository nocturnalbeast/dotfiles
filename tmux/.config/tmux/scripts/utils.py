"""
Shared utilities for tmux status bar scripts.

Provides common text handling, tmux formatting, and debounce functionality
used by genstatusbar.py and ssh_helper.py.
"""

import re
import time
from pathlib import Path

import wcwidth

ELLIPSIS = "…"
TMUX_FORMAT_PATTERN = re.compile(r"#\[[^\]]*\]")

SSH_FLAG_PATTERN = re.compile(r"^-[1246AaCfGgKkMNnqsTtVvXxYy]+$")
SSH_OPTION_PATTERN = re.compile(r"^-(B|b|c|D|E|e|F|I|i|J|L|l|m|O|o|p|Q|R|S|W|w)$")


def should_skip_debounce(debounce_file: Path, debounce_seconds: float) -> bool:
    try:
        if debounce_file.exists():
            last_run = float(debounce_file.read_text().strip())
            elapsed = time.time() - last_run
            if elapsed < debounce_seconds:
                return True
    except (ValueError, OSError):
        pass
    return False


def update_debounce_timestamp(debounce_file: Path):
    try:
        debounce_file.parent.mkdir(parents=True, exist_ok=True)
        debounce_file.write_text(str(time.time()))
    except OSError:
        pass


def display_width(text: str) -> int:
    return wcwidth.wcswidth(text)


def strip_tmux_formatting(text: str) -> str:
    return TMUX_FORMAT_PATTERN.sub("", text)


def truncate_text(text: str, max_width: int) -> str:
    if display_width(text) <= max_width:
        return text

    ellipsis_width = display_width(ELLIPSIS)
    available = max_width - ellipsis_width

    if available <= 0:
        return ELLIPSIS[:max_width] if max_width > 0 else ""

    truncated = ""
    current_width = 0

    for char in text:
        char_width = wcwidth.wcwidth(char)
        if char_width < 0:
            char_width = 0
        if current_width + char_width > available:
            break
        truncated += char
        current_width += char_width

    return truncated + ELLIPSIS
