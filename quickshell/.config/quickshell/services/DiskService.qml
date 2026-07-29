pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../components"

Singleton {
    id: root

    // ─── Backward-compatible root drive properties (for DiskWidget bar) ──
    property string rootUsed: ""
    property string rootTotal: ""
    property real rootPercent: 0

    // ─── Categorized drive lists ────────────────────────
    property var systemDrives: []      // Internal disks with mounted partitions
    property var mountedExternal: []   // Removable/hotplug drives that are mounted
    property var unmountedDrives: []   // Partitions with fstype but no mount, >500M, not swap

    // ─── Polling control (consumer-visibility) ──────────
    property int _pollConsumers: 0
    readonly property bool pollingActive: _pollConsumers > 0

    function registerPollConsumer() {
        _pollConsumers++;
    }
    function unregisterPollConsumer() {
        _pollConsumers = Math.max(0, _pollConsumers - 1);
    }

    // ─── Hotplug watcher ────────────────────────────────
    Process {
        id: udevWatcher
        command: ["udevadm", "monitor", "--subsystem-match", "block", "--property"]
        running: true
        stdout: SplitParser {
            onRead: function (line) {
                if (line.startsWith("ACTION=add") || line.startsWith("ACTION=remove") || line.startsWith("ACTION=change"))
                    debounceTimer.restart();
            }
        }
        onExited: function () {
            if (!udevWatcher.running)
                udevWatcher.running = true;
        }
    }

    Timer {
        id: debounceTimer
        interval: 1000
        onTriggered: lsblkQuery.running = true
    }

    // ─── One-shot lsblk query ───────────────────────────
    Process {
        id: lsblkQuery
        running: false
        command: ["lsblk", "-J", "-b", "-o", "NAME,SIZE,FSTYPE,LABEL,MOUNTPOINTS,TYPE,PATH,HOTPLUG,MODEL,ROTA"]
        stdout: StdioCollector {
            onStreamFinished: function () {
                try {
                    var data = JSON.parse(text);
                    parseDevices(data.blockdevices || []);
                } catch (e) {
                    console.warn("DiskService: lsblk parse error:", e);
                }
            }
        }
    }

    Component.onCompleted: {
        lsblkQuery.running = true;
        polkitCheck.running = true;
    }

    // ─── Polkit agent launcher (portable across distros) ────
    Process {
        id: polkitCheck
        running: false
        command: ["pidof", "polkit-gnome-authentication-agent-1", "lxqt-policykit-agent", "polkit-kde-authentication-agent-1", "mate-polkit", "hyprpolkitagent", "lxpolkit"]
        onExited: function (exitCode, exitStatus) {
            // pidof returns 0 if ANY process was found
            if (exitCode === 0)
                return; // agent already running, skip
            polkitLauncher.running = true;
        }
    }

    Process {
        id: polkitLauncher
        running: false
        command: ["bash", "-c", "for agent in " + "/usr/libexec/hyprpolkitagent " + "/usr/lib/hyprpolkitagent " + "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 " + "/usr/libexec/polkit-gnome-authentication-agent-1 " + "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1 " + "/usr/lib/polkit-kde-authentication-agent-1 " + "/usr/libexec/polkit-kde-authentication-agent-1 " + "/usr/libexec/kf6/polkit-kde-authentication-agent-1 " + "/usr/lib/x86_64-linux-gnu/libexec/polkit-kde-authentication-agent-1 " + "/usr/libexec/polkit-mate-authentication-agent-1 " + "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1 " + "/usr/bin/lxqt-policykit-agent " + "/usr/bin/lxpolkit; do " + "[ -x \"$agent\" ] && exec \"$agent\"; " + "done"]
    }

    // ─── Poll every 30s for usage changes ───────────────
    Timer {
        interval: 30000
        running: root.pollingActive
        repeat: true
        onTriggered: lsblkQuery.running = true
    }

    // ─── Device parsing ─────────────────────────────────
    function parseDevices(blockdevices) {
        var sysDrives = [];
        var mountedExt = [];
        var unmounted = [];

        for (var i = 0; i < blockdevices.length; i++) {
            var disk = blockdevices[i];
            if (disk.type !== "disk")
                continue;
            if (!disk.children || disk.children.length === 0)
                continue;
            var isRemovable = disk.hotplug === true;
            var diskModel = disk.model || disk.name;

            for (var j = 0; j < disk.children.length; j++) {
                var part = disk.children[j];
                if (part.type !== "part")
                    continue;
                if (!part.fstype)
                    continue;
                var mounts = part.mountpoints || [];
                var hasSwap = mounts.indexOf("[SWAP]") >= 0;
                if (hasSwap)
                    continue;

                // Check for unlocked LUKS mapper device (child of the partition)
                var isLuks = part.fstype === "crypto_LUKS";
                var luksMapper = null;
                var realMounts = [];
                var displayFstype = part.fstype;
                var displayPath = part.path;

                if (isLuks && part.children && part.children.length > 0) {
                    for (var k = 0; k < part.children.length; k++) {
                        var child = part.children[k];
                        if (child.type === "crypt") {
                            luksMapper = child;
                            break;
                        }
                    }
                }

                if (luksMapper) {
                    // LUKS is unlocked — use mapper device info
                    var mapperMounts = luksMapper.mountpoints || [];
                    realMounts = mapperMounts.filter(function (m) {
                        return m && m !== "[SWAP]" && m !== "";
                    });
                    displayFstype = luksMapper.fstype || part.fstype;
                    displayPath = luksMapper.path;
                } else {
                    realMounts = mounts.filter(function (m) {
                        return m && m !== "[SWAP]" && m !== "";
                    });
                }

                // Size filter: skip partitions < 500MB
                var sizeBytes = part.size || 0;
                if (sizeBytes < 500000000)
                    continue;
                var label = part.label || (luksMapper ? luksMapper.label : "") || part.name;
                var sizeStr = FormatUtils.formatBytes(sizeBytes);
                // For btrfs with multiple mounts, prefer "/" as the representative mountpoint
                var mountPoint = "";
                if (realMounts.indexOf("/") >= 0)
                    mountPoint = "/";
                else if (realMounts.length > 0)
                    mountPoint = realMounts[0];

                var entry = {
                    name: part.name,
                    label: label,
                    fstype: displayFstype,
                    size: sizeStr,
                    sizeBytes: sizeBytes,
                    mountpoint: mountPoint,
                    path: part.path,
                    mapperPath: luksMapper ? luksMapper.path : "",
                    model: diskModel,
                    isRemovable: isRemovable,
                    isLuks: isLuks,
                    isLuksUnlocked: !!luksMapper,
                    used: "",
                    percent: 0
                };

                if (mountPoint) {
                    if (mountPoint === "/" || mountPoint === "/boot/efi") {
                        sysDrives.push(entry);
                    } else {
                        // All other mounted partitions (internal data drives, USB, etc.)
                        mountedExt.push(entry);
                    }
                } else {
                    unmounted.push(entry);
                }
            }
        }

        root.systemDrives = sysDrives;
        root.mountedExternal = mountedExt;
        root.unmountedDrives = unmounted;

        // Trigger df query for usage data
        dfQuery.running = true;
    }

    // ─── df query for usage percentages ─────────────────
    Process {
        id: dfQuery
        running: false
        command: ["df", "-h", "--output=source,target,size,used,avail,pcent"]
        stdout: StdioCollector {
            onStreamFinished: function () {
                try {
                    var lines = text.split("\n");
                    var usageMap = {};
                    var usageByTarget = {};
                    for (var i = 1; i < lines.length; i++) {
                        var parts = lines[i].trim().split(/\s+/);
                        if (parts.length >= 6) {
                            usageMap[parts[0]] = {
                                source: parts[0],
                                target: parts[1],
                                size: parts[2],
                                used: parts[3],
                                avail: parts[4],
                                percent: parseFloat(parts[5]) || 0
                            };
                            usageByTarget[parts[1]] = usageMap[parts[0]];
                        }
                    }
                    applyUsage(usageMap, usageByTarget);
                } catch (e) {
                    console.warn("DiskService: df parse error:", e);
                }
            }
        }
    }

    function applyUsage(usageMap, usageByTarget) {
        // Update system drives
        var sysDrives = root.systemDrives.slice();
        for (var i = 0; i < sysDrives.length; i++) {
            var d = sysDrives[i];
            var usage = usageMap["/dev/" + d.name] || (d.mapperPath ? usageMap[d.mapperPath] : null) || (d.mountpoint ? usageByTarget[d.mountpoint] : null);
            if (usage) {
                d.used = usage.used;
                d.percent = usage.percent;
            }
        }
        root.systemDrives = sysDrives;

        // Update mounted external
        var ext = root.mountedExternal.slice();
        for (var j = 0; j < ext.length; j++) {
            var e = ext[j];
            var usage2 = usageMap["/dev/" + e.name] || (e.mapperPath ? usageMap[e.mapperPath] : null) || (e.mountpoint ? usageByTarget[e.mountpoint] : null);
            if (usage2) {
                e.used = usage2.used;
                e.percent = usage2.percent;
            }
        }
        root.mountedExternal = ext;

        // Update root backward-compat properties
        for (var m = 0; m < sysDrives.length; m++) {
            if (sysDrives[m].mountpoint === "/") {
                root.rootUsed = sysDrives[m].used;
                root.rootTotal = sysDrives[m].size;
                root.rootPercent = sysDrives[m].percent;
                break;
            }
        }
    }

    // ─── Actions ────────────────────────────────────────
    function mountDevice(devicePath) {
        mountProc.command = ["udiskie-mount", "-r", devicePath];
        mountProc.running = true;
    }

    function unmountDevice(devicePath, mapperPath) {
        // For unlocked LUKS, unmount via the mapper device so udiskie can also lock the container
        var target = (mapperPath && mapperPath.length > 0) ? mapperPath : devicePath;
        unmountProc.command = ["udiskie-umount", "-l", target];
        unmountProc.running = true;
    }

    Process {
        id: mountProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: function () {
                refreshTimer.start();
            }
        }
        stderr: SplitParser {
            onRead: function (line) {
                console.warn("DiskService mount:", line);
            }
        }
        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0)
                console.warn("DiskService mount failed: exit code", exitCode);
        }
    }

    Process {
        id: unmountProc
        running: false
        stdout: StdioCollector {
            onStreamFinished: function () {
                refreshTimer.start();
            }
        }
        stderr: SplitParser {
            onRead: function (line) {
                console.warn("DiskService unmount:", line);
            }
        }
        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0)
                console.warn("DiskService unmount failed: exit code", exitCode);
        }
    }

    Timer {
        id: refreshTimer
        interval: 500
        onTriggered: lsblkQuery.running = true
    }

    // ─── Helpers ────────────────────────────────────────
    // (formatSize moved to FormatUtils singleton)
}
