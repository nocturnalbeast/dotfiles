import Quickshell
import QtQuick
import "../../theme"
import "../../services"

PanelWindow {
    id: clockWindow

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: false

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    // Empty input region — all mouse events pass through to
    // windows below (including the bar). Standard pattern for
    // fullscreen transparent PanelWindows (noctalia, dankmaterial).
    mask: Region {}

    Component.onCompleted: {
        WallpaperPlacement.registerPollConsumer();
        WallpaperPlacement.screenWidth = screen.width;
        WallpaperPlacement.screenHeight = screen.height;
        WmBackend.registerOccupancyConsumer();
    }
    Component.onDestruction: {
        WallpaperPlacement.unregisterPollConsumer();
        WmBackend.unregisterOccupancyConsumer();
    }

    // Only show when workspace is empty AND (placement is ready or AI placement is off)
    property bool _shouldShow: WmBackend.isWorkspaceEmpty && (!WallpaperPlacement.useAiPlacement || WallpaperPlacement.placement !== null)
    visible: _shouldShow

    DesktopClockFace {
        id: clockFace
        anchors.fill: parent
        fadeIn: clockWindow._shouldShow
    }
}
