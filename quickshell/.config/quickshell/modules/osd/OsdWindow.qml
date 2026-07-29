import Quickshell
import QtQuick
import "../../services"
import "../../theme"
import "../../config"

PanelWindow {
    id: osdWindow

    screen: modelData

    property string posAnchor: Config.osdPosition
    property int offsetX: Config.osdOffsetX
    property int offsetY: Config.osdOffsetY
    property int marginX: Config.osdMarginX
    property int marginY: Config.osdMarginY

    property bool _isToggle: OsdManager.activeType === "bluetooth" || OsdManager.activeType === "wifi" || OsdManager.activeType === "caffeine"
    property int _osdWidth: _isToggle ? Spacing.osdToggleSize : Spacing.osdWidth
    property int _osdHeight: _isToggle ? Spacing.osdToggleSize : Spacing.osdHeight
    property bool _hCenter: posAnchor === "top" || posAnchor === "center" || posAnchor === "bottom" || posAnchor === "bottom-center"
    property bool _vCenter: posAnchor === "left" || posAnchor === "center" || posAnchor === "right"

    anchors {
        top: posAnchor.startsWith("top") || posAnchor === "center" || posAnchor === "left" || posAnchor === "right"
        bottom: posAnchor.startsWith("bottom")
        left: posAnchor.endsWith("left") || posAnchor === "top" || posAnchor === "center" || posAnchor === "bottom" || posAnchor === "bottom-center"
        right: posAnchor.endsWith("right")
    }

    margins {
        top: {
            if (posAnchor.startsWith("top"))
                return marginY + offsetY;
            if (_vCenter)
                return Math.round((osdWindow.screen.height - _osdHeight) / 2 + offsetY);
            return 0;
        }
        bottom: {
            if (posAnchor.startsWith("bottom"))
                return marginY - offsetY;
            return 0;
        }
        left: {
            if (posAnchor.endsWith("left"))
                return marginX + offsetX;
            if (_hCenter)
                return Math.round((osdWindow.screen.width - _osdWidth) / 2 + offsetX);
            return 0;
        }
        right: {
            if (posAnchor.endsWith("right"))
                return marginX - offsetX;
            return 0;
        }
    }

    implicitWidth: _osdWidth
    implicitHeight: _osdHeight

    color: "transparent"
    visible: true
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    mask: Region {}

    OsdContent {
        anchors.fill: parent
    }
}
