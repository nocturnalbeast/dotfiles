pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []
    property string activeWindowTitle: ""
    property bool hasFullscreen: false  // Niri IPC has no fullscreen field
    property bool isWorkspaceEmpty: false

    property int _processed: 0
    property int _occupancyConsumers: 0
    readonly property bool trackOccupancy: _occupancyConsumers > 0

    function registerOccupancyConsumer() { _occupancyConsumers++; }
    function unregisterOccupancyConsumer() { _occupancyConsumers = Math.max(0, _occupancyConsumers - 1); }

    Component.onCompleted: {
        if (WmDetector.compositor !== "niri") return;
        eventStream.running = true;
    }

    // === Event stream (niri msg --json event-stream) ===
    // Events carry complete state inline — no separate polling needed.
    // Once this socket is open, it won't accept further requests, so
    // action commands (focusWorkspace via wmctl) use separate processes.
    Process {
        id: eventStream
        running: false
        command: ["niri", "msg", "--json", "event-stream"]
        stdout: StdioCollector {
            waitForEnd: false
            onDataChanged: {
                let full = data.toString();
                if (full.length < root._processed) root._processed = 0;
                let newData = full.substring(root._processed);
                root._processed = full.length;
                let lines = newData.split("\n");
                for (let i = 0; i < lines.length - 1; i++) {
                    let line = lines[i].trim();
                    if (!line) continue;
                    try {
                        root.handleEvent(JSON.parse(line));
                    } catch (e) {}
                }
            }
        }
    }

    function handleEvent(event) {
        // Events carry full state arrays — read directly, no re-poll
        if (event.WorkspacesChanged) {
            let wsl = event.WorkspacesChanged.workspaces || [];
            root.buildWorkspaces(wsl);
        }
        if (event.WindowsChanged) {
            let wins = event.WindowsChanged.windows || [];
            root.updateTitleFromWindows(wins);
        }
        if (event.WindowFocusChanged) {
            let title = event.WindowFocusChanged.title || "";
            root.activeWindowTitle = title;
        }
    }

    function buildWorkspaces(wsl) {
        let ws = [];
        for (let i = 0; i < wsl.length; i++) {
            let w = wsl[i];
            ws.push({
                name: (w.idx + 1).toString(),
                index: w.idx,
                occupied: true,  // niri workspaces auto-close when empty
                focused: !!w.is_active,
                urgent: false
            });
        }
        root.workspaces = ws;
        let activeWs = ws.find(w => w.focused);
        root.isWorkspaceEmpty = activeWs ? !activeWs.occupied : true;
    }

    function updateTitleFromWindows(wins) {
        let focused = wins.find(w => w.is_focused);
        root.activeWindowTitle = focused ? (focused.title || "") : "";
    }
}
