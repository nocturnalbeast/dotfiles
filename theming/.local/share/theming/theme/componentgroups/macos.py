"""macos group: sketchybar, aerospace."""

from __future__ import annotations

from theme.componentgroups.base import ComponentGroup
from theme.components.aerospace import AerospaceComponent
from theme.components.sketchybar import SketchybarComponent


class MacOSGroup(ComponentGroup):
    key = "macos"

    def __init__(self) -> None:
        self.members = [
            SketchybarComponent(),
            AerospaceComponent(),
        ]
