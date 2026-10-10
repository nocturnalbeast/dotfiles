"""Apply executor: gate → parallel writes → surface merge → reloads → stamp commit; collect-all, canonical output order."""

from __future__ import annotations

import sys

from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from typing import Any, Iterator, Sequence

from theme.components.base import Component, Effects
from theme.helpers import logio, reload, writers
from theme.helpers.logio import atomic_write, warn
from theme.resources.base import Context

# shared surfaces: id → (path, writer kind, writer kwargs)
from theme.components.gtk import S1, S2, S3, S4, S6
from theme.components.aerospace import BORDERS_SH
from theme.components.wm import BSPWM_SET_COLORS, XRESOURCES

SURFACE_SPECS: dict[str, tuple[Path, str, dict[str, Any]]] = {
    "S1": (S1, "space", {}),
    "S2": (S2, "eq", {"section": "Settings"}),
    "S3": (S3, "eq", {"section": "Settings"}),
    "S4": (S4, "eq", {"quote": True}),
    "S6": (S6, "managed", {}),
}

SURFACE_XRESOURCES = XRESOURCES
SURFACE_BSPWM = BSPWM_SET_COLORS
SURFACE_BORDERS_SH = BORDERS_SH

RELOAD_ORDER = (
    "sighup",
    "xrdb",
    "bspwm",
    "dunst",
    "mako",
    "fcache",
    "iconcache",
    "xsetroot",
    "sketchybar",
    "borders",
    "awesome",
)


def _waves(members: list[Component]) -> Iterator[list[Component]]:
    """Scheduling waves by write_deps: notify waits for icons."""
    done: set[str] = set()
    remaining = list(members)
    while remaining:
        wave = [m for m in remaining if m.write_deps <= done]
        if not wave:  # dependency cycle guard: proceed in order
            wave = list(remaining)
        for m in wave:
            remaining.remove(m)
        done.update(m.key for m in wave)
        yield wave


def _native(m: Component) -> bool:
    return (
        not m.platform
        or {"linux": "linux", "darwin": "darwin"}.get(m.platform) == sys.platform
    )


def _skip_note(m: Component) -> None:
    from theme.helpers.logio import action

    action(f"{m.key}: skipped ({m.platform}-only, running on {sys.platform})")


def _safe_write(m: Component, ctx: Context) -> Effects:
    """Collect-all: a member's exception never skips another."""
    logio.set_current_member(m.key)
    try:
        return m.write_effects(ctx)
    except Exception as e:  # noqa: BLE001 - reported, run continues
        from theme.helpers.logio import fail

        fail(f"{m.key}: {e}")
        return Effects(code=1)
    finally:
        logio.set_current_member(None)


def _merge_surfaces(contribs: dict[str, list[dict[str, Any]]]) -> None:
    for sid in sorted(contribs):
        path, kind, kwargs = SURFACE_SPECS[sid]
        merged: dict[str, Any] = {}
        for contrib in contribs[sid]:
            merged.update(contrib)
        text = writers.read_surface(path)
        if kind == "space":
            new_text = writers.update_space_kv(text, merged)
        elif kind == "eq":
            new_text = writers.update_eq_kv(text, merged, **kwargs)
        else:
            raise RuntimeError(f"surface {sid} has no merge writer")
        atomic_write(path, new_text)


def _merge_managed(managed: list[tuple[str, str, str | None]]) -> None:
    path = SURFACE_SPECS["S6"][0]
    text = writers.read_surface(path)
    for _sid, var, value in managed:
        text, neutralized = writers.managed_line_set(text, var, value)
        if neutralized:
            warn(f"neutralized unmanaged {var} export")
    atomic_write(path, text)


def _run_reloads(ctx: Context, declared: list[tuple[str, dict[str, Any]]]) -> None:
    """Ordered, deduped, best-effort reloads - a failure warns, never fails the apply."""
    from theme.helpers.logio import ok

    seen: dict[tuple[str, str], dict[str, Any]] = {}
    for kind, params in declared:
        dedup = (kind, str(params.get("dir", "")) if kind == "iconcache" else kind)
        seen.setdefault(dedup, params)
    for kind in RELOAD_ORDER:
        for (dk, _), params in seen.items():
            if dk != kind:
                continue
            if kind == "sighup":
                if not reload.sighup_xsettingsd():
                    ctx.restart_hints.append("xsettingsd (not running)")
                else:
                    ok("xsettingsd reloaded (SIGHUP)")
            elif kind == "xrdb":
                if reload.xrdb_merge(SURFACE_XRESOURCES):
                    ok("xresources merged live (W1)")
                else:
                    warn(
                        "xrdb absent or no X session - writes landed, "
                        "reload on next X11 session"
                    )
            elif kind == "bspwm":
                if reload.bspwm_apply_colors(SURFACE_BSPWM):
                    ok("bspwm colors applied live (W3)")
                else:
                    warn("bspc absent - manual reload needed")
            elif kind == "dunst":
                if reload.dunst_reload():
                    ok("dunst reloaded (W6)")
            elif kind == "mako":
                if reload.mako_reload():
                    ok("mako reloaded (W7)")
            elif kind == "fcache":
                if not reload.fc_cache():
                    warn("fc-cache absent")
            elif kind == "iconcache":
                reload.gtk_update_icon_cache(Path(params["dir"]))
            elif kind == "xsetroot":
                home = Path.home()
                if not reload.xsetroot_cursor(
                    params["theme"],
                    [
                        home / ".local/share/icons",
                        home / ".icons",
                        Path("/usr/share/icons"),
                    ],
                ):
                    ctx.restart_hints.append("root cursor (xsetroot absent or X11-off)")
            elif kind == "sketchybar":
                if reload.sketchybar_reload():
                    ok("sketchybar reloaded")
            elif kind == "borders":
                if reload.borders_relaunch(SURFACE_BORDERS_SH):
                    ok("borders relaunched")
            elif kind == "awesome":
                if reload.awesome_restart():
                    ok("awesome restarted (W2 reload)")


def run_members(ctx: Context, members: Sequence[Component]) -> int:
    """Run members and join effects; records replay in members-list order regardless of worker completion."""
    from theme.state import commit_members

    runnable = [m for m in members if _native(m)]
    for m in members:
        if m not in runnable:
            _skip_note(m)
    members = runnable
    scheme = next((m for m in members if m.key == "scheme"), None)
    rest = [m for m in members if m is not scheme]

    groups = sorted({m.group for m in members if m.group})
    logio.phase(
        f"apply · {'/'.join(groups) if groups else 'nothing (all members skipped)'}"
    )

    jobs = max(1, int(getattr(ctx, "jobs", 1)))
    parallel = jobs > 1 and not ctx.dry_run and len(rest) > 1

    results: list[tuple[Component, Effects]] = []
    canonical = ([scheme] if scheme else []) + rest

    logio.set_deferred(parallel)
    try:
        if scheme is not None:
            results.append((scheme, _safe_write(scheme, ctx)))
        for wave in _waves(rest):
            if not parallel or len(wave) == 1:
                for m in wave:
                    results.append((m, _safe_write(m, ctx)))
            else:
                with ThreadPoolExecutor(max_workers=jobs) as pool:
                    futures = [pool.submit(_safe_write, m, ctx) for m in wave]
                    results.extend((m, f.result()) for m, f in zip(wave, futures))
    finally:
        logio.set_deferred(False)

    if parallel:
        logio.replay([m.key for m in canonical])

    # shared surfaces: merge-write, one atomic write per file
    surface_contribs: dict[str, list[dict[str, Any]]] = {}
    managed: list[tuple[str, str, str | None]] = []
    for m, eff in results:
        for sid, contrib in eff.surfaces.items():
            surface_contribs.setdefault(sid, []).append(contrib)
        managed.extend(eff.managed)
    if not ctx.dry_run:
        if surface_contribs:
            _merge_surfaces(surface_contribs)
        if managed:
            _merge_managed(managed)

    # consolidated reloads
    declared: list[tuple[str, dict[str, Any]]] = []
    for _m, eff in results:
        declared.extend(eff.reloads)
    if not ctx.dry_run and declared:
        _run_reloads(ctx, declared)

    # stamp commit at join
    if not ctx.dry_run:
        commit_members([eff.record for _m, eff in results if eff.record])
    for _m, eff in results:
        ctx.restart_hints.extend(eff.restart_hints)

    return max((eff.code for _m, eff in results), default=0)
