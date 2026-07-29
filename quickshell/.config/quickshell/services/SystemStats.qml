pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../components"

Singleton {
    id: root

    // ─── CPU ─────────────────────────────────────
    property real cpuPercent: 0
    property var coreLoads: []
    property real cpuFrequency: 0  // MHz

    // ─── Memory ──────────────────────────────────
    property string memoryUsed: ""
    property string memoryTotal: ""
    property real memoryPercent: 0
    property string swapUsed: ""
    property string swapTotal: ""
    property real swapPercent: 0

    // ─── Temperature ─────────────────────────────
    property real temperature: 0

    // ─── Extra ───────────────────────────────────
    property string loadAverage: ""   // "0.52 0.58 0.59"
    property string uptimeText: ""    // "3d 14h 22m"

    // ─── Internal state ──────────────────────────
    property var prevCpuActive: []
    property var prevCpuIdle: []
    property string thermalZonePath: ""  // auto-detected

    // ─── Auto-detect thermal zone on startup ─────
    Component.onCompleted: {
        thermalDetect.running = true;
    }

    // One-shot process: scan hwmon then thermal_zone for CPU temp sensor
    Process {
        id: thermalDetect
        running: false
        command: ["bash", "-c", "for i in /sys/class/hwmon/hwmon*/name; do " + "[ -f \"$i\" ] || continue; " + "name=$(cat \"$i\" 2>/dev/null); " + "case \"$name\" in " + "coretemp|k10temp|zenpower) " + "dir=\"${i%/*}\"; " + "[ -f \"$dir/temp1_input\" ] && { echo \"hwmon:$dir/temp1_input\"; exit 0; } " + ";; esac; " + "done; " + "for i in /sys/class/thermal/thermal_zone*/type; do " + "[ -f \"$i\" ] || continue; " + "type=$(cat \"$i\" 2>/dev/null); " + "case \"$type\" in " + "x86_pkg_temp|cpu_thermal|TCPU|cpu*-thermal|soc-thermal) " + "dir=\"${i%/*}\"; " + "[ -f \"$dir/temp\" ] && { echo \"zone:$dir/temp\"; exit 0; } " + ";; esac; " + "done; " + "echo \"zone:/sys/class/thermal/thermal_zone0/temp\""]
        stdout: StdioCollector {
            onStreamFinished: {
                var output = data.toString().trim();
                if (output.startsWith("hwmon:") || output.startsWith("zone:"))
                    root.thermalZonePath = output.split(":").slice(1).join(":");
                else
                    root.thermalZonePath = "/sys/class/thermal/thermal_zone0/temp";
            }
        }
    }

    // ─── Polling control (consumer-visibility) ──
    property int _pollConsumers: 0
    readonly property bool pollingActive: _pollConsumers > 0

    function registerPollConsumer() {
        _pollConsumers++;
    }
    function unregisterPollConsumer() {
        _pollConsumers = Math.max(0, _pollConsumers - 1);
    }

    // ─── Timer — 2s polling interval ─────────────
    Timer {
        id: statsTimer
        interval: 2000
        running: root.pollingActive
        repeat: true
        triggeredOnStart: root.pollingActive
        onTriggered: {
            cpuFile.reload();
            meminfoFile.reload();
            if (root.thermalZonePath)
                tempFile.reload();
            loadavgFile.reload();
            uptimeFile.reload();
            freqFile.reload();
        }
    }

    // ─── CPU — /proc/stat ────────────────────────
    FileView {
        id: cpuFile
        path: "/proc/stat"
        onLoaded: {
            try {
                var text = cpuFile.text();
                var lines = text.split("\n");
                var active = [];
                var idle = [];
                for (var i = 0; i < lines.length; i++) {
                    var match = lines[i].match(/^cpu(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/);
                    if (match) {
                        var a = parseInt(match[2]) + parseInt(match[3]) + parseInt(match[4]);
                        var idl = parseInt(match[5]);
                        active.push(a);
                        idle.push(idl);
                    }
                }
                if (root.prevCpuActive.length === active.length && active.length > 0) {
                    var loads = [];
                    var totalPct = 0;
                    for (var j = 0; j < active.length; j++) {
                        var dActive = active[j] - root.prevCpuActive[j];
                        var dIdle = idle[j] - root.prevCpuIdle[j];
                        var dTotal = dActive + dIdle;
                        var pct = dTotal > 0 ? (dActive / dTotal) * 100 : 0;
                        loads.push(pct);
                        totalPct += pct;
                    }
                    root.coreLoads = loads;
                    root.cpuPercent = totalPct / loads.length;
                }
                root.prevCpuActive = active;
                root.prevCpuIdle = idle;
            } catch (e) {
                root.cpuPercent = 0;
                root.coreLoads = [];
            }
        }
    }

    // ─── Memory — /proc/meminfo ──────────────────
    FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        onLoaded: {
            try {
                var text = meminfoFile.text();
                var memTotalMatch = text.match(/MemTotal:\s+(\d+)/);
                var memAvailMatch = text.match(/MemAvailable:\s+(\d+)/);
                var swapTotalMatch = text.match(/SwapTotal:\s+(\d+)/);
                var swapFreeMatch = text.match(/SwapFree:\s+(\d+)/);

                if (memTotalMatch && memAvailMatch) {
                    var total = parseInt(memTotalMatch[1]);
                    var avail = parseInt(memAvailMatch[1]);
                    var used = total - avail;
                    root.memoryTotal = FormatUtils.formatMemory(Math.round(total / 1024));
                    root.memoryUsed = FormatUtils.formatMemory(Math.round(used / 1024));
                    root.memoryPercent = total > 0 ? (used / total) * 100 : 0;
                }

                if (swapTotalMatch && swapFreeMatch) {
                    var sTotal = parseInt(swapTotalMatch[1]);
                    var sFree = parseInt(swapFreeMatch[1]);
                    var sUsed = sTotal - sFree;
                    root.swapTotal = FormatUtils.formatMemory(Math.round(sTotal / 1024));
                    root.swapUsed = FormatUtils.formatMemory(Math.round(sUsed / 1024));
                    root.swapPercent = sTotal > 0 ? (sUsed / sTotal) * 100 : 0;
                }
            } catch (e) {
                root.memoryUsed = "";
                root.memoryTotal = "";
                root.memoryPercent = 0;
                root.swapUsed = "";
                root.swapTotal = "";
                root.swapPercent = 0;
            }
        }
    }

    // ─── Temperature — /sys/class/thermal/ ────────
    FileView {
        id: tempFile
        path: root.thermalZonePath
        onLoaded: {
            try {
                var val = parseInt(tempFile.text().trim());
                root.temperature = isNaN(val) ? 0 : val / 1000;
            } catch (e) {
                root.temperature = 0;
            }
        }
    }

    // ─── Load Average — /proc/loadavg ─────────────
    FileView {
        id: loadavgFile
        path: "/proc/loadavg"
        onLoaded: {
            try {
                var parts = loadavgFile.text().trim().split(/\s+/);
                if (parts.length >= 3)
                    root.loadAverage = parts[0] + " " + parts[1] + " " + parts[2];
            } catch (e) {
                root.loadAverage = "";
            }
        }
    }

    // ─── Uptime — /proc/uptime ────────────────────
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            try {
                var seconds = parseFloat(uptimeFile.text().split(" ")[0]);
                var days = Math.floor(seconds / 86400);
                var hours = Math.floor((seconds % 86400) / 3600);
                var minutes = Math.floor((seconds % 3600) / 60);
                if (days > 0)
                    root.uptimeText = days + "d " + hours + "h";
                else if (hours > 0)
                    root.uptimeText = hours + "h " + minutes + "m";
                else
                    root.uptimeText = minutes + "m";
            } catch (e) {
                root.uptimeText = "";
            }
        }
    }

    // ─── CPU Frequency — sysfs with /proc/cpuinfo fallback ─
    FileView {
        id: freqFile
        path: "/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq"
        onLoaded: {
            try {
                var khz = parseInt(freqFile.text().trim());
                if (!isNaN(khz) && khz > 0) {
                    root.cpuFrequency = khz / 1000; // MHz
                } else {
                    freqFallback.reload();
                }
            } catch (e) {
                freqFallback.reload();
            }
        }
        onLoadFailed: function (error) {
            freqFallback.reload();
        }
    }

    // Fallback: parse "cpu MHz" from /proc/cpuinfo (works on VMs, some servers)
    FileView {
        id: freqFallback
        path: "/proc/cpuinfo"
        onLoaded: {
            try {
                var text = freqFallback.text();
                var lines = text.split("\n");
                // Average all "cpu MHz" lines for a representative frequency
                var total = 0;
                var count = 0;
                for (var i = 0; i < lines.length; i++) {
                    var match = lines[i].match(/^cpu MHz\s*:\s*([\d.]+)/);
                    if (match) {
                        total += parseFloat(match[1]);
                        count++;
                    }
                }
                root.cpuFrequency = count > 0 ? total / count : 0;
            } catch (e) {
                root.cpuFrequency = 0;
            }
        }
    }

    // ─── Helpers ──────────────────────────────────
    // (formatMemory moved to FormatUtils singleton)
}
