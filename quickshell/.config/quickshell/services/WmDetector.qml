pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Detect X11 vs Wayland via environment variables
    // $XDG_SESSION_TYPE is set by display managers; fallback to $DISPLAY/$WAYLAND_DISPLAY
    readonly property bool isX11: Quickshell.env("XDG_SESSION_TYPE") === "x11" || (Quickshell.env("DISPLAY") !== null && Quickshell.env("WAYLAND_DISPLAY") === null)
    readonly property bool isWayland: Quickshell.env("XDG_SESSION_TYPE") === "wayland" || Quickshell.env("WAYLAND_DISPLAY") !== null

    // Detect the specific compositor
    readonly property string compositor: {
        if (isX11) return "x11";
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") !== null) return "hyprland";
        if (Quickshell.env("SWAYSOCK") !== null) return "sway";
        var desktop = Quickshell.env("XDG_CURRENT_DESKTOP") || "";
        if (desktop.indexOf("river") !== -1) return "river";
        if (desktop.indexOf("niri") !== -1) return "niri";
        if (desktop.indexOf("somewm") !== -1) return "somewm";
        return "";
    }

    // Detect specific WM name on X11 via EWMH _NET_SUPPORTING_WM_CHECK
    property string _wmName: ""
    readonly property string wmName: _wmName

    // Convenience: true only when running bspwm specifically
    readonly property bool isBspwm: isX11 && wmName === "bspwm"

    // Unified workspace empty detection — delegated to WmBackend facade
    readonly property bool isWorkspaceEmpty: WmBackend.isWorkspaceEmpty

    Process {
        id: wmNameCheck
        running: false
        command: ["sh", "-c", "WM_CHECK=$(xprop -root _NET_SUPPORTING_WM_CHECK 2>/dev/null | sed 's/.*# //'); [ -n \"$WM_CHECK\" ] && xprop -id \"$WM_CHECK\" _NET_WM_NAME 2>/dev/null | sed 's/.*= //;s/\"//g'"]
        stdout: StdioCollector {
            onStreamFinished: {
                let name = data.toString().trim();
                if (name)
                    root._wmName = name;
            }
        }
    }

    Component.onCompleted: {
        if (root.isX11)
            wmNameCheck.running = true;
    }

    function focusWorkspace(index) {
        WmBackend.focusWorkspace(index);
    }
}
