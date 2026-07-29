pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []
    property string activeWorkspace: "1"
    property string activeWindowTitle: ""
    property int workspaceCount: 10
    property int focusedTags: 0
    property bool connected: false
    property var occupancyMap: ({})
    property bool isWorkspaceEmpty: false

    Component.onCompleted: {
        initializeWorkspaces();
    }

    function initializeWorkspaces() {
        let ws = [];
        for (let i = 1; i <= 10; i++) {
            ws.push({
                name: i.toString(),
                index: i - 1,
                occupied: false,
                focused: i === 1,
                urgent: false
            });
        }
        root.workspaces = ws;
        root.workspaceCount = 10;
        root.activeWorkspace = "1";
        root.connected = true;
    }

    // Polling control for occupancy (desktop clock)
    property int _occupancyConsumers: 0
    readonly property bool trackOccupancy: _occupancyConsumers > 0

    function registerOccupancyConsumer() {
        _occupancyConsumers++;
    }
    function unregisterOccupancyConsumer() {
        _occupancyConsumers = Math.max(0, _occupancyConsumers - 1);
    }

    // Poll river state periodically
    Timer {
        running: WmDetector.isWayland
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            focusCheck.running = true;
            if (root.trackOccupancy)
                occupancyCheck.running = true;
        }
    }

    Process {
        id: focusCheck
        running: false
        command: ["riverctl", "get-focused-tags"]
        stdout: StdioCollector {
            onStreamFinished: {
                let output = data.toString().trim();
                let focusedValue = parseInt(output);
                if (!isNaN(focusedValue) && focusedValue !== root.focusedTags) {
                    root.focusedTags = focusedValue;
                    updateWorkspaces();
                }
            }
        }
    }

    Process {
        id: occupancyCheck
        running: false
        command: ["lswt"]
        stdout: StdioCollector {
            onStreamFinished: {
                let output = data.toString().trim();
                if (!output)
                    return;
                let map = {};
                let lines = output.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let match = lines[i].match(/tags:\s*(\d+)/);
                    if (match) {
                        let tagMask = parseInt(match[1]);
                        if (isNaN(tagMask))
                            continue;
                        for (let t = 0; t < 10; t++) {
                            if (tagMask & (1 << t))
                                map[t] = true;
                        }
                    }
                }
                root.occupancyMap = map;
                root.updateWorkspaces();
            }
        }
    }

    function updateWorkspaces() {
        let ws = [];
        let foundActive = false;
        for (let i = 0; i < 10; i++) {
            let tagBit = Math.pow(2, i);
            let focused = (root.focusedTags & tagBit) !== 0;
            ws.push({
                name: (i + 1).toString(),
                index: i,
                occupied: !!root.occupancyMap[i],
                focused: focused,
                urgent: false
            });
            if (focused && !foundActive) {
                root.activeWorkspace = (i + 1).toString();
                foundActive = true;
            }
        }
        root.workspaces = ws;
        // Update isWorkspaceEmpty
        let activeWs = ws.find(w => w.focused);
        root.isWorkspaceEmpty = activeWs ? !activeWs.occupied : true;
    }

    Process {
        id: riverFocusProc
        running: false
        property int targetTag: 0
        command: ["riverctl", "set-focused-tags", "" + Math.pow(2, targetTag)]
    }

    function focusWorkspace(index) {
        riverFocusProc.targetTag = index;
        riverFocusProc.running = true;
    }

    // === Window cycling ===
    Process {
        id: riverCycleProc
        running: false
        property string cycleDir: "next"
        command: ["riverctl", "focus-view", cycleDir]
    }

    function cycleWindow(direction) {
        riverCycleProc.cycleDir = direction > 0 ? "next" : "previous";
        riverCycleProc.running = true;
    }
}
