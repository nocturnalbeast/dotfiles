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

    // Input mask matching the clock's visual content (clockContent).
    // The previous `mask: Region {}` (empty region → full click-through)
    // never becomes an effective empty X input region on X11: quickshell's
    // empty-mask path depends on the expose/polish → WindowTransparentForInput
    // → XFixes chain, which fails for windows that map at runtime. Result: the
    // fullscreen window swallowed ALL clicks (including the bar's) whenever
    // the workspace was empty. A non-empty mask rides the reliable rule that
    // an unset input shape tracks the bounding shape: input is confined to the
    // clock glyphs, everything else (the whole bar strip included) passes
    // through to windows below. DesktopClockFace exposes innerItem for this.
    mask: Region { item: clockFace.innerItem }

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
