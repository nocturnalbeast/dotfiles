pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string layout: "US"

    // ─── Polling control (consumer-visibility) ──────────
    property int _pollConsumers: 0
    readonly property bool pollingActive: _pollConsumers > 0

    function registerPollConsumer() {
        _pollConsumers++;
    }
    function unregisterPollConsumer() {
        _pollConsumers = Math.max(0, _pollConsumers - 1);
    }

    Timer {
        interval: 2000
        running: root.pollingActive
        repeat: true
        triggeredOnStart: root.pollingActive
        onTriggered: layoutProc.running = true
    }

    Process {
        id: layoutProc

        running: false
        command: ["setxkbmap", "-query"]

        stdout: StdioCollector {
            onStreamFinished: {
                var output = data.toString();
                var match = output.match(/layout:\s*(\S+)/);
                if (match)
                    root.layout = match[1].toUpperCase();
            }
        }
    }
}
