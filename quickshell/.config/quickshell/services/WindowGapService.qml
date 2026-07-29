pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Default gap value; overridden by WM-specific queries
    property int windowGap: 10

    // ─── Polling control (consumer-visibility) ──────────
    property int _pollConsumers: 0
    readonly property bool pollingActive: _pollConsumers > 0

    function registerPollConsumer() {
        _pollConsumers++;
    }
    function unregisterPollConsumer() {
        _pollConsumers = Math.max(0, _pollConsumers - 1);
    }

    // ─── bspwm: query window_gap via bspc ───
    Process {
        id: bspcGapProc
        running: false
        command: ["bspc", "config", "window_gap"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(data.toString().trim());
                if (!isNaN(val))
                    root.windowGap = val;
            }
        }
    }

    Timer {
        running: WmDetector.isBspwm && root.pollingActive
        interval: 10000
        repeat: true
        triggeredOnStart: root.pollingActive
        onTriggered: bspcGapProc.running = true
    }

    // ─── spectrwm: read region_padding from config file ───
    // Spectrwm doesn't have a CLI query tool — values are static in config.
    // region_padding = N is the equivalent of bspwm's window_gap.
    Process {
        id: spectrwmGapProc
        running: false
        command: ["sh", "-c", "grep -E '^\\s*region_padding\\s*=' \"${XDG_CONFIG_HOME:-$HOME/.config}/spectrwm/spectrwm.conf\" 2>/dev/null | sed 's/.*=\\s*//'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var val = parseInt(data.toString().trim());
                if (!isNaN(val))
                    root.windowGap = val;
            }
        }
    }

    Timer {
        running: WmDetector.wmName === "spectrwm" && root.pollingActive
        interval: 30000
        repeat: true
        triggeredOnStart: root.pollingActive
        onTriggered: spectrwmGapProc.running = true
    }
}
