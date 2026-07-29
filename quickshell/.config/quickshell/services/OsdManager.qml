pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../config"

Singleton {
    id: root

    property bool visible: false
    property string activeType: "" // "volume" | "brightness" | "mic" | "bluetooth" | "wifi" | "caffeine"
    property real activeValue: 0 // 0.0 to 1.0 for slider types
    property string activeIcon: ""
    property bool activeMuted: false
    property bool activeState: false // on/off for toggle types
    property bool _ready: false // suppress OSD during startup init

    // Grace period: ignore service init signals for 3 seconds after shell start
    Component.onCompleted: startupDelay.start()

    Timer {
        id: startupDelay
        interval: 3000
        onTriggered: root._ready = true
    }

    function showVolume(value, muted) {
        if (!root._ready || Visibility.activeBarPopup !== null)
            return;
        root.activeType = "volume";
        root.activeValue = value;
        root.activeMuted = muted;
        if (muted || value === 0)
            root.activeIcon = "󰝟";
        else if (value < 0.33)
            root.activeIcon = "󰕿";
        else if (value < 0.66)
            root.activeIcon = "󰖀";
        else
            root.activeIcon = "󰕾";
        root.visible = true;
        root._restartTimer();
    }

    function showBrightness(value) {
        if (!root._ready || Visibility.activeBarPopup !== null)
            return;
        root.activeType = "brightness";
        root.activeValue = value;
        root.activeMuted = false;
        if (value < 0.33)
            root.activeIcon = "󰃚";
        else if (value < 0.66)
            root.activeIcon = "󰃛";
        else
            root.activeIcon = "󰃠";
        root.visible = true;
        root._restartTimer();
    }

    function showMic(value, muted) {
        if (!root._ready)
            return;
        root.activeType = "mic";
        root.activeValue = value;
        root.activeMuted = muted;
        root.activeState = !muted;
        root.activeIcon = muted ? "󰍭" : "󰍬";
        root.visible = true;
        root._restartTimer();
    }

    function showBluetooth(powered) {
        if (!root._ready)
            return;
        root.activeType = "bluetooth";
        root.activeValue = powered ? 1 : 0;
        root.activeState = powered;
        root.activeIcon = powered ? "󰂯" : "󰂲";
        root.visible = true;
        root._restartTimer();
    }

    function showWifi(enabled) {
        if (!root._ready)
            return;
        root.activeType = "wifi";
        root.activeValue = enabled ? 1 : 0;
        root.activeState = enabled;
        root.activeIcon = enabled ? "󰤨" : "󰤭";
        root.visible = true;
        root._restartTimer();
    }

    function showCaffeine(enabled) {
        if (!root._ready)
            return;
        root.activeType = "caffeine";
        root.activeValue = enabled ? 1 : 0;
        root.activeState = enabled;
        root.activeIcon = enabled ? "󰅶" : "󰒲";
        root.visible = true;
        root._restartTimer();
    }

    function dismiss() {
        root.visible = false;
        root.activeType = "";
    }

    function _restartTimer() {
        dismissTimer.stop();
        dismissTimer.start();
    }

    Timer {
        id: dismissTimer
        interval: Config.osdTimeout
        onTriggered: root.dismiss()
    }

    Connections {
        target: AudioService
        function onVolumeChanged() {
            root.showVolume(AudioService.volume, AudioService.muted);
        }
    }

    Connections {
        target: BrightnessService
        function onPercentageChanged() {
            root.showBrightness(BrightnessService.percentage / 100);
        }
    }

    Connections {
        target: BluetoothService
        function onEnabledChanged() {
            root.showBluetooth(BluetoothService.enabled);
        }
    }

    Connections {
        target: CaffeineService
        function onEnabledChanged() {
            root.showCaffeine(CaffeineService.enabled);
        }
    }

    // Disabled: NetworkService singleton triggers upstream QS segfault
    // (NMWirelessNetwork::updateReferenceAp use-after-free). Re-enable
    // when upstream fixes the bug.
    // Connections {
    //     target: NetworkService
    //     function onWifiToggled(enabled) {
    //         root.showWifi(enabled);
    //     }
    // }

}
