pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../components"
import "../config"

Singleton {
    id: root

    // ═══════════════════════════════════════════
    // DEVICE DISCOVERY
    // ═══════════════════════════════════════════

    readonly property var allDevices: Networking.devices.values

    readonly property var wifiDevice: {
        var devs = root.allDevices;
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wifi)
                return devs[i];
        }
        return null;
    }

    readonly property var wiredDevice: {
        var devs = root.allDevices;
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].type === DeviceType.Wired)
                return devs[i];
        }
        return null;
    }

    // ═══════════════════════════════════════════
    // CONNECTION STATE
    // ═══════════════════════════════════════════

    readonly property bool connected: {
        if (root.wifiDevice && root.wifiDevice.connected)
            return true;
        if (root.wiredDevice && root.wiredDevice.connected)
            return true;
        return false;
    }

    readonly property string connectionType: {
        if (root.wifiDevice && root.wifiDevice.connected)
            return "wifi";
        if (root.wiredDevice && root.wiredDevice.connected)
            return "ethernet";
        return "disconnected";
    }

    readonly property string interfaceName: {
        if (root.wifiDevice && root.wifiDevice.connected)
            return root.wifiDevice.name || "";
        if (root.wiredDevice && root.wiredDevice.connected)
            return root.wiredDevice.name || "";
        return "";
    }

    // ═══════════════════════════════════════════
    // WIFI DETAILS
    // ═══════════════════════════════════════════

    readonly property var activeWifiNetwork: {
        if (!root.wifiDevice || !root.wifiDevice.connected)
            return null;
        var nets = root.wifiDevice.networks.values;
        for (var i = 0; i < nets.length; i++) {
            if (nets[i].connected)
                return nets[i];
        }
        return null;
    }

    readonly property string ssid: root.activeWifiNetwork ? root.activeWifiNetwork.name : ""

    // Native API gives 0.0-1.0, consumers expect 0-100
    readonly property int signalStrength: root.activeWifiNetwork ? Math.round(root.activeWifiNetwork.signalStrength * 100) : 0

    readonly property bool scanning: root.wifiDevice ? root.wifiDevice.scannerEnabled && root.wifiDevice.scanning : false

    readonly property var wifiNetworks: root.wifiDevice ? root.wifiDevice.networks.values : []

    // ═══════════════════════════════════════════
    // IP ADDRESS (no native API — fallback to ip command)
    // ═══════════════════════════════════════════

    property string localIp: ""

    function refreshIp() {
        var iface = root.interfaceName;
        if (!iface)
            return;
        ipProc.command = ["bash", "-c", "ip -4 -o addr show dev " + iface + " 2>/dev/null | awk '{split($4,a,\"/\"); print a[1]}' | head -1"];
        ipProc.running = true;
    }

    Process {
        id: ipProc
        running: false
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var output = data.toString().trim();
                    root.localIp = output || "";
                } catch (e) {}
            }
        }
    }

    // Refresh IP when interface changes
    onInterfaceNameChanged: root.refreshIp()

    // ═══════════════════════════════════════════
    // POLLING CONTROL (consumer-visibility)
    // ═══════════════════════════════════════════

    property int _pollConsumers: 0
    readonly property bool pollingActive: _pollConsumers > 0

    function registerPollConsumer() {
        _pollConsumers++;
    }
    function unregisterPollConsumer() {
        _pollConsumers = Math.max(0, _pollConsumers - 1);
    }

    // ═══════════════════════════════════════════
    // SPEED TRACKING (no native API — /proc/net/dev)
    // ═══════════════════════════════════════════

    property string upSpeed: ""
    property string downSpeed: ""
    property real prevRxBytes: 0
    property real prevTxBytes: 0
    property int speedInterval: 3

    Timer {
        interval: root.speedInterval * 1000
        running: root.connected && root.pollingActive
        repeat: true
        triggeredOnStart: root.pollingActive
        onTriggered: {
            var iface = root.interfaceName;
            if (!iface || speedCheck.running)
                return;
            speedCheck.command = ["bash", "-c", "awk '/^" + iface + ":/ {print $2, $10}' /proc/net/dev"];
            speedCheck.running = true;
        }
    }

    Process {
        id: speedCheck
        running: false
        command: ["true"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let output = data.toString().trim();
                    let parts = output.split(/\s+/);
                    if (parts.length >= 2) {
                        let rxBytes = parseInt(parts[0]) || 0;
                        let txBytes = parseInt(parts[1]) || 0;
                        if (root.prevRxBytes > 0) {
                            root.downSpeed = FormatUtils.formatSpeed((rxBytes - root.prevRxBytes) / root.speedInterval);
                            root.upSpeed = FormatUtils.formatSpeed((txBytes - root.prevTxBytes) / root.speedInterval);
                        }
                        root.prevRxBytes = rxBytes;
                        root.prevTxBytes = txBytes;
                    }
                } catch (e) {
                    root.upSpeed = "";
                    root.downSpeed = "";
                }
            }
        }
    }

    // (formatSpeed moved to FormatUtils singleton)

    // ═══════════════════════════════════════════
    // ICON HELPERS
    // ═══════════════════════════════════════════

    function getNetworkIcon() {
        if (!connected)
            return "󰤭";
        if (connectionType === "ethernet")
            return "󰈀";
        if (signalStrength < 20)
            return "󰤯";
        if (signalStrength < 40)
            return "󰤟";
        if (signalStrength < 60)
            return "󰤢";
        if (signalStrength < 80)
            return "󰤥";
        return "󰤨";
    }

    function getSignalIcon(strength) {
        if (strength < 20)
            return "󰤯";
        if (strength < 40)
            return "󰤟";
        if (strength < 60)
            return "󰤢";
        if (strength < 80)
            return "󰤥";
        return "󰤨";
    }

    // ═══════════════════════════════════════════
    // ACTIONS
    // ═══════════════════════════════════════════

    function scanWifi() {
        if (Config.wifiScanEnabled && root.wifiDevice)
            root.wifiDevice.scannerEnabled = true;
    }

    function connectToNetwork(network) {
        if (network && typeof network.connect === "function")
            network.connect();
    }

    function disconnectNetwork(network) {
        if (network && typeof network.disconnect === "function")
            network.disconnect();
    }

    // Toggle WiFi radio on/off via nmcli (native QS API lacks radio toggle)
    function toggleWifi() {
        if (!root.wifiDevice)
            return;
        var isOn = root.wifiDevice.state !== 0; // DeviceState.Unmanaged = 0
        wifiToggleProc.command = isOn ? ["nmcli", "radio", "wifi", "off"] : ["nmcli", "radio", "wifi", "on"];
        wifiToggleProc.running = true;
        root.wifiToggled(!isOn);
    }

    signal wifiToggled(bool enabled)

    Process {
        id: wifiToggleProc
        running: false
        command: ["true"]
    }

    readonly property bool available: Networking.backend !== NetworkBackendType.None
}
