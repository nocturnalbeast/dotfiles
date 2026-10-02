#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Analyze WCAG contrast ratios in base24 tinty schemes: analyze_contrast.py <scheme.yaml> [--verbose] | --all."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

SCHEME_DIR = Path.home() / ".local/share/tinted-theming/tinty/custom-schemes/base24"

SLOT_ROLES = {
    "base00": "bg",
    "base01": "bg_alt",
    "base02": "bg_selected",
    "base03": "comment",
    "base04": "dim_fg",
    "base05": "fg",
    "base06": "fg_bright",
    "base07": "fg_boldest",
    "base08": "red",
    "base09": "orange",
    "base0A": "yellow",
    "base0B": "green",
    "base0C": "cyan",
    "base0D": "blue",
    "base0E": "magenta",
    "base0F": "bright_magenta",
}

# WCAG: AA ≥4.5:1 normal / ≥3:1 large; AAA ≥7:1 / ≥4.5:1.
# Terminal readability is checked as fg-vs-bg.
AA_NORMAL = 4.5
AAA_NORMAL = 7.0
AA_LARGE = 3.0


def parse_hex(h: str) -> tuple[int, int, int]:
    h = h.lstrip("#")
    return int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)


def relative_luminance(hex_color: str) -> float:
    r, g, b = parse_hex(hex_color)
    lin = lambda c: (
        c / 255.0 / 12.92
        if c / 255.0 <= 0.04045
        else ((c / 255.0 + 0.055) / 1.055) ** 2.4
    )
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def contrast_ratio(hex1: str, hex2: str) -> float:
    l1 = relative_luminance(hex1)
    l2 = relative_luminance(hex2)
    lighter = max(l1, l2)
    darker = min(l1, l2)
    return (lighter + 0.05) / (darker + 0.05)


def load_scheme(path: Path) -> dict[str, str]:
    slots = {}
    for line in path.read_text().splitlines():
        if line.strip().startswith("base"):
            parts = line.split(":", 1)
            if len(parts) == 2:
                slot = parts[0].strip()
                value = parts[1].strip().strip('"').strip("'")
                if slot.startswith("base") and value.startswith("#"):
                    slots[slot] = value
    return slots


def analyze_scheme(
    slots: dict[str, str], name: str, verbose: bool = False
) -> list[dict]:
    issues = []
    bg = slots.get("base00", "#000000")
    fg = slots.get("base05", "#ffffff")

    for slot, role in SLOT_ROLES.items():
        if slot not in slots:
            continue
        color = slots[slot]

        # fg-vs-bg: the primary readability check
        ratio = contrast_ratio(color, bg)
        level = "AAA" if ratio >= AAA_NORMAL else "AA" if ratio >= AA_NORMAL else "FAIL"

        if ratio < AA_NORMAL:
            issues.append(
                {
                    "slot": slot,
                    "role": role,
                    "color": color,
                    "vs": "base00(bg)",
                    "ratio": ratio,
                    "level": level,
                }
            )
        elif verbose:
            issues.append(
                {
                    "slot": slot,
                    "role": role,
                    "color": color,
                    "vs": "base00(bg)",
                    "ratio": ratio,
                    "level": level,
                    "info": True,
                }
            )

    # bg-vs-fg summary
    fg_ratio = contrast_ratio(fg, bg)
    return issues


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("scheme", nargs="?", help="path to scheme yaml or --all")
    parser.add_argument(
        "--all", action="store_true", help="analyze all wallpaper-* schemes"
    )
    parser.add_argument(
        "--verbose",
        "-v",
        action="store_true",
        help="show all ratios, not just failures",
    )
    args = parser.parse_args()

    if args.all:
        schemes = sorted(SCHEME_DIR.glob("wallpaper-*.yaml"))
    elif args.scheme:
        schemes = [Path(args.scheme)]
    else:
        parser.error("provide a scheme path or --all")

    total_fail = 0
    for scheme_path in schemes:
        name = scheme_path.stem
        slots = load_scheme(scheme_path)
        if len(slots) < 16:
            print(f"SKIP {name}: only {len(slots)} slots")
            continue

        issues = analyze_scheme(slots, name, args.verbose)
        fails = [i for i in issues if i.get("level") == "FAIL"]
        total_fail += len(fails)

        bg = slots.get("base00", "?")
        fg = slots.get("base05", "?")
        fg_ratio = contrast_ratio(fg, bg)

        status = "✓" if not fails else f"✗ ({len(fails)} AA failures)"
        print(f"\n{'=' * 60}")
        print(f"  {name}  [{status}]")
        print(f"  bg={bg} fg={fg} fg/bg contrast={fg_ratio:.2f}:1")
        print(f"{'=' * 60}")

        for issue in sorted(issues, key=lambda x: x["ratio"]):
            marker = "  " if issue.get("info") else "⚠ "
            print(
                f"  {marker}{issue['slot']} ({issue['role']:15s}) {issue['color']} "
                f"vs {issue['vs']}  {issue['ratio']:5.2f}:1  {issue['level']}"
            )

    print(f"\n{'=' * 60}")
    print(f"  TOTAL: {total_fail} AA failures across {len(schemes)} schemes")
    return 0 if total_fail == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
