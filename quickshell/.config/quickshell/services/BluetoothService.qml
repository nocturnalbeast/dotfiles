pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property bool available: adapter != null

    readonly property bool enabled: adapter ? adapter.enabled : false

    readonly property var devices: adapter ? adapter.devices.values : []

    readonly property string connectedDevice: {
        if (!adapter)
            return "";

        var devs = adapter.devices.values;
        for (var i = 0; i < devs.length; i++) {
            if (devs[i].connected)
                return devs[i].name || devs[i].address;
        }
        return "";
    }

    readonly property bool connected: connectedDevice !== ""

    function togglePower() {
        if (!adapter)
            return;
        adapter.enabled = !adapter.enabled;
    }

    function scanDevices() {
        // Native API auto-discovers; this is a no-op but kept for API compat
    }

    function connectDevice(device) {
        if (device && typeof device.connect === "function")
            device.connect();
    }

    function disconnectDevice(device) {
        if (device && typeof device.disconnect === "function")
            device.disconnect();
    }
}
