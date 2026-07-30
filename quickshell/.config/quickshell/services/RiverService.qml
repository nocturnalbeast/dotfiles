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
    property bool hasFullscreen: false
    property var occupancyMap: ({})
    property bool isWorkspaceEmpty: false

    Component.onCompleted: {
        if (WmDetector.compositor !== "river") return;
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
        root.activeWorkspace = "1";
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

    // Poll occupancy only — focus tracking is impossible because
    // riverctl get-focused-tags does not exist (see river.md §4e).
    // Workspace focus state stays at the initial assumption (tag 1).
    Timer {
        running: WmDetector.compositor === "river"
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (root.trackOccupancy)
                occupancyCheck.running = true;
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
                root.updateOccupancy();
            }
        }
    }

    // Update occupancy on existing workspace array, preserving focus state.
    function updateOccupancy() {
        let ws = [];
        for (let i = 0; i < 10; i++) {
            ws.push({
                name: (i + 1).toString(),
                index: i,
                occupied: !!root.occupancyMap[i],
                focused: i === 0,  // tag 1 assumed focused
                urgent: false
            });
        }
        root.workspaces = ws;
        let activeWs = ws[0];
        root.isWorkspaceEmpty = activeWs ? !activeWs.occupied : true;
    }
}
