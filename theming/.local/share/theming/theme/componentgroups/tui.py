"""tui group: scheme → vivid → atuin → fsh (normative order)."""

from __future__ import annotations

from theme.componentgroups.base import ComponentGroup
from theme.components.scheme import SchemeComponent
from theme.components.atuin import AtuinComponent
from theme.components.fsh import FshComponent
from theme.components.superfile import SuperfileComponent
from theme.components.vivid import VividComponent


class TUIGroup(ComponentGroup):
    key = "tui"
    members = [
        SchemeComponent(),
        VividComponent(),
        AtuinComponent(),
        FshComponent(),
        SuperfileComponent(),
    ]
