pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real percentage: 0
    property bool available: false

    // Track whether a write operation is in progress to avoid
    // ddcutil lock conflicts between concurrent get/set calls.
    property bool _writing: false

    // ── Polling control (consumer-visibility) ──
    property int _pollConsumers: 0
    readonly property bool pollingActive: _pollConsumers > 0

    function registerPollConsumer() {
        _pollConsumers++;
    }
    function unregisterPollConsumer() {
        _pollConsumers = Math.max(0, _pollConsumers - 1);
    }

    function getBrightnessIcon() {
        if (percentage < 14.3)
            return "󰃚";
        if (percentage < 28.6)
            return "󰃛";
        if (percentage < 42.9)
            return "󰃜";
        if (percentage < 57.1)
            return "󰃝";
        if (percentage < 71.4)
            return "󰃞";
        if (percentage < 85.7)
            return "󰃟";
        return "󰃠";
    }

    function setBrightness(pct) {
        if (!available)
            return;
        _writing = true;
        brightSet.brightArg = Math.round(pct).toString();
        brightSet.running = true;
    }

    function increaseBrightness() {
        if (!available)
            return;
        _writing = true;
        brightUp.running = true;
    }

    function decreaseBrightness() {
        if (!available)
            return;
        _writing = true;
        brightDown.running = true;
    }

    // ── Night light toggle ──
    // Right-click on brightness widget toggles gammastep.
    // Launches as a persistent Process; killing it reverts gamma automatically.
    function toggleNightLight() {
        nightProc.running = !nightProc.running;
    }

    Process {
        id: nightProc
        running: false
        command: ["gammastep"]
    }

    function _scheduleRefresh() {
        refreshDelay.start();
    }

    Process {
        id: checkBrightness
        running: true
        command: ["which", "brightness"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let output = data.toString().trim();
                    available = !!output;
                } catch (e) {
                    available = false;
                }
            }
        }
    }

    Timer {
        id: brightTimer
        interval: 2000
        running: root.pollingActive
        repeat: true
        triggeredOnStart: root.pollingActive
        onTriggered: {
            if (available && !_writing && !brightCheck.running) {
                brightCheck.running = true;
            }
        }
    }

    // Brief delay after a write operation before polling again,
    // giving ddcutil time to release its lock.
    Timer {
        id: refreshDelay
        interval: 500
        onTriggered: {
            _writing = false;
            if (available && !brightCheck.running) {
                brightCheck.running = true;
            }
        }
    }

    Process {
        id: brightCheck
        running: false
        command: ["brightness", "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let output = data.toString().trim();
                    if (!output)
                        return;
                    let val = parseInt(output);
                    if (!isNaN(val) && val >= 0 && val <= 100) {
                        root.percentage = val;
                        root.available = true;
                    } else {
                        root.available = false;
                    }
                } catch (e) {
                    root.available = false;
                }
            }
        }
    }

    Process {
        id: brightSet
        running: false
        property string brightArg: "50"
        command: ["brightness", "set", brightArg]
        onExited: _scheduleRefresh()
    }

    Process {
        id: brightUp
        running: false
        command: ["brightness", "increase", "5"]
        onExited: _scheduleRefresh()
    }

    Process {
        id: brightDown
        running: false
        command: ["brightness", "decrease", "5"]
        onExited: _scheduleRefresh()
    }
}
