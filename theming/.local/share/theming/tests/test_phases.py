"""Phase executor tests: ordering, waves, merge-writes, reload sequencing, stamp batching, collect-all, serial equivalence."""

from __future__ import annotations

import unittest
from pathlib import Path
from typing import Any
from unittest import mock

from theme.components.base import Component, Effects
from theme.resources.base import Context


class Fake(Component):
    group = "test"

    def __init__(self, key: str, calls: list[str], **kw: Any) -> None:
        self.key = key
        self.calls = calls
        self.fails = kw.get("fails", False)
        self.write_deps = frozenset(kw.get("deps", ()))

    def write_effects(self, ctx: Context) -> Effects:
        self.calls.append(f"write:{self.key}")
        if self.fails:
            raise RuntimeError("boom")
        eff = Effects(reloads=kw_reloads.get(self.key, []))
        return eff

    def status(self, ctx: Context) -> int:
        return 0

    def build(self, ctx: Context) -> dict[str, Any]:
        return {}


kw_reloads: dict[str, list] = {}


def _ctx(jobs: int = 4, **kw: Any) -> Context:
    return Context(config={}, palette={}, jobs=jobs, **kw)


class TestPhaseOrdering(unittest.TestCase):
    def test_scheme_runs_first(self):
        calls: list[str] = []
        kw_reloads.clear()
        members = [
            Fake("zzz", calls),
            Fake("scheme", calls),
            Fake("aaa", calls),
        ]
        from theme.apply_phases import run_members

        with (
            mock.patch("theme.apply_phases._merge_surfaces"),
            mock.patch("theme.apply_phases._merge_managed"),
            mock.patch("theme.apply_phases._run_reloads"),
            mock.patch("theme.state.commit_members"),
        ):
            code = run_members(_ctx(), members)
        self.assertEqual(code, 0)
        self.assertEqual(calls[0], "write:scheme")

    def test_write_deps_wave(self):
        calls: list[str] = []
        kw_reloads.clear()
        members = [Fake("icons", calls), Fake("notify", calls, deps={"icons"})]
        from theme.apply_phases import run_members

        with (
            mock.patch("theme.apply_phases._merge_surfaces"),
            mock.patch("theme.apply_phases._merge_managed"),
            mock.patch("theme.apply_phases._run_reloads"),
            mock.patch("theme.state.commit_members"),
        ):
            run_members(_ctx(jobs=1), members)
        self.assertLess(calls.index("write:icons"), calls.index("write:notify"))

    def test_collect_all_continues(self):
        calls: list[str] = []
        kw_reloads.clear()
        members = [Fake("bad", calls, fails=True), Fake("good", calls)]
        from theme.apply_phases import run_members

        with (
            mock.patch("theme.apply_phases._merge_surfaces"),
            mock.patch("theme.apply_phases._merge_managed"),
            mock.patch("theme.apply_phases._run_reloads"),
            mock.patch("theme.state.commit_members"),
        ):
            code = run_members(_ctx(jobs=1), members)
        self.assertEqual(code, 1)
        self.assertIn("write:good", calls)


class TestMergeSurfaces(unittest.TestCase):
    def test_s1_merged_single_write(self):
        from theme import apply_phases
        from theme.helpers import writers

        tmp = Path("/tmp/opencode/s1-test")
        tmp.parent.mkdir(parents=True, exist_ok=True)
        tmp.write_text("Net/Other keepme\n")
        with mock.patch.dict(
            apply_phases.SURFACE_SPECS,
            {"S1": (tmp, "space", {})},
        ):
            apply_phases._merge_surfaces(
                {
                    "S1": [
                        {"Net/ThemeName": "Tela-dark"},
                        {"Net/IconThemeName": "Tela-dark"},
                    ],
                }
            )
        text = tmp.read_text()
        self.assertIn("Net/Other keepme", text)
        self.assertIn('Net/ThemeName "Tela-dark"', text)
        self.assertIn('Net/IconThemeName "Tela-dark"', text)


class TestReloadOrder(unittest.TestCase):
    def test_ordered_and_deduped(self):
        from theme import apply_phases

        fired: list[str] = []
        with (
            mock.patch.object(
                apply_phases.reload,
                "sighup_xsettingsd",
                side_effect=lambda: fired.append("sighup") or True,
            ),
            mock.patch.object(
                apply_phases.reload,
                "xrdb_merge",
                side_effect=lambda p: fired.append("xrdb") or True,
            ),
            mock.patch.object(
                apply_phases.reload,
                "awesome_restart",
                side_effect=lambda: fired.append("awesome") or True,
            ),
            mock.patch.object(
                apply_phases.reload,
                "dunst_reload",
                side_effect=lambda: fired.append("dunst") or True,
            ),
        ):
            apply_phases._run_reloads(
                _ctx(),
                [
                    ("awesome", {}),
                    ("dunst", {}),
                    ("dunst", {}),
                    ("sighup", {}),
                    ("sighup", {}),
                    ("xrdb", {}),
                ],
            )
        self.assertEqual(fired, ["sighup", "xrdb", "dunst", "awesome"])


class TestStampBatch(unittest.TestCase):
    def test_commit_members_groups_writes(self):
        from theme import state

        with (
            mock.patch.object(state, "read_stamp", side_effect=lambda g: {}),
            mock.patch.object(state, "write_stamp") as ws,
        ):
            state.commit_members(
                [
                    ("gui", "gtk", {"a": 1}),
                    ("gui", "icons", {"b": 2}),
                    ("tui", "vivid", {"c": 3}),
                ]
            )
        groups = [c.args[0] for c in ws.call_args_list]
        self.assertEqual(sorted(groups), ["gui", "tui"])
        gui_write = next(c for c in ws.call_args_list if c.args[0] == "gui")
        self.assertEqual(gui_write.args[1], {"gtk": {"a": 1}, "icons": {"b": 2}})


class TestSerialEquivalence(unittest.TestCase):
    def test_jobs1_matches_legacy_order(self):
        calls: list[str] = []
        kw_reloads.clear()
        members = [Fake(k, calls) for k in ("a", "b", "c", "d")]
        from theme.apply_phases import run_members

        with (
            mock.patch("theme.apply_phases._merge_surfaces"),
            mock.patch("theme.apply_phases._merge_managed"),
            mock.patch("theme.apply_phases._run_reloads"),
            mock.patch("theme.state.commit_members"),
        ):
            run_members(_ctx(jobs=1), members)
        self.assertEqual(calls, ["write:a", "write:b", "write:c", "write:d"])


if __name__ == "__main__":
    unittest.main()
