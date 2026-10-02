"""gui group: gtk → icons → cursors → fonts → zathura (normative order)."""

from __future__ import annotations

from theme.componentgroups.base import ComponentGroup
from theme.components.cursors import CursorsComponent
from theme.components.fonts import FontsComponent
from theme.components.zathura import ZathuraComponent
from theme.components.gtk import GTKComponent
from theme.components.icons import IconsComponent


class GUIGroup(ComponentGroup):
    key = "gui"
    members = [
        GTKComponent(),
        IconsComponent(),
        CursorsComponent(),
        FontsComponent(),
        ZathuraComponent(),
    ]
