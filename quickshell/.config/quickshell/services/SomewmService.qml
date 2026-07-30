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
        if (WmDetector.compositor !== "somewm") return;
        eventStream.running = true;
        refreshState();
    }

    // === Event stream (somewm-client --subscribe) ===
    Process {
        id: eventStream
        running: false
        command: ["somewm-client", "--subscribe"]
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
                    root.handleEvent(line);
                }
            }
        }
    }

    function handleEvent(event) {
        // Somewm events are plain text identifiers
        if (event === "tag_switch" || event === "tag_focus") {
            root.refreshState();
        } else if (event === "client_focus") {
            root.refreshTitle();
        } else if (event === "client_manage" || event === "client_unmanage") {
            if (root.trackOccupancy) root.refreshState();
        }
    }

    // === State polling (tag list + tag current) ===
    Process {
        id: tagPoll
        running: false
        command: ["sh", "-c",
            "echo 'tags:'$(somewm-client tag list 2>/dev/null); " +
            "echo 'current:'$(somewm-client tag current 2>/dev/null)"]
        stdout: StdioCollector {
            onStreamFinished: {
                let output = data.toString();
                let tagLine = (output.match(/tags:(.*)/) || [])[1] || "";
                let curLine = (output.match(/current:(.*)/) || [])[1] || "1";
                let currentTag = parseInt(curLine.trim().split(",")[0]) || 1;
                root.buildWorkspaces(tagLine.trim(), currentTag);
            }
        }
    }

    function refreshState() { tagPoll.running = true; }

    // === Title polling ===
    Process {
        id: titlePoll
        running: false
        command: ["sh", "-c",
            "somewm-client client list 2>/dev/null | head -1 | sed -n 's/.*title=\"\\([^\"]*\\)\".*/\\1/p'"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.activeWindowTitle = data.toString().trim();
            }
        }
    }

    function refreshTitle() { titlePoll.running = true; }

    function buildWorkspaces(tagList, currentTag) {
        // Parse tag list lines: "1: tag_name [active]" or similar
        let ws = [];
        let lines = tagList.split("\n");
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim();
            if (!line) continue;
            let match = line.match(/^(\d+):\s*(.+)/);
            if (!match) continue;
            let idx = parseInt(match[1]);
            let name = match[2].replace(/\s*\[.*\].*/, "").trim() || ("tag" + idx);
            ws.push({
                name: name,
                index: idx - 1,
                occupied: false,  // requires client list correlation
                focused: idx === currentTag,
                urgent: false
            });
        }
        // If no tags parsed, fall back to 9 tags
        if (ws.length === 0) {
            for (let i = 1; i <= 9; i++) {
                ws.push({
                    name: "tag" + i,
                    index: i - 1,
                    occupied: false,
                    focused: i === currentTag,
                    urgent: false
                });
            }
        }
        root.workspaces = ws;
        let activeWs = ws.find(w => w.focused);
        root.isWorkspaceEmpty = activeWs ? !activeWs.occupied : true;
    }
}
