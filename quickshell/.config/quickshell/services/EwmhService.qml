pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // === Workspace data ===
    property var workspaces: []
    property int workspaceCount: 0
    property string activeWorkspace: ""
    property int currentDesktop: 0
    property bool isWorkspaceEmpty: false

    // === Window data ===
    property string activeWindowTitle: ""
    property string activeWindowId: ""

    // === Fullscreen ===
    property bool hasFullscreen: false

    // === Root property spy ===
    // Streams _NET_CURRENT_DESKTOP, _NET_ACTIVE_WINDOW, _NET_DESKTOP_NAMES,
    // _NET_NUMBER_OF_DESKTOPS changes in real-time
    property int _rootSpyProcessed: 0

    Process {
        id: rootSpy
        running: false
        command: ["xprop", "-root", "-spy", "_NET_CURRENT_DESKTOP", "_NET_ACTIVE_WINDOW", "_NET_DESKTOP_NAMES", "_NET_NUMBER_OF_DESKTOPS"]
        stdout: StdioCollector {
            waitForEnd: false
            onDataChanged: {
                let full = data.toString();
                if (full.length < root._rootSpyProcessed) {
                    root._rootSpyProcessed = 0;
                }
                let newData = full.substring(root._rootSpyProcessed);
                root._rootSpyProcessed = full.length;

                let lines = newData.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line === "")
                        continue;
                    root.handleRootEvent(line);
                }
            }
        }
    }

    function handleRootEvent(line) {
        if (line.startsWith("_NET_CURRENT_DESKTOP(CARDINAL)")) {
            let val = parseInt(line.split("= ")[1]);
            if (!isNaN(val)) {
                root.currentDesktop = val;
                root.rebuildWorkspaces();
            }
        } else if (line.startsWith("_NET_ACTIVE_WINDOW(WINDOW)")) {
            // Format: _NET_ACTIVE_WINDOW(WINDOW): window id # 0x12345
            let match = line.match(/window id # (0x[0-9a-fA-F]+)/);
            if (match) {
                root.activeWindowId = match[1];
                root.startWindowSpy(match[1]);
                root.checkFullscreen(match[1]);
                occupancyProc.running = true;
            }
        } else if (line.startsWith("_NET_DESKTOP_NAMES(UTF8_STRING)")) {
            root.parseDesktopNames(line);
        } else if (line.startsWith("_NET_NUMBER_OF_DESKTOPS(CARDINAL)")) {
            let val = parseInt(line.split("= ")[1]);
            if (!isNaN(val)) {
                root.workspaceCount = val;
                root.rebuildWorkspaces();
            }
        }
    }

    // === Desktop names ===
    property var desktopNames: []

    function parseDesktopNames(line) {
        // Format: _NET_DESKTOP_NAMES(UTF8_STRING) = "main", "inet", "code", ...
        let raw = line.split("= ")[1] || "";
        let names = [];
        // Split by ", " and strip quotes
        let parts = raw.split(", ");
        for (let i = 0; i < parts.length; i++) {
            let name = parts[i].replace(/"/g, "").trim();
            if (name.length > 0)
                names.push(name);
        }
        root.desktopNames = names;
        root.workspaceCount = names.length;
        root.rebuildWorkspaces();
    }

    // === Workspace occupancy (polled) ===
    property var occupancyMap: ({})

    // Polling control: only needed for desktop clock's isWorkspaceEmpty
    property int _occupancyConsumers: 0
    readonly property bool trackOccupancy: _occupancyConsumers > 0

    function registerOccupancyConsumer() {
        _occupancyConsumers++;
    }
    function unregisterOccupancyConsumer() {
        _occupancyConsumers = Math.max(0, _occupancyConsumers - 1);
    }

    Timer {
        interval: 3000
        running: WmDetector.isX11 && root.trackOccupancy
        repeat: true
        triggeredOnStart: root.trackOccupancy
        onTriggered: occupancyProc.running = true
    }

    Process {
        id: occupancyProc
        running: false
        command: ["sh", "-c", "xprop -root _NET_CLIENT_LIST 2>/dev/null | " + "sed 's/.*# //' | tr ', ' '\\n' | while read wid; do " + "wid=$(echo $wid | tr -d ' '); " + "[ -z \"$wid\" ] && continue; " + "desktop=$(xprop -id \"$wid\" _NET_WM_DESKTOP 2>/dev/null | sed 's/.*= //'); " + "echo \"$wid $desktop\"; " + "done"]
        stdout: StdioCollector {
            onStreamFinished: {
                let output = data.toString();
                let map = {};
                let lines = output.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].trim().split(" ");
                    if (parts.length >= 2) {
                        let desktop = parseInt(parts[parts.length - 1]);
                        if (!isNaN(desktop)) {
                            map[desktop] = true;
                        }
                    }
                }
                root.occupancyMap = map;
                root.rebuildWorkspaces();
            }
        }
    }

    // === Rebuild workspaces array ===
    function rebuildWorkspaces() {
        let ws = [];
        let count = root.workspaceCount;
        let names = root.desktopNames;
        for (let i = 0; i < count; i++) {
            ws.push({
                name: (names && names[i]) ? names[i] : (i + 1).toString(),
                index: i,
                occupied: !!root.occupancyMap[i],
                focused: i === root.currentDesktop,
                urgent: false
            });
        }
        root.workspaces = ws;
        root.isWorkspaceEmpty = (root.currentDesktop >= 0 && root.currentDesktop < ws.length) ? !root.occupancyMap[root.currentDesktop] : false;
        if (root.currentDesktop >= 0 && root.currentDesktop < ws.length) {
            root.activeWorkspace = ws[root.currentDesktop].name;
        }
    }

    // === Window title spy ===
    // Spawns xprop -spy on the active window for _NET_WM_NAME
    property int _windowSpyProcessed: 0

    Process {
        id: windowSpy
        running: false
        command: ["xprop", "-id", root.activeWindowId, "-spy", "_NET_WM_NAME", "_NET_WM_STATE"]
        stdout: StdioCollector {
            waitForEnd: false
            onDataChanged: {
                let full = data.toString();
                if (full.length < root._windowSpyProcessed) {
                    root._windowSpyProcessed = 0;
                }
                let newData = full.substring(root._windowSpyProcessed);
                root._windowSpyProcessed = full.length;

                let lines = newData.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    let line = lines[i].trim();
                    if (line.startsWith("_NET_WM_NAME(UTF8_STRING)")) {
                        let raw = line.split("= ")[1] || "";
                        root.activeWindowTitle = raw.replace(/"/g, "");
                    } else if (line.startsWith("_NET_WM_STATE(ATOM)")) {
                        root.hasFullscreen = line.includes("_NET_WM_STATE_FULLSCREEN");
                    }
                }
            }
        }
    }

    function startWindowSpy(wid) {
        if (!wid || wid === "0x0") {
            root.activeWindowTitle = "";
            root._lastSpyWid = "0x0";
            windowSpy.running = false;
            return;
        }
        // Debounce: only restart if window actually changed
        if (wid === root._lastSpyWid)
            return;
        root._lastSpyWid = wid;
        root._windowSpyProcessed = 0;
        windowSpy.running = false;
        windowSpyTimer.restart();
    }

    property string _lastSpyWid: ""

    Timer {
        id: windowSpyTimer
        interval: 100
        onTriggered: {
            if (root.activeWindowId && root.activeWindowId !== "0x0") {
                windowSpy.command = ["xprop", "-id", root.activeWindowId, "-spy", "_NET_WM_NAME", "_NET_WM_STATE"];
                windowSpy.running = true;
            }
        }
    }

    // === Fullscreen detection ===
    function checkFullscreen(wid) {
        if (!wid || wid === "0x0") {
            root.hasFullscreen = false;
            return;
        }
        fsCheckProc.running = false;
        fsCheckProc.command = ["xprop", "-id", wid, "_NET_WM_STATE"];
        fsCheckProc.running = true;
    }

    Process {
        id: fsCheckProc
        running: false
        command: ["xprop", "-id", "0x0", "_NET_WM_STATE"]
        stdout: StdioCollector {
            onStreamFinished: {
                let output = data.toString();
                root.hasFullscreen = output.includes("_NET_WM_STATE_FULLSCREEN");
            }
        }
    }

    // === Workspace switching ===
    Process {
        id: switchProc
        running: false
        property int targetDesktop: 0
        command: ["wmctrl", "-s", targetDesktop.toString()]
    }

    function focusWorkspace(index) {
        switchProc.targetDesktop = index;
        switchProc.running = true;
    }

    // === Window cycling ===
    // Delegates to wmctl which handles compositor-specific window cycling.
    Process {
        id: cycleWinProc
        running: false
        command: ["sh", "-c", ""]
    }

    function cycleWindow(direction) {
        cycleWinProc.command = ["wmctl", "window", "cycle", direction > 0 ? "next" : "prev"];
        cycleWinProc.running = true;
    }

    // === Initial data fetch ===
    Component.onCompleted: {
        console.log("EwmhService: Component.onCompleted");
        if (WmDetector.isX11) {
            initNamesProc.running = true;
            rootSpy.running = true;
        }
    }

    Process {
        id: initNamesProc
        running: false
        command: ["xprop", "-root", "_NET_DESKTOP_NAMES", "_NET_NUMBER_OF_DESKTOPS", "_NET_CURRENT_DESKTOP", "_NET_ACTIVE_WINDOW"]
        stdout: StdioCollector {
            onStreamFinished: {
                let output = data.toString();
                let lines = output.split("\n");
                for (let i = 0; i < lines.length; i++) {
                    root.handleRootEvent(lines[i].trim());
                }
            }
        }
    }
}
