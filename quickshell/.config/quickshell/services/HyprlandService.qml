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
        if (WmDetector.compositor !== "hyprland") return;
        eventStream.running = true;
        refreshWorkspaces();
    }

    // === Event stream (socket2 via socat) ===
    Process {
        id: eventStream
        running: false
        command: ["socat", "-u",
            "UNIX-CONNECT:" + Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" +
            Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket2.sock", "-"]
        stdout: StdioCollector {
            waitForEnd: false
            onDataChanged: {
                let full = data.toString();
                if (full.length < root._processed) root._processed = 0;
                let newData = full.substring(root._processed);
                root._processed = full.length;
                let lines = newData.split("\n");
                for (let i = 0; i < lines.length - 1; i++) {
                    root.handleEvent(lines[i].trim());
                }
            }
        }
    }

    function handleEvent(line) {
        if (line.startsWith("workspace>>") || line.startsWith("focusedmon>>")) {
            root.refreshWorkspaces();
        } else if (line.startsWith("activewindow>>")) {
            let parts = line.substring("activewindow>>".length).split(",");
            root.activeWindowTitle = parts.length >= 2 ? parts[1].trim() : "";
        } else if (line.startsWith("fullscreen>>")) {
            root.hasFullscreen = line.substring("fullscreen>>".length).trim() === "1";
        } else if (line.startsWith("openwindow>>") || line.startsWith("closewindow>>")) {
            if (root.trackOccupancy) root.refreshWorkspaces();
        }
    }

    // === Workspace data polling ===
    Process {
        id: wsPoll
        running: false
        command: ["sh", "-c",
            "echo '{\"workspaces\":'$(hyprctl workspaces -j)',\"active\":'$(hyprctl activeworkspace -j)'}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let combined = JSON.parse(data.toString());
                    root.buildWorkspaces(combined.workspaces || [], combined.active || {});
                } catch (e) {}
            }
        }
    }

    function refreshWorkspaces() { wsPoll.running = true; }

    function buildWorkspaces(wsl, active) {
        let ws = [];
        let activeId = active.id || -1;
        let sorted = wsl.sort((a, b) => a.id - b.id);
        for (let i = 0; i < sorted.length; i++) {
            let w = sorted[i];
            ws.push({
                name: w.name || w.id.toString(),
                index: i,
                occupied: (w.windows || 0) > 0,
                focused: w.id === activeId,
                urgent: false
            });
        }
        root.workspaces = ws;
        let activeWs = ws.find(w => w.focused);
        root.isWorkspaceEmpty = activeWs ? !activeWs.occupied : true;
        if (active.title) root.activeWindowTitle = active.title;
    }
}
