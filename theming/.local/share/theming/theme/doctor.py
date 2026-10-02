"""Dependency/asset audit; never takes the flock. Exit: 0 ok · 1 warnings · 2 any failure."""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

from theme.helpers.logio import console
from theme.registry import SHIPPED
from theme.state import CACHE_DIR, STATE_DIR

HOME = Path.home()
LEVELS = {"ok": 0, "skip": 0, "warn": 1, "fail": 2}
RESULTS: list[tuple[str, str, str]] = []


def check(level: str, domain: str, detail: str) -> None:
    RESULTS.append((level, domain, detail))


def _which(name: str) -> bool:
    return shutil.which(name) is not None


def _display_contract() -> tuple[str, str]:
    """External writer audit: partial-rewrite + flock."""
    script = HOME / ".local/bin/display"
    if not script.exists():
        return "fail", "display script missing"
    text = script.read_text()
    if "grep -vE" in text and "pkill -HUP xsettingsd" in text:
        if "theming/lock" in text or "flock" in text.lower():
            return "ok", "partial-rewrite + SIGHUP + lock"
        return "warn", "partial-rewrite + SIGHUP (no flock acquisition yet)"
    return "fail", "pre-contract version (whole-file rewrite)"


def run_doctor(
    deep: bool = False, strict: bool = False, report: Path | None = None
) -> int:

    # -- core runtime ------------------------------------------------------
    for tool in ("git", "uv", "python3"):
        check("ok" if _which(tool) else "fail", "core", tool)
    launcher = HOME / ".local/bin/theme"
    check("ok" if launcher.exists() else "fail", "core", f"launcher symlink {launcher}")

    # -- external writer -----------------------------------------------------
    level, detail = _display_contract()
    check(level, "ext-writer", f"display: {detail}")

    # -- palette engine ------------------------------------------------------
    if "palette" not in SHIPPED:
        check("skip", "palette", "engine not shipped")
    else:
        check("ok" if _which("matugen") else "fail", "palette", "matugen")

    # -- tui domain ---------------------------------------------------------
    if "tui" in SHIPPED:
        check("ok" if _which("tinty") else "fail", "tui", "tinty (the engine)")
        check("ok" if _which("vivid") else "warn", "tui", "vivid (LS_COLORS)")
        # thaimeleon: warn-not-fail (watch daemon soft-degrades) but name the failing flavor when config selects it
        if _which("thaimeleon"):
            from theme.engines.thaim import THAIM_PINNED_VERSION

            try:
                r = subprocess.run(
                    ["thaimeleon", "--version"], capture_output=True, text=True
                )
                ver = (r.stdout + r.stderr).strip()
                good = THAIM_PINNED_VERSION in ver
            except OSError:
                good, ver = False, "unqueryable"
            note = f"thaimeleon {ver}"
            if not good:
                note += (
                    f" — pinned {THAIM_PINNED_VERSION} (slot-mapping contract); "
                    f"flavor 'thaim' unavailable"
                )
            check("ok" if good else "warn", "tui", note)
        else:
            check(
                "warn",
                "tui",
                "thaimeleon absent — flavor 'thaim' unavailable "
                "(cargo install thaimeleon --version 0.1.2 --locked)",
            )
        if _which("wallust"):
            from theme.engines.wallust import WALLUST_PINNED_VERSION, wallust_version

            ver = wallust_version()
            check(
                "ok" if ver == WALLUST_PINNED_VERSION else "warn",
                "tui",
                f"wallust {ver or 'unqueryable'}"
                + (
                    ""
                    if ver == WALLUST_PINNED_VERSION
                    else f" — pinned {WALLUST_PINNED_VERSION}; engine 'wallust' gated"
                ),
            )
        else:
            check(
                "warn",
                "tui",
                "wallust absent — engine 'wallust' unavailable "
                "(cargo install --git https://codeberg.org/explosion-mental/wallust.git "
                "--tag 3.5.2 --locked)",
            )
        catalog = HOME / ".local/share/tinted-theming/tinty/repos/schemes/base24"
        if catalog.is_dir():
            count = sum(1 for _ in catalog.glob("*.yaml"))
            check(
                "ok" if count >= 200 else "warn",
                "tui",
                f"approx catalog: {count} base24 schemes"
                + ("" if count >= 200 else " (degrades to follow)"),
            )
        else:
            check("warn", "tui", "approx catalog absent")

    # -- gui domain (shipped) --------------------------------------------------
    if "gui" in SHIPPED:
        for tool in ("meson", "ninja", "sassc"):
            check("ok" if _which(tool) else "warn", "gui/gtk", tool)
        for tool in ("node", "npm"):
            check(
                "ok" if _which(tool) else "warn",
                "gui/gtk",
                f"{tool} (materia dart-sass)",
            )
        for tool in ("magick", "identify", "xsetroot", "xcursorgen", "sed", "grep"):
            check("ok" if _which(tool) else "warn", "gui/cursors", tool)
        if deep:
            r = subprocess.run(
                ["npx", "--yes", "cbmp", "--help"], capture_output=True, text=True
            )
            check(
                "ok" if r.returncode == 0 else "warn", "gui/cursors", "npx cbmp (deep)"
            )
            r = subprocess.run(
                ["uvx", "--from", "clickgen", "ctgen", "--help"],
                capture_output=True,
                text=True,
            )
            check("ok" if r.returncode == 0 else "warn", "gui/cursors", "ctgen (deep)")
        zf = CACHE_DIR / "bitmaps" / "bitmaps.zip"
        check(
            "ok" if zf.exists() else "warn",
            "gui/cursors",
            f"bitmaps.zip {'cached' if zf.exists() else 'absent (network on next bibata build)'}",
        )
        check(
            "ok" if _which("gtk-update-icon-cache") else "warn",
            "gui/icons",
            "gtk-update-icon-cache",
        )

    # -- qt domain ------------------------------------------------------------
    if "qt" in SHIPPED:
        check(
            "ok" if _which("qt6ct") else "fail",
            "qt",
            "qt6ct (platformtheme, both modes)",
        )
        check(
            "ok"
            if Path("/usr/lib64/qt6/plugins/styles/libkvantum.so").exists()
            else "warn",
            "qt",
            "kvantum engine"
            + (
                ""
                if Path("/usr/lib64/qt6/plugins/styles/libkvantum.so").exists()
                else " absent — fusion fallback (zypper in kvantum-qt6)"
            ),
        )

    # -- wm domain -----------------------------------------------------------
    if "wm" in SHIPPED:
        for tool in ("xrdb", "awesome-client", "bspc", "makoctl", "dunstctl"):
            check("ok" if _which(tool) else "warn", "wm", tool)

    # -- unshipped domains ------------------------------------------------------
    for domain in ():
        if domain not in SHIPPED:
            check("skip", domain, "ships in a later phase")

    # -- fonts ----------------------------------------------------------------------
    check("ok" if _which("fc-cache") else "warn", "fonts", "fc-cache")
    fontconf = HOME / ".config/fontconfig/fonts.conf"
    check(
        "ok" if fontconf.exists() and fontconf.parent.is_dir() else "warn",
        "fonts",
        f"fonts.conf {'writable' if fontconf.exists() else 'absent (bootstrap on apply)'}",
    )

    # -- fallback shim  -------
    icons = HOME / ".local/share/icons"
    shim = icons / "default" / "index.theme"
    if shim.exists():
        inherits = ""
        try:
            inherits = next(
                l.split("=", 1)[1].strip()
                for l in shim.read_text().splitlines()
                if l.startswith("Inherits=")
            )
        except (OSError, StopIteration):
            pass
        live = (icons / inherits).exists() if inherits else False
        check(
            "ok" if live else "warn",
            "fallback-shim",
            f"default → {inherits or 'nothing'}"
            + ("" if live else " (dangling Inherits — cursor fallback broken)"),
        )
    else:
        check(
            "warn",
            "fallback-shim",
            "icons/default shim missing — apps requesting theme 'default' "
            "fall to hicolor",
        )

    # -- state sanity ------------------------------------------------------------------
    for group in ("gui",):
        path = STATE_DIR / f"{group}.json"
        if path.exists():
            import json

            try:
                json.loads(path.read_text())
                check("ok", "state", f"{group}.json parses")
            except json.JSONDecodeError:
                check("warn", "state", f"{group}.json corrupt (≡ missing, self-heals)")
        else:
            check("ok", "state", f"{group}.json absent (first apply)")
    check("ok" if CACHE_DIR.exists() else "ok", "state", "sources dir")

    # -- watch daemon ----------------------------------------------------------
    hb = STATE_DIR / "watch.heartbeat"
    if "watch" not in SHIPPED:
        check("skip", "watch", "daemon not shipped")
    else:
        import time as _time

        fresh = hb.exists() and _time.time() - hb.stat().st_mtime < 120
        check(
            "ok" if fresh else "fail",
            "watch",
            "heartbeat" + ("" if fresh else " stale (>120s — daemon dead?)"),
        )

    # -- report --------
    from theme.helpers import logio
    from rich.panel import Panel
    from rich.text import Text

    glyph_map = {
        "ok": ("ok", "ok"),
        "skip": ("skip", "dim"),
        "warn": ("warn", "warn"),
        "fail": ("fail", "err"),
    }
    counts = {
        lvl: sum(1 for r in RESULTS if r[0] == lvl)
        for lvl in ("ok", "skip", "warn", "fail")
    }
    worst = max((LEVELS[lvl] for lvl, _, _ in RESULTS), default=0)

    for level, domain, detail in RESULTS:
        logio.RUN.records.append(
            {"verb": "check", "level": level, "domain": domain, "detail": detail}
        )

    if logio.RUN.json_mode:
        return _strict_code(worst, counts, strict)

    lines_by_domain: dict[str, list[tuple[str, str]]] = {}
    for level, domain, detail in RESULTS:
        lines_by_domain.setdefault(domain, []).append((level, detail))

    body = Text()
    for i, (domain, checks) in enumerate(lines_by_domain.items()):
        if i:
            body.append("\n")
        body.append(domain.upper(), style="info")
        body.append("\n")
        for level, detail in checks:
            g, style = glyph_map[level]
            body.append(f"  {logio.glyph(g)} ", style=style)
            body.append(f"{level}", style=style)
            body.append(f" {detail}\n", style="dim")
    summary_bits = " · ".join(f"{v} {k}" for k, v in counts.items() if v) or "no checks"
    body.rstrip()
    panel = Panel(body, title="doctor", border_style="dim")
    logio.result(panel)
    logio.console.print(Text(summary_bits, style="dim"))
    if report is not None:
        from rich.console import Console as RichConsole

        rec = RichConsole(
            record=True, width=100, force_terminal=True, color_system="truecolor"
        )
        rec.print(panel)
        rec.print(Text(summary_bits, style="dim"))
        report = Path(report).expanduser()
        report.parent.mkdir(parents=True, exist_ok=True)
        report.write_text(rec.export_html(inline_styles=True), encoding="utf-8")
        logio.action(f"report written to {report}")
    return _strict_code(worst, counts, strict)


def _strict_code(worst: int, counts: dict[str, int], strict: bool) -> int:
    # 0 ok · 1 warnings · 2 failure; --strict promotes warnings to 2 (warn alone already exits 1)
    if worst >= 2:
        return 2
    if strict and counts.get("warn"):
        return 2
    if worst == 1:
        return 1
    return 0
