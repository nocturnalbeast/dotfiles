pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool daemonRunning: false
    property bool checking: false
    property bool available: false

    signal locked
    signal unlocked

    function lock() {
        lockProc.running = true;
        root.locked();
    }

    function startDaemon() {
        startProc.running = true;
        daemonRunning = true;
    }

    function stopDaemon() {
        stopProc.running = true;
        daemonRunning = false;
    }

    function refreshStatus() {
        checking = true;
        statusProc.running = true;
    }

    Process {
        id: checkProc
        running: true
        command: ["which", "lockctl"]
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
        onExited: {
            if (available)
                refreshStatus();
        }
    }

    Process {
        id: lockProc
        running: false
        command: ["lockctl", "lock"]
        onExited: root.unlocked()
    }

    Process {
        id: startProc
        running: false
        command: ["lockctl", "start"]
        onExited: refreshStatus()
    }

    Process {
        id: stopProc
        running: false
        command: ["lockctl", "stop"]
        onExited: refreshStatus()
    }

    Process {
        id: statusProc
        running: false
        command: ["lockctl", "status"]
        onExited: function (code) {
            daemonRunning = (code === 0);
            checking = false;
        }
    }
}
