"""Registry: name → Component/ComponentGroup instance (uniform dispatch)."""

from __future__ import annotations

from theme.componentgroups.all import AllGroup
from theme.componentgroups.macos import MacOSGroup
from theme.componentgroups.gui import GUIGroup
from theme.componentgroups.tui import TUIGroup
from theme.components.base import Component
from theme.componentgroups.wm import WMGroup
from theme.components.qt import QtComponent

_group = GUIGroup()
_tui = TUIGroup()
_all = AllGroup()
_qt = QtComponent()
_wm = WMGroup()

REGISTRY: dict[str, Component] = {
    "gui": _group,
    "tui": _tui,
    "qt": _qt,
    "wm": _wm,
    "macos": MacOSGroup(),
    "all": _all,
}
for member in _group.members:
    REGISTRY[member.key] = member
for member in _tui.members:
    REGISTRY[member.key] = member
for member in _wm.members:
    REGISTRY[member.key] = member
for member in MacOSGroup().members:
    REGISTRY[member.key] = member

SHIPPED = {"gui", "tui", "qt", "wm", "macos", "palette", "watch"}
