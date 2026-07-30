pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var workspaces: []
    property string activeWindowTitle: ""
    property bool hasFullscreen: false
    property bool isWorkspaceEmpty: false

    property int _processed: 0
    property int _occupancyConsumers: 0
    readonly property bool trackOccupancy: _occupancyConsumers > 0

    function registerOccupancyConsumer() { _occupancyConsumers++; }
    function unregisterOccupancyConsumer() { _occupancyConsumers = Math.max(0, _occupancyConsumers - 1); }

    Component.onCompleted: {
        if (WmDetector.compositor !== "sway") return;
        eventStream.running = true;
        refreshWorkspaces();
    }

    // === Event stream (swaymsg subscribe) ===
    Process {
        id: eventStream
        running: false
        command: ["swaymsg", "-t", "subscribe", "-m", '["workspace","window","shutdown"]', "--monitor"]
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
        if (event.change === "shutdown") {
            eventStream.running = false;
            return;
        }
        if (event.type === "workspace") {
            if (event.change === "focus" || event.change === "init" || event.change === "empty") {
                root.refreshWorkspaces();
            }
        } else if (event.type === "window") {
            if (event.change === "focus") {
                let c = event.container;
                if (c && c.name) root.activeWindowTitle = c.name;
                root.hasFullscreen = c && c.fullscreen_mode === 1;
                root.refreshWorkspaces();
            } else if (event.change === "title") {
                let c = event.container;
                if (c && c.focused && c.name) root.activeWindowTitle = c.name;
            } else if (event.change === "fullscreen_mode") {
                let c = event.container;
                if (c && c.focused) root.hasFullscreen = c.fullscreen_mode === 1;
            }
        }
    }

    // === Workspace data polling ===
    Process {
        id: wsPoll
        running: false
        command: ["swaymsg", "-t", "get_workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.buildWorkspaces(JSON.parse(data.toString()));
                } catch (e) {}
            }
        }
    }

    function refreshWorkspaces() { wsPoll.running = true; }

    function buildWorkspaces(wsl) {
        let ws = [];
        for (let i = 0; i < wsl.length; i++) {
            let w = wsl[i];
            ws.push({
                name: w.name || w.num.toString(),
                index: w.num - 1,
                occupied: (w.windows || 0) > 0,
                focused: !!w.focused,
                urgent: !!w.urgent
            });
        }
        root.workspaces = ws;
        let activeWs = ws.find(w => w.focused);
        root.isWorkspaceEmpty = activeWs ? !activeWs.occupied : true;
    }
}
