import Quickshell
import QtQuick
import "../../services"

PanelWindow {
    id: sessionWindow

    exclusionMode: SessionService.open ? ExclusionMode.Normal : ExclusionMode.Ignore
    aboveWindows: true
    visible: SessionService.open

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
