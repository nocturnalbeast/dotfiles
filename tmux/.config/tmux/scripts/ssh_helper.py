#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "psutil>=5.9.0",
#     "wcwidth",
# ]
# ///
"""
SSH hostname detection for tmux window status.

Detects active SSH connections in a pane's process tree and displays
the remote hostname instead of the window name. Falls back to window
name with truncation when no SSH session is detected.

Usage:
    ssh_helper.py <pid> <window_index> <window_name> [max_width]
"""

import sys

import psutil

from utils import SSH_FLAG_PATTERN, SSH_OPTION_PATTERN, display_width, truncate_text


def get_ssh_hostname_psutil(
    pid: int, window_index: str, window_name: str, max_width: int = 0
) -> str:
    try:
        process = psutil.Process(pid)
        for child in process.children(recursive=True):
            if "ssh" in child.name():
                cmdline = " ".join(child.cmdline())
                hostname = _parse_ssh_hostname(cmdline)
                if hostname:
                    result = f"  {hostname}"
                    if max_width > 0 and display_width(result) > max_width:
                        hostname_truncated = truncate_text(hostname, max_width - 4)
                        result = f"  {hostname_truncated}"
                    return result
    except (psutil.NoSuchProcess, psutil.AccessDenied, OSError):
        pass

    result = f"{window_index}: {window_name}"
    if max_width > 0 and display_width(result) > max_width:
        prefix = f"{window_index}: "
        prefix_width = display_width(prefix)
        available_for_name = max_width - prefix_width
        if available_for_name > 0:
            truncated_name = truncate_text(window_name, available_for_name)
            result = f"{prefix}{truncated_name}"
        else:
            result = truncate_text(result, max_width)
    return result


def _parse_ssh_hostname(cmdline: str):
    args = cmdline.split()
    skip_next = False
    for arg in args[1:]:
        if skip_next:
            skip_next = False
            continue
        if arg.startswith("-"):
            if SSH_FLAG_PATTERN.match(arg):
                continue
            if SSH_OPTION_PATTERN.match(arg):
                skip_next = True
                continue
        if not arg.startswith("-"):
            return arg
    return None


def main():
    if len(sys.argv) < 4:
        sys.stderr.write(
            "Usage: ssh_helper.py <pid> <window_index> <window_name> [max_width]\n"
        )
        sys.exit(1)

    pid = int(sys.argv[1])
    window_index = sys.argv[2]
    window_name = (
        " ".join(sys.argv[3:-1]) if len(sys.argv) > 4 else " ".join(sys.argv[3:])
    )
    max_width = int(sys.argv[-1]) if len(sys.argv) > 4 and sys.argv[-1].isdigit() else 0

    result = get_ssh_hostname_psutil(pid, window_index, window_name, max_width)
    print(result)


if __name__ == "__main__":
    main()
