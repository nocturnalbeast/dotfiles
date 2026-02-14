#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "libtmux>=0.53.0",
#     "pyyaml",
#     "wcwidth",
# ]
# ///

"""
Dynamic tmux status bar generator with tinted-theming support.

Generates responsive status bar configurations that adapt to terminal width,
selecting appropriate gitmux layouts and truncating content as needed.
Integrates with tinty/tinted-theming for consistent color schemes.

Usage:
    genstatusbar.py [theme]  # Apply current or specified theme (e.g., base16-tokyo-night-dark)
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Dict, Tuple, Optional

import libtmux
import yaml

from utils import (
    ELLIPSIS,
    display_width,
    should_skip_debounce,
    strip_tmux_formatting,
    truncate_text,
    update_debounce_timestamp,
)


SCRIPT_DIR = Path(__file__).parent.resolve()
SSH_HELPER_PATH = SCRIPT_DIR / "ssh_helper.py"
GITMUX_CONF_PATH = Path.home() / ".config/tmux/gitmux.conf"
TINTED_TMUX_COLORS_DIR = Path.home() / ".local/share/tmux/plugins/tinted-tmux/colors"

_cache_dir = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
GITMUX_CACHE_PATH = _cache_dir / "tmux" / "gitmux-status.yml"
DEBOUNCE_FILE = _cache_dir / "tmux" / "genstatusbar-last-run"
THEME_CACHE_FILE = _cache_dir / "tmux" / "theme-colors.json"
DEBOUNCE_SECONDS = float(os.environ.get("TMUX_STATUS_DEBOUNCE", "2.0"))

SAFETY_MARGIN = int(os.environ.get("TMUX_STATUS_SAFETY_MARGIN", "2"))
STATUS_INTERVAL = int(os.environ.get("TMUX_STATUS_INTERVAL", "15"))
MAX_SESSION_NAME_WIDTH = 12
MAX_WINDOW_NAME_WIDTH = 20
MIN_CLIENT_WIDTH_FOR_SESSION = int(os.environ.get("TMUX_STATUS_MIN_WIDTH", "40"))

LAYOUTS = {
    "full": ["branch", "divergence", "flags", "stats"],
    "compact": ["branch", "divergence", "flags"],
    "minimal": ["branch", "flags"],
    "tiny": ["branch"],
}

STATUS_PADDING = 8
LAYOUT_BUFFER = int(os.environ.get("TMUX_STATUS_LAYOUT_BUFFER", "4"))
WINDOW_SEPARATOR_WIDTH = 3
SESSION_EMOJI = "\uebc8"


def _load_gitmux_base_config() -> dict:
    with open(GITMUX_CONF_PATH) as f:
        return yaml.safe_load(f)


def _apply_layout_options(config: dict, layout: list):
    config["tmux"]["layout"] = layout

    layout_key = tuple(layout)
    if layout_key == ("branch",):
        config["tmux"]["options"]["branch_max_len"] = 8
        config["tmux"]["options"]["hide_clean"] = True
    elif layout_key == ("branch", "flags"):
        config["tmux"]["options"]["branch_max_len"] = 12
        config["tmux"]["options"]["hide_clean"] = True
    elif layout_key == ("branch", "divergence", "flags"):
        config["tmux"]["options"]["branch_max_len"] = 15
        config["tmux"]["options"]["hide_clean"] = True
    else:
        config["tmux"]["options"]["branch_max_len"] = 0
        config["tmux"]["options"]["hide_clean"] = False


def write_gitmux_config(layout: list) -> Path:
    base_config = _load_gitmux_base_config()
    _apply_layout_options(base_config, layout)

    GITMUX_CACHE_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(GITMUX_CACHE_PATH, "w") as f:
        yaml.dump(base_config, f, default_flow_style=False)

    return GITMUX_CACHE_PATH


def get_gitmux_output(layout: list, cwd: str) -> Tuple[str, int]:
    config_path = write_gitmux_config(layout)

    try:
        result = subprocess.run(
            ["gitmux", "-cfg", str(config_path), cwd],
            capture_output=True,
            text=True,
            timeout=2,
        )
        if result.returncode != 0:
            return "", 0

        raw_output = result.stdout.strip()
        visible_output = strip_tmux_formatting(raw_output)
        width = display_width(visible_output)

        return raw_output, width
    except subprocess.TimeoutExpired:
        return "", 0
    except OSError:
        return "", 0


def get_theme(theme_arg=None) -> Tuple[str, str, str]:
    if theme_arg:
        full_theme = theme_arg
    else:
        result = subprocess.run(
            ["tinty", "current", "name"], capture_output=True, text=True, timeout=5
        )
        if result.returncode != 0:
            sys.stderr.write("Error: Could not get theme from tinty\n")
            sys.exit(1)
        theme_name = result.stdout.strip().lower()

        result = subprocess.run(
            ["tinty", "current", "system"], capture_output=True, text=True, timeout=5
        )
        if result.returncode != 0:
            sys.stderr.write("Error: Could not get theme system from tinty\n")
            sys.exit(1)
        theme_system = result.stdout.strip()
        full_theme = f"{theme_system}-{theme_name}"

    if full_theme.startswith("base16-"):
        system = "base16"
        theme_name = full_theme[7:]
    elif full_theme.startswith("base24-"):
        system = "base24"
        theme_name = full_theme[7:]
    else:
        sys.stderr.write(f"Error: Unknown theme system: {full_theme}\n")
        sys.exit(1)

    return full_theme, system, theme_name


def get_left_width(server=None, truncated_session_name: Optional[str] = None) -> int:
    if truncated_session_name:
        session_name = truncated_session_name
    elif server:
        session = server.sessions[0]
        session_name = session.name
    else:
        return MAX_SESSION_NAME_WIDTH + 5

    content = f" {SESSION_EMOJI}  {session_name} "
    return display_width(content)


def get_center_width(server) -> int:
    session = server.sessions[0]
    windows = session.windows

    if not windows:
        return 0

    total_width = 0

    for i, window in enumerate(windows):
        if not window.panes:
            continue

        pane = window.panes[0]

        try:
            result = subprocess.run(
                [
                    str(SSH_HELPER_PATH),
                    str(pane.pid),
                    str(window.index),
                    window.name,
                    str(MAX_WINDOW_NAME_WIDTH),
                ],
                capture_output=True,
                text=True,
                timeout=2,
            )
            if result.returncode != 0:
                window_content = f" {window.index}:{window.name} "
                window_width = display_width(window_content)
            else:
                raw_output = result.stdout.strip()
                visible_output = strip_tmux_formatting(raw_output)
                window_width = display_width(visible_output)
        except subprocess.TimeoutExpired:
            window_content = f" {window.index}:{window.name} "
            window_width = display_width(window_content)
        except OSError:
            window_content = f" {window.index}:{window.name} "
            window_width = display_width(window_content)

        total_width += window_width

        if i < len(windows) - 1:
            total_width += WINDOW_SEPARATOR_WIDTH

    return total_width


def get_time_width() -> int:
    return display_width(" %H:%M ")


def get_separator_width() -> int:
    return display_width(" :: ")


def select_gitmux_layout(
    available_width: int, cwd: str
) -> Tuple[Optional[list], str, int]:
    layouts_ordered = ["full", "compact", "minimal", "tiny"]

    for layout_name in layouts_ordered:
        layout = LAYOUTS[layout_name]
        raw_output, output_width = get_gitmux_output(layout, cwd)

        total_width = (
            output_width + get_separator_width() + get_time_width() + LAYOUT_BUFFER
        )

        if total_width <= available_width:
            return layout, raw_output, total_width - LAYOUT_BUFFER

    return None, "", get_time_width()


def _load_cached_colors(theme_name: str) -> Optional[Dict[str, str]]:
    try:
        if THEME_CACHE_FILE.exists():
            cache_data = json.loads(THEME_CACHE_FILE.read_text())
            if cache_data.get("theme") == theme_name:
                return cache_data.get("colors")
    except (json.JSONDecodeError, OSError, KeyError):
        pass
    return None


def _save_cached_colors(theme_name: str, colors: Dict[str, str]):
    try:
        THEME_CACHE_FILE.parent.mkdir(parents=True, exist_ok=True)
        THEME_CACHE_FILE.write_text(json.dumps({"theme": theme_name, "colors": colors}))
    except OSError:
        pass


def get_color_mapping(theme_name: str, system: str) -> Dict[str, str]:
    cached = _load_cached_colors(theme_name)
    if cached:
        return cached

    data_dir = os.environ.get(
        "TINTY_DATA_DIR", str(Path.home() / ".local/share/tinted-theming/tinty")
    )

    theme_filename = theme_name.lower().replace(" ", "-").replace(",", "")
    theme_filename = "".join(c for c in theme_filename if c.isalnum() or c == "-")

    yaml_path = Path(data_dir) / "repos" / "schemes" / system / f"{theme_filename}.yaml"

    if not yaml_path.exists():
        yaml_path = Path(data_dir) / "repos" / "schemes" / system / f"{theme_name}.yaml"

    if not yaml_path.exists():
        sys.stderr.write(f"Error: Theme file not found: {yaml_path}\n")
        sys.exit(1)

    with open(yaml_path) as f:
        theme_data = yaml.safe_load(f)

    if system == "base16":
        keys = {
            "bg": "base01",
            "fg": "base04",
            "fg_current": "base0A",
            "fg_session": "base04",
            "fg_prefix": "base0D",
            "fg_bright": "base06",
        }
    else:
        keys = {
            "bg": "base01",
            "fg": "base04",
            "fg_current": "base13",
            "fg_session": "base04",
            "fg_prefix": "base0D",
            "fg_bright": "base06",
        }

    colors = {}
    palette = theme_data.get("palette", {})
    for name, key in keys.items():
        if key in palette:
            colors[name] = palette[key].lstrip("#")
        else:
            sys.stderr.write(f"Error: Color key '{key}' not found in theme\n")
            sys.exit(1)

    _save_cached_colors(theme_name, colors)
    return colors


def set_global_option(server, option: str, value):
    server.set_option(option, value, global_=True)


def build_status_left(
    colors: Dict[str, str],
    show_session_name: bool = True,
    truncated_session_name: Optional[str] = None,
) -> Tuple[str, int]:
    bg_color = colors["bg"]
    fg_session = colors["fg_session"]
    fg_prefix = colors["fg_prefix"]

    if show_session_name:
        session_placeholder = truncated_session_name or "#S"
        status_left = (
            f"#[bg=#{bg_color},fg=#{fg_session}]"
            f"#{{?client_prefix,, {SESSION_EMOJI}  {session_placeholder} }}"
            f"#[bg=#{bg_color},fg=#{fg_session}]"
            f"#[bg=#{fg_prefix},fg=#{bg_color},bold]"
            f"#{{?client_prefix, {SESSION_EMOJI}  {session_placeholder} }}"
            f"#[bg=#{bg_color},fg=#{fg_session}]"
        )
        if truncated_session_name:
            width = get_left_width(None, truncated_session_name)
        else:
            width = MAX_SESSION_NAME_WIDTH + 5
    else:
        status_left = (
            f"#[bg=#{bg_color},fg=#{fg_session}]"
            f"#{{?client_prefix,, {SESSION_EMOJI}  }}"
            f"#[bg=#{fg_prefix},fg=#{bg_color},bold]"
            f"#{{?client_prefix, {SESSION_EMOJI}  }}"
            f"#[bg=#{bg_color},fg=#{fg_session}]"
        )
        width = display_width(f" {SESSION_EMOJI}  ")

    return status_left, width


def build_status_right_with_gitmux(colors: Dict[str, str], gitmux_config: str) -> str:
    return (
        "#(OUTPUT=$(gitmux -cfg "
        + gitmux_config
        + ' "#{pane_current_path}" 2>/dev/null); '
        '[ -n "$OUTPUT" ] && echo "#[bg=#'
        + colors["bg"]
        + ",fg=#"
        + colors["fg_bright"]
        + "] $OUTPUT "
        "#[bg=#"
        + colors["bg"]
        + ",fg=#"
        + colors["fg_session"]
        + "]:: #[fg=#"
        + colors["fg_session"]
        + ']%H:%M" '
        '|| echo "#[bg=#' + colors["bg"] + ",fg=#" + colors["fg_session"] + '] %H:%M")'
    )


def build_status_right_time_only(colors: Dict[str, str]) -> str:
    return f"#[bg=#{colors['bg']},fg=#{colors['fg_session']}] %H:%M"


def build_window_format(colors: Dict[str, str]) -> Tuple[str, str]:
    bg_color = colors["bg"]

    normal_format = f"#({SSH_HELPER_PATH} #{{pane_pid}} #{{window_index}} #{{window_name}} {MAX_WINDOW_NAME_WIDTH} | xargs)"

    current_format = (
        f"#[bg=#{bg_color}]"
        f"#{{?window_zoomed_flag, ,}}"
        f"#[fg=#{colors['fg_current']}]"
        f"#({SSH_HELPER_PATH} #{{pane_pid}} #{{window_index}} #{{window_name}} {MAX_WINDOW_NAME_WIDTH} | xargs)"
    )

    return normal_format, current_format


def set_window_options(server, colors: Dict[str, str]):
    bg_color = colors["bg"]
    normal_format, current_format = build_window_format(colors)

    set_global_option(server, "window-status-separator", " • ")
    set_global_option(
        server,
        "window-status-current-style",
        f"fg=#{colors['fg_current']},bg=#{bg_color}",
    )
    set_global_option(server, "window-status-format", normal_format)
    set_global_option(server, "window-status-current-format", current_format)
    set_global_option(
        server,
        "window-status-current-style",
        f"fg=#{colors['fg_current']},bg=#{bg_color}",
    )
    set_global_option(
        server,
        "window-status-bell-style",
        f"bg=#{colors['fg_prefix']},fg=#{colors['bg']},bold",
    )
    set_global_option(
        server,
        "window-status-activity-style",
        f"bg=#{colors['fg_current']},fg=#{colors['bg']}",
    )


def get_current_pane_cwd(server) -> str:
    try:
        result = server.cmd("display-message", "-p", "#{pane_current_path}").stdout
        if isinstance(result, list):
            return result[0] if result else str(Path.home())
        return result.strip() if result else str(Path.home())
    except (AttributeError, Exception):
        return str(Path.home())


def apply_status_options(server, colors: Dict[str, str]):
    set_global_option(server, "status-position", "bottom")
    set_global_option(server, "status-justify", "absolute-centre")
    set_global_option(server, "status-interval", STATUS_INTERVAL)
    set_global_option(server, "status-style", f"bg=#{colors['bg']},fg=#{colors['fg']}")

    session = server.sessions[0]
    session_name = session.name
    truncated_session = truncate_text(session_name, MAX_SESSION_NAME_WIDTH)

    center_width = get_center_width(server)

    client_width_result = server.cmd("display-message", "-p", "#{client_width}").stdout
    if isinstance(client_width_result, list):
        client_width = int(client_width_result[0]) if client_width_result else 80
    else:
        client_width = int(client_width_result.strip())

    time_only_width = get_time_width()

    full_left_width = get_left_width(None, truncated_session)
    emoji_only_width = display_width(f" {SESSION_EMOJI} ")

    available_with_full_left = (
        client_width
        - full_left_width
        - center_width
        - time_only_width
        - STATUS_PADDING
        - SAFETY_MARGIN
    )

    show_session_name = (
        client_width >= MIN_CLIENT_WIDTH_FOR_SESSION and available_with_full_left >= 0
    )

    status_left, left_width = build_status_left(
        colors,
        show_session_name=show_session_name,
        truncated_session_name=truncated_session,
    )
    set_global_option(server, "status-left", status_left)
    set_global_option(server, "status-left-length", left_width + SAFETY_MARGIN)

    cwd = get_current_pane_cwd(server)

    actual_left_width = left_width if show_session_name else emoji_only_width

    available_for_gitmux = (
        client_width
        - actual_left_width
        - center_width
        - time_only_width
        - STATUS_PADDING
        - SAFETY_MARGIN
    )

    layout, gitmux_raw_output, right_width = select_gitmux_layout(
        available_for_gitmux, cwd
    )

    if layout:
        gitmux_config = write_gitmux_config(layout)
        status_right = build_status_right_with_gitmux(colors, str(gitmux_config))
    else:
        status_right = build_status_right_time_only(colors)
        right_width = time_only_width

    set_global_option(server, "status-right", status_right)
    set_global_option(server, "status-right-length", right_width + SAFETY_MARGIN)

    set_window_options(server, colors)


def source_theme_file(server, theme: str):
    theme_file = TINTED_TMUX_COLORS_DIR / f"{theme}.conf"
    if theme_file.exists():
        server.cmd("source-file", str(theme_file))


def apply_theme(theme_arg=None):
    try:
        server = libtmux.Server()
        if not server.is_alive():
            sys.exit(0)
    except Exception as e:
        sys.stderr.write(f"Error: Could not connect to tmux server: {e}\n")
        sys.exit(1)

    full_theme, system, theme_name = get_theme(theme_arg)
    colors = get_color_mapping(theme_name, system)
    source_theme_file(server, full_theme)
    apply_status_options(server, colors)
    server.set_option("@tinted-color", full_theme)
    server.cmd("refresh-client", "-S")


def main():
    if should_skip_debounce(DEBOUNCE_FILE, DEBOUNCE_SECONDS):
        sys.exit(0)

    parser = argparse.ArgumentParser(
        description="Generate and apply tmux status bar theme using libtmux"
    )
    parser.add_argument(
        "theme", nargs="?", help="Theme name (e.g., base16-tokyo-night-dark)"
    )
    args = parser.parse_args()

    try:
        apply_theme(args.theme)
        update_debounce_timestamp(DEBOUNCE_FILE)
    except KeyboardInterrupt:
        sys.exit(1)
    except subprocess.TimeoutExpired as e:
        sys.stderr.write(f"Timeout: {e}\n")
        sys.exit(1)
    except OSError as e:
        sys.stderr.write(f"I/O Error: {e}\n")
        sys.exit(1)


if __name__ == "__main__":
    main()
