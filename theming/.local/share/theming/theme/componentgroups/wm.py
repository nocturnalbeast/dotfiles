"""wm group: six members, uniform dispatch."""

from __future__ import annotations

from theme.components.wm import (
    BarMember,
    ChromeMember,
    LockMember,
    MenuMember,
    NotifyMember,
    XresourcesMember,
)
from theme.componentgroups.base import ComponentGroup


class WMGroup(ComponentGroup):
    key = "wm"

    def __init__(self) -> None:
        self.members = [
            XresourcesMember(),
            ChromeMember(),
            NotifyMember(),
            LockMember(),
            MenuMember(),
            BarMember(),
        ]
