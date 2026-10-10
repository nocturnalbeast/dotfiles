"""TUI scheme member: resolve scheme name → tinty apply → mtime-touch; approx snaps to the nearest catalog scheme via ΔE00."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from pathlib import Path
from typing import Any

from ruamel.yaml import YAML

from theme.components.base import Component, Effects
from theme.helpers.logio import action, detail_line, fail, warn
from theme.palette import mode, slice_hash
from theme.resources.base import Context
from theme.state import make_record, read_member

SCHEME_PREFIX = "base24-wallpaper-"
TINTY_CURRENT = Path.home() / ".local/share/tinted-theming/tinty/current_scheme"
TINTY_SCHEME_DIR = (
    Path.home() / ".local/share/tinted-theming/tinty/custom-schemes/base24"
)
TINTY_CATALOG_DIR = (
    Path.home() / ".local/share/tinted-theming/tinty/repos/schemes/base24"
)
EMISSION_STAMP = (
    Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
    / "theming/palette.json"
)

from theme.engines import ENGINE_SUFFIX  # noqa: E402


def _read_yaml(path: Path) -> dict[str, Any] | None:
    yaml = YAML()
    yaml.preserve_quotes = True
    try:
        data = yaml.load(path.read_text())
    except OSError:
        return None
    return data if isinstance(data, dict) else None


def query_slots(gen_name: str) -> dict[str, str] | None:
    """Slots of an emitted generated scheme (approx query vector)."""
    path = TINTY_SCHEME_DIR / f"{gen_name.removeprefix('base24-')}.yaml"
    data = _read_yaml(path) if path.exists() else None
    if not data:
        return None
    palette = data.get("palette")
    if not isinstance(palette, dict):
        return None
    return {str(k): str(v) for k, v in palette.items()}


class SchemeComponent(Component):
    key = "scheme"
    group = "tui"

    # -- resolution ---------------------------------------------------------

    def _resolved_mode(self, ctx: Context) -> str:
        cfg = ctx.config["tui"]
        resolved = cfg["mode"]
        if resolved == "auto":
            resolved = mode(ctx.palette)
        return resolved

    def _generated_scheme_name(self, ctx: Context) -> str:
        """follow-mode name: base24-wallpaper-{mode}[-vibrant|-thaim]."""
        suffix = ENGINE_SUFFIX.get(ctx.config["engines"]["tui"], "")
        return f"{SCHEME_PREFIX}{self._resolved_mode(ctx)}{suffix}"

    def _query_slots(self, gen_name: str) -> dict[str, str] | None:
        return query_slots(gen_name)

    def _approx(
        self, ctx: Context, gen_name: str
    ) -> tuple[str, list[tuple[str, float]]]:
        """Catalog snap: nearest within τ → catalog name, else the
        generated scheme (pure function - status/apply parity)."""
        from theme.helpers.deltae import load_catalog, nearest_schemes

        query = self._query_slots(gen_name)
        if query is None:
            # artifacts missing: apply auto-emits first; status reports drift
            return gen_name, []

        catalog = load_catalog(TINTY_CATALOG_DIR)
        if not catalog:
            warn("approx: catalog unreadable - degrading to follow")
            return gen_name, []

        top = nearest_schemes(query, catalog, self._resolved_mode(ctx), k=3)
        tau = float(ctx.config["tui"]["approx_threshold"])
        if top and top[0][1] < tau:
            return top[0][0], top
        return gen_name, top

    def resolve_scheme_name(self, ctx: Context) -> str:
        cfg = ctx.config["tui"]
        if cfg["scheme"] == "approx":
            name, _ = self._approx(ctx, self._generated_scheme_name(ctx))
            return name
        if cfg["scheme"] != "follow":
            return cfg["scheme"]
        return self._generated_scheme_name(ctx)

    # -- freshness ----------------------------------

    def _verify_artifacts(self, ctx: Context) -> bool:
        """Stamp gate: engines_emitted.tui + palette_section_hash must
        match; the file-existence check is belt-only."""
        gen_name = self._generated_scheme_name(ctx)
        scheme_file = TINTY_SCHEME_DIR / f"{gen_name.removeprefix('base24-')}.yaml"
        if not scheme_file.exists():
            return False

        import hashlib

        try:
            stamp = json.loads(EMISSION_STAMP.read_text())
        except (OSError, ValueError):
            return False
        if not isinstance(stamp, dict):
            return False
        emitted = stamp.get("engines_emitted") or {}
        if emitted.get("tui") != ctx.config["engines"]["tui"]:
            return False
        current_hash = hashlib.sha256(
            json.dumps(ctx.palette, sort_keys=True, default=str).encode()
        ).hexdigest()
        return stamp.get("palette_section_hash") == current_hash

    def _auto_emit(self, ctx: Context) -> None:
        from theme.generate import emit_only

        action("artifacts stale - auto-invoking palette emit")
        emit_only()

    def _auto_regenerate(self, ctx: Context, stored: str, configured: str) -> bool:
        """Engine switch: auto-regenerate when the source image exists;
        hard error for static palettes / missing images (regeneration
        impossible)."""
        from theme.generate import GenerationError, generate

        image = ctx.palette.get("source_image")
        if (
            ctx.palette.get("source") == "static"
            or not image
            or not Path(image).exists()
        ):
            fail(
                f"engines.tui switched ({stored} → {configured}) and regeneration "
                f"is impossible (static palette or missing source image)",
                hint="run `theme palette generate --image <path>`",
            )
            return False
        if ctx.dry_run:
            action(f"would regenerate for engine switch: {stored} → {configured}")
            return True
        action(f"engine switch {stored} → {configured} - auto-invoking generation")
        mode = ctx.config.get("palette", {}).get("mode", "auto")
        try:
            generate(image, mode, engines=ctx.config.get("engines"))
        except GenerationError as e:
            fail(f"engine-switch regeneration failed: {e}")
            return False
        from theme.config import DEFAULT_CONFIG, load_yaml

        ctx.palette = (load_yaml(DEFAULT_CONFIG) or {}).get("palette", ctx.palette)
        return True

    # -- component contract --------------------------------------------------

    def consumed_slice(self, ctx: Context) -> dict[str, Any]:
        slice_: dict[str, Any] = {
            "scheme": ctx.config["tui"]["scheme"],
            "tui_engine": ctx.config["engines"]["tui"],
            "tui_mode": ctx.config["tui"]["mode"],
            "effective_mode": mode(ctx.palette),
            "approx_threshold": ctx.config["tui"]["approx_threshold"],
        }
        return slice_

    def write_effects(self, ctx: Context) -> Effects:
        """Freshness gate → conditional regeneration (the only
        config.yaml write-back; ctx.palette settles here for every
        later member) → tinty apply."""

        if not shutil.which("tinty"):
            fail("tinty not found - the engine is required")
            return Effects(code=1)

        if ctx.config["tui"]["scheme"] in ("follow", "approx"):
            stored = (ctx.palette.get("engines") or {}).get("tui")
            configured = ctx.config["engines"]["tui"]
            if stored and stored != configured:
                if not self._auto_regenerate(ctx, stored, configured):
                    return Effects(code=1)
            if not self._verify_artifacts(ctx):
                if not ctx.dry_run:
                    self._auto_emit(ctx)
                else:
                    action("would auto-emit stale artifacts")

        scheme = self.resolve_scheme_name(ctx)

        tui_engine = ctx.config["engines"]["tui"]
        if (
            ctx.config["tui"]["scheme"] in ("follow", "approx")
            and tui_engine == "thaim"
        ):
            scheme_file = TINTY_SCHEME_DIR / f"{scheme.removeprefix('base24-')}.yaml"
            if not scheme_file.exists():
                fail(
                    f"thaim engine unavailable - scheme {scheme} not emitted "
                    f"(prerequisites, /)"
                )
                return Effects(code=1)

        action(f"applying tinty scheme: {scheme}")

        if ctx.dry_run:
            action(f"would run: tinty apply {scheme}")
            return Effects()

        r = subprocess.run(["tinty", "apply", scheme], capture_output=True, text=True)
        if r.returncode != 0:
            fail(f"tinty apply failed: {r.stderr[-300:]}")
            return Effects(code=1)

        if TINTY_CURRENT.exists():
            os.utime(TINTY_CURRENT, None)

        slice_ = self.consumed_slice(ctx)
        slice_["resolved"] = scheme
        surfaces: dict[str, Any] = {
            "tinty": {
                "scheme": scheme,
                "current": TINTY_CURRENT.read_text().strip()
                if TINTY_CURRENT.exists()
                else "",
            }
        }
        if ctx.config["tui"]["scheme"] == "approx":
            _, top3 = self._approx(ctx, self._generated_scheme_name(ctx))
            surfaces["approx"] = {
                "top3": [[n, round(d, 3)] for n, d in top3],
            }
        return Effects(
            record=(
                "tui",
                "scheme",
                make_record(
                    slice_hash(slice_),
                    slice_hash(slice_),
                    {},
                    surfaces,
                ),
            )
        )

    def status(self, ctx: Context) -> int:
        from theme.helpers.logio import note_state

        old = read_member("tui", "scheme")
        code = 0

        slice_ = self.consumed_slice(ctx)
        scheme = self.resolve_scheme_name(ctx)
        slice_["resolved"] = scheme
        if not old or old.get("config_hash") != slice_hash(slice_):
            code |= 1

        current = TINTY_CURRENT.read_text().strip() if TINTY_CURRENT.exists() else ""
        detail = None
        if current != scheme:
            detail = f"current={current!r} expected={scheme!r}"
            detail_line(f"drift scheme: current={current!r} expected={scheme!r}")
            code |= 2

        if ctx.config["tui"]["scheme"] == "approx":
            gen_name = self._generated_scheme_name(ctx)
            if self._query_slots(gen_name) is None:
                warn("approx: query artifacts missing - apply needed")
                detail = detail or "approx query artifacts missing"
            else:
                _, top3 = self._approx(ctx, gen_name)
                tau = float(ctx.config["tui"]["approx_threshold"])
                if top3:
                    verdict = "snap" if scheme != gen_name else "fallback"
                    lines = ", ".join(f"{n} ({d:.2f})" for n, d in top3)
                    action(f"approx (τ={tau}): {verdict} - top-3: {lines}")
        note_state(self.group, self.key, code, detail)
        return code

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}


def suggest(config: dict[str, Any], image: str | None = None) -> int:
    """`theme tui suggest [--image]`: top-3 catalog neighbours + ΔE00
    distances per mode, τ verdict; read-only, never emits."""
    from theme.helpers.deltae import load_catalog, nearest_schemes

    from theme.engines import ENGINES, ENGINE_SUFFIX

    tui_engine_name = config["engines"]["tui"]
    suffix = ENGINE_SUFFIX.get(tui_engine_name, "")
    tau = float(config["tui"]["approx_threshold"])

    catalog = load_catalog(TINTY_CATALOG_DIR)
    if not catalog:
        fail(f"approx catalog unreadable: {TINTY_CATALOG_DIR}")
        return 1

    queries: dict[str, dict[str, str] | None] = {}
    if image:
        try:
            engine = ENGINES[tui_engine_name]
            out = engine.extract(str(image))
            for m in ("dark", "light"):
                queries[m] = out["variants"][m]["extensions"]["terminal"]
        except RuntimeError as e:
            fail(f"transient generation failed: {e}")
            return 1
    else:
        for m in ("dark", "light"):
            gen = f"{SCHEME_PREFIX}{m}{suffix}"
            slots = query_slots(gen)
            if slots is None:
                warn(
                    f"{m}: query artifacts missing "
                    f"({gen}) - apply first, or pass --image"
                )
            queries[m] = slots

    rc = 0
    from theme.helpers.logio import result, summary, width_tier
    from rich.table import Table

    table = Table(box=None, pad_edge=False, show_edge=False)
    table.add_column("#", justify="right", style="dim")
    table.add_column("scheme", style="key")
    if width_tier() >= 100:
        table.add_column("d(ΔE00)", justify="right")
    table.add_column("verdict @ τ", style="dim")

    console_header = f"tui suggest - engine: {tui_engine_name}, τ = {tau}"
    action(console_header)
    for m in ("dark", "light"):
        slots = queries.get(m)
        if slots is None:
            rc = 1
            continue
        top = nearest_schemes(slots, catalog, m, k=3)
        verdict = "would-snap" if top and top[0][1] < tau else "would-fallback"
        for rank, (name, dist) in enumerate(top, 1):
            row = [
                f"{m}[dim].{rank}[/dim]" if rank == 1 else f"[dim].{rank}[/dim]",
                name,
            ]
            if width_tier() >= 100:
                row.append(f"{dist:.3f}")
            row.append(verdict if rank == 1 else "")
            table.add_row(*row)
    result(table)
    summary(f"suggest complete · engine {tui_engine_name} · τ {tau}", to_stdout=True)
    return rc
