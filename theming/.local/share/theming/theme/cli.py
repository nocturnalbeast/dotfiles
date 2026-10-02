"""theme CLI: apply · status · palette · watch · doctor · upgrade · uninstall; targets = groups/components/members."""

from __future__ import annotations

import argparse
import sys
from contextlib import nullcontext
from pathlib import Path

from theme.config import DEFAULT_CONFIG, ConfigError, resolve
from theme.helpers.logio import console, err_console
from theme.palette import PaletteError
from theme.resources.base import Context
from theme.state import ThemeBusy, mutation_lock


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(prog="theme", description=__doc__)
    p.add_argument(
        "--config",
        type=Path,
        default=DEFAULT_CONFIG,
        help="config.yaml path (default: repo config.yaml)",
    )
    p.add_argument(
        "--override",
        action="append",
        default=[],
        metavar="k:v",
        help="repeatable dot.path:value overrides",
    )
    p.add_argument("-q", "--quiet", action="store_true", help="summary + errors only")
    p.add_argument(
        "-v",
        "--verbose",
        action="count",
        default=0,
        help="repeatable: -v detail, -vv subprocess + tracebacks",
    )
    p.add_argument(
        "--json",
        action="store_true",
        dest="json_mode",
        help="single JSON envelope on stdout",
    )
    p.add_argument("--ascii", action="store_true", help="force ASCII glyphs/boxes")
    p.add_argument("--no-progress", action="store_true", help="disable spinners/Live")
    p.add_argument("--yes", action="store_true", help="skip confirmation prompts")
    sub = p.add_subparsers(dest="cmd", required=True)

    epilogs = {
        "apply": "exit codes: 0 ok · 1 failure · 2 validation · 3 busy · 130 interrupted",
        "status": "exit codes: 0 clean · 1 apply-needed · 2 live drift · 3 both",
        "uninstall": "exit codes: 0 ok · 1 failure · 2 validation · 3 busy; confirms unless --yes",
    }
    for name in ("apply", "status", "uninstall"):
        s = sub.add_parser(name, epilog=epilogs[name])
        s.add_argument(
            "target", nargs="?" if name == "uninstall" else None, default=None
        )
        if name == "apply":
            s.add_argument(
                "--jobs",
                type=int,
                default=None,
                metavar="N",
                help="P1 worker pool cap; 1 = serial)",
            )

    up = sub.add_parser(
        "upgrade",
        epilog="exit codes: 0 ok · 1 failure · 2 validation · 3 busy; --force-rebuild confirms unless --yes",
    )
    up.add_argument("target", nargs="?", default=None)
    up.add_argument(
        "--jobs",
        type=int,
        default=None,
        metavar="N",
        help="P1 worker pool cap; 1 = serial)",
    )

    pal = sub.add_parser("palette")
    pal_sub = pal.add_subparsers(dest="palette_cmd", required=True)
    gen = pal_sub.add_parser("generate")
    gen.add_argument("--image", required=True)
    gen.add_argument("--mode", choices=["auto", "dark", "light"])
    pal_sub.add_parser("emit")

    doc = sub.add_parser(
        "doctor",
        epilog="exit codes: 0 ok · 1 warnings · 2 any failure; --strict promotes warnings to 2",
    )
    doc.add_argument("--deep", action="store_true")
    doc.add_argument(
        "--strict",
        action="store_true",
        help="warnings promote to failure severity (exit 2)",
    )
    doc.add_argument(
        "--report",
        type=Path,
        default=None,
        metavar="FILE.html",
        help="export the report as HTML",
    )
    sub.add_parser("watch")

    tui = sub.add_parser("tui")
    tui_sub = tui.add_subparsers(dest="tui_cmd", required=True)
    sug = tui_sub.add_parser("suggest")
    sug.add_argument(
        "--image",
        default=None,
        help="transient query from an image (no write-back, no emission)",
    )

    for s in sub.choices.values():
        s.add_argument("--dry-run", action="store_true")
        s.add_argument("--no-build", action="store_true")
        s.add_argument("--force-rebuild", action="store_true")
        s.add_argument("--offline", action="store_true")
    for nested in (pal_sub.choices.values(), tui_sub.choices.values()):
        for s in nested:
            s.add_argument("--dry-run", action="store_true")
            s.add_argument("--no-build", action="store_true")
            s.add_argument("--force-rebuild", action="store_true")
            s.add_argument("--offline", action="store_true")
    return p


def _ctx(args, config: dict) -> Context:
    import os

    jobs = getattr(args, "jobs", None)
    if jobs is None:
        jobs = min(4, os.cpu_count() or 1)
    return Context(
        config=config,
        palette=config.get("palette", {}),
        dry_run=args.dry_run,
        offline=args.offline,
        force=args.force_rebuild,
        no_build=args.no_build,
        jobs=max(1, jobs),
    )


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)

    from theme.helpers import logio

    if args.quiet and args.verbose:
        err_console.print("[red]-q and -v are mutually exclusive[/red]")
        return 2
    verbosity = -1 if args.quiet else args.verbose
    logio.configure(
        verbosity=verbosity,
        json_mode=args.json_mode,
        ascii_only=args.ascii,
        progress=not args.no_progress,
        dry_run=getattr(args, "dry_run", False),
        yes=args.yes,
    )

    command = (
        getattr(args, "palette_cmd", None) or getattr(args, "tui_cmd", None) or args.cmd
    )
    try:
        code = _dispatch(args, command)
    except KeyboardInterrupt:
        err_console.print("[dim]interrupted[/dim]")
        code = 130
    if args.json_mode:
        logio.emit_json(command, code)
    return code


def _render_status(target: str, code: int) -> None:
    """Status Tree from the run collector + legend + summary."""
    from rich.text import Text
    from rich.tree import Tree

    from theme.helpers import logio

    if logio.RUN.json_mode:
        return

    states = [r for r in logio.RUN.records if r.get("verb") == "state"]
    tree = Tree(Text(target, style="key"), guide_style="dim")
    by_group: dict[str, list] = {}
    for r in states:
        by_group.setdefault(r["group"], []).append(r)
    if len(by_group) == 1:
        for r in states:
            line = logio.state_label(
                {"ok": 0, "apply-needed": 1, "drift": 2, "both": 3}.get(r["state"], -1)
            )
            line.append(f" {r['member']}")
            if r.get("detail"):
                line.append(f" · {r['detail']}", style="dim")
            tree.add(line)
    else:
        for group, rows in by_group.items():
            branch = tree.add(Text(group, style="key"))
            for r in rows:
                line = logio.state_label(
                    {"ok": 0, "apply-needed": 1, "drift": 2, "both": 3}.get(
                        r["state"], -1
                    )
                )
                line.append(f" {r['member']}")
                if r.get("detail"):
                    line.append(f" · {r['detail']}", style="dim")
                branch.add(line)

    counts = {
        w: sum(1 for r in states if r["state"] == w)
        for w in ("ok", "apply-needed", "drift", "both")
        if any(r["state"] == w for r in states)
    }
    legend = Text(" · ".join(counts) if counts else "no members", style="dim")
    logio.result(tree)
    logio.console.print(legend)
    tally = " · ".join(f"{v} {k}" for k, v in counts.items()) or target
    summary_text = Text("status: ")
    summary_text.append(tally, style="key")
    logio.console.print(summary_text)


def _dispatch(args, command: str) -> int:
    try:
        config = resolve(args.config, args.override)
    except ConfigError as e:
        from theme.helpers.logio import fail

        fail(f"config error: {e}")
        return 2

    from theme.registry import REGISTRY, SHIPPED

    if args.cmd == "doctor":
        from theme.doctor import run_doctor

        return run_doctor(deep=args.deep, strict=args.strict, report=args.report)

    if args.cmd == "palette":
        from theme.generate import emit_only, generate

        try:
            if args.palette_cmd == "generate":
                mode = args.mode or config.get("palette", {}).get("mode", "auto")
                engines = config.get("engines")
                if args.dry_run:
                    generate(args.image, mode, dry_run=True, engines=engines)
                    return 0
                with mutation_lock():
                    generate(args.image, mode, engines=engines)
                return 0
            elif args.palette_cmd == "emit":
                with mutation_lock():
                    emit_only()
                return 0
        except ThemeBusy:
            from theme.helpers.logio import fail

            fail("another theme operation is running", hint="retry shortly (60s lock)")
            return 3
        except SystemExit:
            raise
        except Exception as e:
            from theme.helpers.logio import fail

            fail(str(e))
            return 1

    if args.cmd == "tui":
        from theme.components.scheme import suggest

        return suggest(config, image=args.image)

    if args.cmd == "watch":
        from theme.watch import watch_daemon

        wp = config.get("wallpaper", {})
        watch_daemon(
            tracker=wp.get("tracker", "~/.config/wm/current_wallpaper"),
            on_change=wp.get("on_change", ["all"]),
            sync=wp.get("sync", False),
        )
        return 0

    target = getattr(args, "target", None)
    if args.cmd == "upgrade" and target is None:
        target = "all"
    if target not in REGISTRY:
        err_console.print(
            f"[red]unknown target[/red] {target!r} — "
            f"valid: {', '.join(sorted(REGISTRY))}"
        )
        return 2

    component = REGISTRY[target]
    ctx = _ctx(args, config)

    try:
        if args.cmd == "status":
            code = component.status(ctx)
            _render_status(target, code)
            return code
        if args.cmd == "uninstall":
            from theme.helpers.logio import confirm

            confirm(f"Uninstall target {target!r} (removes built assets + stamps)?")
        if args.cmd == "upgrade" and args.force_rebuild:
            from theme.helpers.logio import confirm

            confirm(f"Force-rebuild {target!r} from source (long-running)?")
        # mutating ops: whole-invocation lock — dry-run is
        # lock-free
        lock = nullcontext() if args.dry_run else mutation_lock()
        with lock:
            if args.cmd == "apply":
                code = component.apply(ctx)
                from theme.helpers.reload import notify_reload, report_restart_hint

                report_restart_hint(ctx.restart_hints)
                if not args.dry_run:
                    notify_reload()
                return code
            if args.cmd == "upgrade":
                ctx.force = True
                return component.apply(ctx)
            if args.cmd == "uninstall":
                component.uninstall(ctx)
                return 0
    except ThemeBusy:
        err_console.print("[red]another theme operation is running[/red] (60s timeout)")
        return 3
    except (RuntimeError, PaletteError) as e:
        err_console.print(f"[red]{e}[/red]")
        return 1
    return 0
