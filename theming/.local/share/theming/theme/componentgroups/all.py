"""all group: total-set alias composing every registered component."""

from __future__ import annotations

from theme.componentgroups.base import ComponentGroup
from theme.componentgroups.gui import GUIGroup
from theme.componentgroups.macos import MacOSGroup
from theme.componentgroups.tui import TUIGroup
from theme.componentgroups.wm import WMGroup
from theme.components.qt import QtComponent


class AllGroup(ComponentGroup):
    key = "all"

    def __init__(self) -> None:
        self.members = (
            list(GUIGroup.members)
            + list(TUIGroup.members)
            + [QtComponent()]
            + list(WMGroup().members)
            + list(MacOSGroup().members)
        )
