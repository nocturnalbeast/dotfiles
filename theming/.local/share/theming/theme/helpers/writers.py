"""Writer contract primitives: text in → text out, callers persist.

Foreign content survives byte-for-byte; inserts append to the owned
region, replaces preserve separator/quote formatting.
"""

from __future__ import annotations

import re
from pathlib import Path
from typing import Mapping, Union

MANAGED_MARKER = "# theme:managed"


def _split_keepends(text: str) -> list[str]:
    return text.splitlines(keepends=True)


def _ensure_nl(lines: list[str]) -> None:
    if lines and not lines[-1].endswith("\n"):
        lines[-1] += "\n"


def update_space_kv(text: str, updates: Mapping[str, Union[str, int]]) -> str:
    """xsettingsd-style `Key value` lines. Strings quoted, ints bare."""
    lines = _split_keepends(text)
    seen: set[str] = set()
    out: list[str] = []
    for line in lines:
        m = re.match(r"^([A-Za-z][A-Za-z0-9/]*)\s+(.*)$", line.rstrip("\n"))
        if m and m.group(1) in updates:
            key = m.group(1)
            val = updates[key]
            rendered = f"{key} {val}" if isinstance(val, int) else f'{key} "{val}"'
            out.append(line.replace(line.rstrip("\n"), rendered))
            seen.add(key)
        else:
            out.append(line)
    _ensure_nl(out)
    for key, val in updates.items():
        if key not in seen:
            rendered = f"{key} {val}" if isinstance(val, int) else f'{key} "{val}"'
            out.append(rendered + "\n")
    return "".join(out)


def update_eq_kv(
    text: str,
    updates: dict[str, str],
    section: str | None = None,
    quote: bool = False,
) -> str:
    """`key=value` lines (settings.ini sections, gtkrc body).

    Replaces preserve the original separator spacing; values bare (ini)
    or quoted (gtkrc). Missing keys append at the end of the owned
    section (creating it if absent); with section=None, at EOF.
    """
    lines = _split_keepends(text)
    seen: set[str] = set()
    out: list[str] = []
    in_target = section is None
    insert_at: int | None = None

    def render_value(val: str) -> str:
        return f'"{val}"' if quote else val

    def render_line(key: str, val: str) -> str:
        return f'{key}="{val}"' if quote else f"{key}={val}"

    for line in lines:
        stripped = line.strip()
        if section is not None and stripped.startswith("[") and stripped.endswith("]"):
            if in_target:
                insert_at = len(out)
            in_target = stripped == f"[{section}]"
            if in_target:
                insert_at = None
            out.append(line)
            continue
        if in_target:
            m = re.match(
                r"^(\s*)([A-Za-z][A-Za-z0-9_-]*)(\s*=\s*)(.*)$", line.rstrip("\n")
            )
            if m and m.group(2) in updates:
                key = m.group(2)
                newline = f"{m.group(1)}{key}{m.group(3)}{render_value(updates[key])}"
                out.append(newline + "\n" if line.endswith("\n") else newline)
                seen.add(key)
                continue
        out.append(line)
        if in_target:
            insert_at = len(out)

    _ensure_nl(out)
    missing = [render_line(k, v) + "\n" for k, v in updates.items() if k not in seen]
    if not missing:
        return "".join(out)

    if section is None:
        out.extend(missing)
    elif insert_at is not None:
        out[insert_at:insert_at] = missing
    else:
        out.append(f"[{section}]\n")
        out.extend(missing)
    return "".join(out)


def managed_line_set(text: str, var: str, value: str | None) -> tuple[str, bool]:
    """Set one managed env export. value=None ⇒ commented form.

    Returns (new_text, neutralized_unmanaged). An existing UNMANAGED
    active export of `var` is neutralized (commented) so the managed
    line is the only authority; the caller reports the neutralization.
    An existing managed line is updated IN PLACE - position, indent and
    file layout are preserved across applies (the export moves only if
    the file never had a managed line, in which case it is appended).
    """
    active = re.compile(rf"^(\s*)export\s+{re.escape(var)}=(.*)$")
    managed = re.compile(
        rf"^(\s*)(#\s*)?export\s+{re.escape(var)}=.*{re.escape(MANAGED_MARKER)}\s*$"
    )
    neutralized = False
    rendered = (
        f"export {var}={value} {MANAGED_MARKER}"
        if value is not None
        else f"# export {var}= {MANAGED_MARKER}"
    )
    out: list[str] = []
    replaced = False
    for line in _split_keepends(text):
        body = line.rstrip("\n")
        m = managed.match(body)
        if m:
            if not replaced:
                out.append(f"{m.group(1)}{rendered}\n")
                replaced = True
            continue  # surplus managed duplicates are dropped
        if active.match(body) and MANAGED_MARKER not in body:
            out.append(line.replace(body, f"# {body}"))
            neutralized = True
            continue
        out.append(line)
    _ensure_nl(out)
    if not replaced:
        out.append(f"{rendered}\n")
    return "".join(out), neutralized


# value = quoted string OR bare token; a trailing comment requires
# leading whitespace so '#' inside quoted hex values stays part of
# the value
_SET_LINE = re.compile(r'^(\s*)(set)\s+([A-Za-z0-9_-]+)(\s+)("[^"]*"|\S+)(\s+#.*)?$')


def update_set_kv(text: str, values: dict[str, str]) -> tuple[str, list[str]]:
    """Rewrite `set <key> <value>` lines in place: whitespace
    between key and value is preserved byte-for-byte. Keys absent from
    the file are appended after the last set-line; returns
    (new_text, appended_keys)."""
    out: list[str] = []
    remaining = dict(values)
    last_set = -1
    for line in text.splitlines():
        m = _SET_LINE.match(line)
        if m:
            if m.group(3) in remaining:
                key = m.group(3)
                out.append(
                    f"{m.group(1)}{m.group(2)} {key}{m.group(4)}"
                    f"{remaining[key]}{m.group(6) or ''}"
                )
                del remaining[key]
            else:
                out.append(line)
            last_set = len(out) - 1
        else:
            out.append(line)
    for key, value in remaining.items():
        out.insert(last_set + 1, f"set {key} {value}")
    joined = "\n".join(out)
    if text.endswith("\n"):
        joined += "\n"
    return joined, list(remaining)


def update_prefixed_lines(text: str, templates: dict[str, str]) -> str:
    """Replace whole lines matching `^\\s*PREFIX` with the given template.

    For xresources (`*.color0:`), hypr (`col.active_border =`), bspwm
    (`bspc config x_color`), QML property lines. Missing prefixes
    append at EOF.
    """
    lines = _split_keepends(text)
    seen: set[str] = set()
    out: list[str] = []
    for line in lines:
        body = line.rstrip("\n")
        for prefix, template in templates.items():
            if re.match(rf"^\s*{re.escape(prefix)}", body):
                newline = line.replace(body, template)
                out.append(newline if newline.endswith("\n") else newline + "\n")
                seen.add(prefix)
                break
        else:
            out.append(line)
    _ensure_nl(out)
    for prefix, template in templates.items():
        if prefix not in seen:
            out.append(template + "\n")
    return "".join(out)


def update_marker_block(text: str, begin: str, end: str, body: str) -> str:
    """Replace the marked region [begin, end] with body.

    The region is created (before `end` anchor / at EOF) when absent -
    the fontconfig bootstrap path.
    """
    pattern = re.compile(re.escape(begin) + r".*?" + re.escape(end), re.DOTALL)
    block = f"{begin}\n{body.rstrip()}\n{end}"
    if pattern.search(text):
        return pattern.sub(lambda _: block, text, count=1)
    return text.rstrip("\n") + "\n" + block + "\n"


def read_surface(path: Path) -> str:
    return path.read_text() if path.exists() else ""


def write_report(path: Path, updates: dict[str, str]) -> dict[str, str]:
    """Convenience for status: owned keys actually present in a file.

    Handles key=value, key: value (xresources), and Key value
    (xsettingsd space-separated) formats.
    """
    found: dict[str, str] = {}
    if not path.exists():
        return found
    for line in path.read_text().splitlines():
        stripped = line.strip()
        m_eq = re.match(r"^([A-Za-z*][A-Za-z0-9_.\-/]*)\s*[=:]\s*(.*)$", stripped)
        m_space = re.match(r"^([A-Za-z][A-Za-z0-9/]*)\s+(.+)$", stripped)
        for m in (m_eq, m_space):
            if m and m.group(1) in updates:
                found[m.group(1)] = m.group(2).strip().strip('"')
    return found


def update_colon_kv(text: str, updates: Mapping[str, str]) -> str:
    """X-style `*.key:  value` lines - formatting-preserving.

    Replaces ONLY the value in existing lines, preserving the exact
    whitespace alignment after the colon (column look survives).
    Interleaved comments and foreign lines untouched byte-for-byte.
    Missing keys are appended at the end (with simple 3-space
    alignment - they had no prior formatting to preserve)."""
    lines = _split_keepends(text)
    seen: set[str] = set()
    out: list[str] = []
    for line in lines:
        m = re.match(r"^(\S+:)(\s+)(\S+.*?)\s*$", line.rstrip("\n"))
        if m and m.group(1)[:-1] in updates:
            key = m.group(1)[:-1]
            # preserve exact leading whitespace before the old value
            out.append(f"{m.group(1)}{m.group(2)}{updates[key]}\n")
            seen.add(key)
        else:
            out.append(line)
    _ensure_nl(out)
    for key, val in updates.items():
        if key not in seen:
            out.append(f"{key}:   {val}\n")
    return "".join(out)
