"""Console pair, glyph ladder, run modes, and the verb print API."""

from __future__ import annotations

import os
import sys
import tempfile
from dataclasses import dataclass, field
import threading
from pathlib import Path
from typing import Any

from rich.console import Console
from rich.markup import escape
from rich.theme import Theme

THEME = Theme(
    {
        "ok": "green",
        "err": "bold red",
        "warn": "bold yellow",
        "info": "cyan",
        "dim": "dim",
        "key": "bold",
        "path": "underline",
        "changed": "yellow",
        "added": "green",
        "removed": "red",
        "rule": "dim",
    },
    inherit=True,
)

console = Console(theme=THEME, highlight=False)
err_console = Console(theme=THEME, highlight=False, stderr=True)

# glyph table: name -> (glyph, ascii, word)
GLYPHS = {
    "ok": ("✔", "+", "ok"),
    "fail": ("✗", "x", "fail"),
    "warn": ("!", "!", "warn"),
    "apply-needed": (">", ">", "apply-needed"),
    "drift": ("~", "~", "drift"),
    "both": ("±", "+/-", "both"),
    "skip": ("·", "-", "skip"),
    "pending": ("*", "*", "pending"),
    "action": ("→", "->", ""),
    "detail": ("⮕", "->", ""),
}

_STDOUT_SAVED = sys.stdout


@dataclass
class RunContext:
    """Run modes + the record collector; set by cli.main."""

    verbosity: int = 0  # -1 quiet · 0 default · 1 -v · 2 -vv
    json_mode: bool = False
    ascii_only: bool = False
    progress: bool = True
    dry_run: bool = False
    yes: bool = False
    records: list[dict[str, Any]] = field(default_factory=list)
    result_obj: Any = None
    deferred: bool = False  # parallel-P1 buffering
    defer_mark: int = 0
    _member: threading.local = field(default_factory=threading.local)


RUN = RunContext()


def configure(
    verbosity: int = 0,
    json_mode: bool = False,
    ascii_only: bool = False,
    progress: bool = True,
    dry_run: bool = False,
    yes: bool = False,
) -> None:
    """Enter a run mode; buffers stdout under --json."""
    RUN.verbosity = verbosity
    RUN.json_mode = json_mode
    RUN.ascii_only = ascii_only
    RUN.progress = progress
    RUN.dry_run = dry_run
    RUN.yes = yes
    RUN.records = []
    RUN.result_obj = None
    if json_mode:
        import io

        console._file = io.StringIO()


def reset() -> None:
    """Restore plain stdout (after envelope emission)."""
    if console._file is not _STDOUT_SAVED:
        console._file = _STDOUT_SAVED


def glyph(name: str, word: bool = False) -> str:
    """Glyph via the fallback ladder: --ascii, else stream encoding,
    else the word. `word=True` returns the word."""
    g, a, w = GLYPHS[name]
    if word:
        return w
    if RUN.ascii_only:
        return a
    target = err_console.file
    encoding = getattr(target, "encoding", None) or "utf-8"
    try:
        g.encode(encoding)
        return g
    except UnicodeEncodeError:
        return a


# --- verb API ------------------------------------------------------


def _record(verb: str, message: str, detail: str | None = None) -> None:
    RUN.records.append(
        {
            "verb": verb,
            "message": message,
            "owner": getattr(RUN._member, "key", None),
            **({"detail": detail} if detail else {}),
        }
    )


def _render(chosen: str, style: str, message: str, detail: str | None) -> None:
    if RUN.deferred:
        return
    line = f"[{style}]{chosen}[/{style}] {escape(message)}"
    if detail:
        line += f" [dim]· {escape(detail)}[/dim]"
    err_console.print(line)


def set_current_member(key: str | None) -> None:
    """Tag records emitted from this thread with their member (P1)."""
    RUN._member.key = key


def set_deferred(on: bool) -> None:
    """Buffer verb rendering (records still collect); marks the
    replay slice."""
    RUN.deferred = on
    if on:
        RUN.defer_mark = len(RUN.records)


def replay(member_order: list[str] | None = None) -> None:
    """Render records appended since defer-on, grouped by member in
    canonical order - default output stays byte-identical to
    a serial run regardless of worker completion order."""
    pending = RUN.records[RUN.defer_mark :]
    RUN.defer_mark = len(RUN.records)
    if RUN.json_mode:
        return
    order = {k: i for i, k in enumerate(member_order or [])}

    def sort_key(r: dict[str, Any]) -> tuple[int, int]:
        owner = r.get("owner")
        return (order.get(owner, -1), pending.index(r))

    for r in sorted(pending, key=sort_key):
        verb, message = r["verb"], r["message"]
        detail = r.get("detail")
        if verb == "ok":
            _render(glyph("ok"), "ok", message, detail)
        elif verb == "fail":
            _render(glyph("fail"), "err", message, detail)
        elif verb == "warn":
            _render(glyph("warn"), "warn", message, detail)
        elif verb == "action":
            if RUN.verbosity >= 0:
                _render(glyph("action"), "dim", message, detail)
        elif verb == "detail":
            if RUN.verbosity >= 1:
                err_console.print(f"  [dim]{escape(message)}[/dim]")


def ok(message: str, detail: str | None = None) -> None:
    _record("ok", message, detail)
    if RUN.json_mode:
        return
    _render(glyph("ok"), "ok", message, detail)


def fail(message: str, detail: str | None = None, hint: str | None = None) -> None:
    _record("fail", message, detail)
    if RUN.json_mode:
        return
    _render(glyph("fail"), "err", message, detail)
    if hint:
        err_console.print(f"  [dim]hint: {escape(hint)}[/dim]")


def warn(message: str, detail: str | None = None) -> None:
    _record("warn", message, detail)
    if RUN.json_mode:
        return
    _render(glyph("warn"), "warn", message, detail)


def action(message: str, detail: str | None = None) -> None:
    if RUN.verbosity < 0:
        return
    _record("action", message, detail)
    if RUN.json_mode:
        return
    _render(glyph("action"), "dim", message, detail)


def detail_line(message: str) -> None:
    if RUN.verbosity < 1 or RUN.json_mode:
        return
    if RUN.deferred:
        _record("detail", message)
        return
    err_console.print(f"  [dim]{escape(message)}[/dim]")


def phase(title: str) -> None:
    if RUN.verbosity < 0 or RUN.json_mode or RUN.deferred:
        return
    err_console.rule(f"[rule]{escape(title)}[/rule]", style="rule")


def summary(message: str, to_stdout: bool = False) -> None:
    """Always-last line; survives -q."""
    _record("summary", message)
    if RUN.json_mode:
        return
    target = console if to_stdout else err_console
    target.print(f"[key]{escape(message)}[/key]")


def result(obj: Any) -> None:
    """Command output; the envelope's result under --json."""
    RUN.result_obj = obj
    if RUN.json_mode:
        return
    console.print(obj)


# --- --json envelope ------------------------------------------------


def emit_json(command: str, exit_code: int, exit_reason: str | None = None) -> None:
    """Write the JSON envelope to real stdout and restore."""
    import json

    envelope: dict[str, Any] = {
        "schema": 1,
        "command": command,
        "results": RUN.records,
    }
    if RUN.result_obj is not None:
        envelope["result"] = RUN.result_obj
    envelope["summary"] = {"exit_code": exit_code}
    if exit_reason:
        envelope["summary"]["exit_reason"] = exit_reason
    reset()
    print(json.dumps(envelope, indent=2, default=str))


# --- swatches ------------------------------------------------------


def swatch_row(pairs: list[tuple[str, str]]) -> "Text":
    """One rich Text line of truecolor swatch chips + labels."""
    from rich.text import Text

    t = Text()
    truecolor = console.color_system == "truecolor"
    for i, (hex_val, name) in enumerate(pairs):
        if i:
            t.append("  ")
        if truecolor:
            t.append("  ", style=f"on {hex_val}")
        t.append(f" {hex_val} {name}", style="dim" if not truecolor else "none")
    return t


def atomic_write(path: Path, text: str) -> None:
    """Temp + rename onto the target's realpath (stow-safe)."""
    path = Path(path).resolve()
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=path.name + ".")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(text)
        os.replace(tmp, path)
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


# --- status states + Tree/envelope data ----------------------

STATE_GLYPHS = {0: "ok", 1: "apply-needed", 2: "drift", 3: "both"}
STATE_WORDS: dict[int, str] = {0: "ok", 1: "apply-needed", 2: "drift", 3: "both"}


def note_state(group: str, member: str, code: int, detail: str | None = None) -> None:
    """Record a member status state for the Tree/envelope."""
    RUN.records.append(
        {
            "verb": "state",
            "group": group,
            "member": member,
            "state": STATE_WORDS.get(code, str(code)),  # noqa: mixed type tolerated in records
            **({"detail": detail} if detail else {}),
        }
    )


def state_label(code: int) -> "Text":
    from rich.text import Text

    return Text(
        f"{glyph(STATE_GLYPHS.get(code, 'pending'))} {STATE_WORDS.get(code, str(code))}",
        style={0: "ok", 1: "changed", 2: "warn", 3: "warn"}.get(code, "dim"),
    )


# --- StatusLog -----------------------------------


class StatusLog:
    """Transient spinner over a subprocess span; tail Panel on failure.

    Disabled at -v, non-TTY, --no-progress, or --json.
    """

    def __init__(self, label: str):
        self.label = label
        self._live = None

    def __enter__(self) -> "StatusLog":
        active = (
            RUN.progress
            and RUN.verbosity == 0
            and not RUN.json_mode
            and not RUN.dry_run
            and err_console.is_terminal
        )
        if not active:
            action(self.label)
            return self
        from rich.live import Live
        from rich.panel import Panel
        from rich.spinner import Spinner
        from rich.console import Group

        self._panel = Panel("", title=self.label, border_style="dim", height=4)
        self._live = Live(
            Group(Spinner("dots", text=self.label, style="dim"), self._panel),
            console=err_console,
            transient=True,
            refresh_per_second=6,
        )
        self._live.start()
        return self

    def tail(self, text: str) -> None:
        """Feed subprocess output (called with captured chunks)."""
        self._tail_text = text

    def __exit__(self, exc_type, exc, tb) -> bool:
        if self._live is not None:
            self._live.stop()
        if exc is not None:
            text = getattr(self, "_tail_text", "") or str(exc)
            from rich.panel import Panel

            lines = text.strip().splitlines()[-10:]
            if lines:
                err_console.print(
                    Panel("\n".join(lines), title=self.label, border_style="err")
                )
        else:
            action(f"{self.label} - done")
        return False


# --- confirmations ---------------------------------------------------


def confirm(question: str, default: bool = False) -> bool:
    """Confirm on stderr; --yes short-circuits, non-TTY is an error."""
    from rich.prompt import Confirm

    if getattr(RUN, "yes", False):
        return True
    if not sys.stdin.isatty():
        raise RuntimeError(
            f"{question} - confirmation required but stdin is not a TTY (use --yes)"
        )
    return Confirm.ask(question, default=default, console=err_console)


# --- width tiers -----------------------------------------------------


def width_tier() -> int:
    """Layout tier from console width: 100/80/60/40."""
    w = console.width
    if w >= 100:
        return 100
    if w >= 80:
        return 80
    if w >= 60:
        return 60
    return 40
