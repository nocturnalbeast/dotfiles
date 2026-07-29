pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Placement result from wallpaper analysis: { center_x, center_y, dominant_color }
    // null until analysis completes or if analysis fails
    property var placement: null

    property string wallpaperPath: ""

    property bool useAiPlacement: true

    property string strategy: "leastBusy"

    // ─── Polling control (consumer-visibility) ──────────
    property int _pollConsumers: 0
    readonly property bool pollingActive: _pollConsumers > 0

    function registerPollConsumer() {
        _pollConsumers++;
    }
    function unregisterPollConsumer() {
        _pollConsumers = Math.max(0, _pollConsumers - 1);
    }

    // Screen dimensions for pixel-to-percent conversion
    // Set by DesktopClock.qml on Component.onCompleted
    property int screenWidth: 1920
    property int screenHeight: 1080

    // Watch the wallpaper symlink for changes
    Process {
        id: readLinkProc
        running: false
        command: ["sh", "-c", "readlink -f ~/.config/wm/current_wallpaper 2>/dev/null || echo ''"]
        stdout: StdioCollector {
            onStreamFinished: {
                let path = data.toString().trim();
                if (path && path !== root.wallpaperPath) {
                    root.wallpaperPath = path;
                    analyzeProc.running = true;
                }
            }
        }
    }

    // Run wallpaper analysis via uv + opencv
    Process {
        id: analyzeProc
        running: false
        command: ["uv", "run", Quickshell.env("HOME") + "/.config/quickshell/scripts/wallpaper-placement.py", root.wallpaperPath, "--screen-width", root.screenWidth.toString(), "--screen-height", root.screenHeight.toString(), "--width", "400", "--height", "200"].concat(root.strategy === "mostBusy" ? ["--busiest"] : [])
        stdout: StdioCollector {
            onStreamFinished: {
                let output = data.toString().trim();
                if (!output || output.startsWith('{"error')) {
                    root.placement = null;
                    return;
                }
                try {
                    let parsed = JSON.parse(output);
                    // Convert absolute pixel coords to screen percentages
                    if (root.screenWidth > 0 && root.screenHeight > 0) {
                        parsed.center_x_pct = parsed.center_x / root.screenWidth * 100;
                        parsed.center_y_pct = parsed.center_y / root.screenHeight * 100;
                    }
                    root.placement = parsed;
                } catch (e) {
                    root.placement = null;
                }
            }
        }
    }

    // Poll for wallpaper changes every 10 seconds
    Timer {
        interval: 10000
        running: root.pollingActive
        repeat: true
        triggeredOnStart: root.pollingActive
        onTriggered: readLinkProc.running = true
    }
}
