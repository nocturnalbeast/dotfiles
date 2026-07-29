import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../services"

PanelWindow {
    id: sessionWindow

    exclusionMode: SessionService.open ? ExclusionMode.Normal : ExclusionMode.Ignore
    aboveWindows: true
    visible: SessionService.open
    WlrLayershell.keyboardFocus: SessionService.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    SessionScreenContent {
        anchors.fill: parent
    }
}
