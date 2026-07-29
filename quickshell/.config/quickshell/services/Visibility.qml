pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    // ═══════════════════════════════════════════
    // BAR POPUPS (mutual exclusion group)
    // ═══════════════════════════════════════════

    // The currently open bar popup (BarPopup Loader)
    property var activeBarPopup: null

    // Open a popup, closing any currently open one first
    function openBarPopup(popup) {
        if (root.activeBarPopup !== null && root.activeBarPopup !== popup) {
            root.activeBarPopup.close();
        }
        root.activeBarPopup = popup;
        if (!popup.active) {
            popup.active = true;
        }
        root._lastActiveWindowId = EwmhService.activeWindowId;
    }

    // Close a specific popup (uses BarPopup.close() for animation)
    function closeBarPopup(popup) {
        popup.close();
        if (root.activeBarPopup === popup) {
            root.activeBarPopup = null;
        }
    }

    // Close the currently active bar popup
    function closeAllBarPopups() {
        if (root.activeBarPopup !== null) {
            root.activeBarPopup.close();
            root.activeBarPopup = null;
        }
    }

    // Toggle: open if closed, close if open (mutual exclusion)
    function toggleBarPopup(popup) {
        if (popup.active) {
            root.closeBarPopup(popup);
        } else {
            root.openBarPopup(popup);
        }
    }

    // Register a popup (called by BarPopup.onActiveChanged)
    // Ensures only one popup is registered at a time
    function registerBarPopup(popup) {
        if (root.activeBarPopup !== null && root.activeBarPopup !== popup) {
            root.activeBarPopup.close();
        }
        root.activeBarPopup = popup;
        root._lastActiveWindowId = EwmhService.activeWindowId;
    }

    // ═══════════════════════════════════════════
    // BAR STATE (active layout, manual hide/switch)
    // ═══════════════════════════════════════════

    property int activeBar: 0  // 0 = mainbar, 1 = monbar

    // Manual hide state — set via IPC hideBar/showBar/toggleBar.
    // Orthogonal to fullscreen auto-hide; bar hides if either is true.
    property bool manualHidden: false

    function switchBar() {
        root.activeBar = root.activeBar === 0 ? 1 : 0;
    }

    // Calendar month offset — scrolled from ClockWidget, watched by CalendarPopup.
    // Resets to 0 when CalendarPopup opens (resyncs to current month).
    property int calendarMonthOffset: 0

    // ═══════════════════════════════════════════
    // OSD STATE (auto-dismiss, no mutual exclusion needed)
    // ═══════════════════════════════════════════

    property string activeOsd: OsdManager.activeType

    function showOsd(type) {
        // Kept for compatibility; actual show logic is in OsdManager via Connections
    }

    function dismissOsd() {
        OsdManager.dismiss();
    }

    // ═══════════════════════════════════════════
    // FUTURE PANELS (stubs for extension)
    // ═══════════════════════════════════════════

    property bool launcherOpen: false
    property bool controlCenterOpen: false
    property bool notificationPanelOpen: false
    property bool sessionOpen: SessionService.open

    // ═══════════════════════════════════════════
    // GLOBAL ACTIONS
    // ═══════════════════════════════════════════

    // Close everything
    function closeAll() {
        SessionService.close();
        root.closeAllBarPopups();
        OsdManager.dismiss();
        root.launcherOpen = false;
        root.controlCenterOpen = false;
        root.notificationPanelOpen = false;
    }

    // Called on external focus (click-outside-to-close)
    function onExternalFocus() {
        root.closeAll();
    }

    // Escape key: close top-most panel
    function handleEscape() {
        // Priority: session > bar popups > OSD > other panels
        if (SessionService.open) {
            SessionService.close();
        } else if (root.activeBarPopup !== null) {
            root.closeAllBarPopups();
        } else if (OsdManager.activeType !== "") {
            OsdManager.dismiss();
        } else if (root.notificationPanelOpen) {
            root.notificationPanelOpen = false;
        } else if (root.controlCenterOpen) {
            root.controlCenterOpen = false;
        } else if (root.launcherOpen) {
            root.launcherOpen = false;
        }
    }

    // ═══════════════════════════════════════════
    // ACTIVE WINDOW MONITORING (X11 click-outside)
    // ═══════════════════════════════════════════

    property string _lastActiveWindowId: ""

    Timer {
        id: focusDebounce
        interval: 100
        onTriggered: {
            if (root.activeBarPopup !== null) {
                root.closeAllBarPopups();
            }
        }
    }

    Connections {
        enabled: WmDetector.isX11
        target: EwmhService
        function onActiveWindowIdChanged() {
            if (root.activeBarPopup === null)
                return;
            if (EwmhService.activeWindowId === root._lastActiveWindowId)
                return;
            root._lastActiveWindowId = EwmhService.activeWindowId;
            focusDebounce.restart();
        }
    }
}
