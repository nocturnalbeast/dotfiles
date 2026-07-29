pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    // Unified WM/compositor backend facade.
    // Dispatches all workspace, window-title, and fullscreen queries
    // to the active backend (EwmhService for X11, RiverService for Wayland).
    // Consumers should use WmBackend instead of checking WmDetector.isX11 directly.

    // === Workspace data ===
    readonly property var workspaces: WmDetector.isX11 ? EwmhService.workspaces : RiverService.workspaces

    // === Window title ===
    readonly property string focusedWindowTitle: WmDetector.isX11 ? EwmhService.activeWindowTitle : RiverService.activeWindowTitle

    // === Fullscreen detection ===
    readonly property bool hasFullscreen: WmDetector.isX11 ? EwmhService.hasFullscreen : false

    // === Workspace empty (current desktop) ===
    readonly property bool isWorkspaceEmpty: WmDetector.isX11 ? EwmhService.isWorkspaceEmpty : RiverService.isWorkspaceEmpty

    // === Occupancy consumer registration ===
    // Call register/unregister in Component.onCompleted/onDestruction
    // so the active backend can start/stop its occupancy polling.
    function registerOccupancyConsumer() {
        if (WmDetector.isX11)
            EwmhService.registerOccupancyConsumer();
        else
            RiverService.registerOccupancyConsumer();
    }

    function unregisterOccupancyConsumer() {
        if (WmDetector.isX11)
            EwmhService.unregisterOccupancyConsumer();
        else
            RiverService.unregisterOccupancyConsumer();
    }

    // === Workspace switching ===
    function focusWorkspace(index) {
        if (WmDetector.isX11)
            EwmhService.focusWorkspace(index);
        else
            RiverService.focusWorkspace(index);
    }

    // === Window cycling ===
    // direction: 1 = next, -1 = previous
    function cycleWindow(direction) {
        if (WmDetector.isX11)
            EwmhService.cycleWindow(direction);
        else
            RiverService.cycleWindow(direction);
    }

    // === Session logout ===
    // Delegates to menu-power for compositor detection and dispatch.
    // This avoids duplicating compositor-specific logout commands in QML.
    function logout() {
        Quickshell.execDetached(["menu-power", "logout"]);
    }
}
