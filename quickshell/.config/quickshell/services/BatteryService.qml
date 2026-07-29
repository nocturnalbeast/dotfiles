pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    // ═══════════════════════════════════════════
    // BACKWARD-COMPATIBLE PROPERTIES
    // (BatteryWidget + BatteryPopup use these)
    // ═══════════════════════════════════════════

    // UPower gives 0.0-1.0, consumers expect 0-100
    readonly property real percentage: {
        var dev = UPower.displayDevice;
        return (dev && dev.isLaptopBattery) ? Math.round(dev.percentage * 100) : 0;
    }

    readonly property bool charging: {
        var dev = UPower.displayDevice;
        return dev ? dev.state === UPowerDeviceState.Charging : false;
    }

    readonly property bool present: {
        var dev = UPower.displayDevice;
        return dev ? dev.isLaptopBattery && dev.isPresent : false;
    }

    readonly property string state: {
        var dev = UPower.displayDevice;
        if (!dev || !dev.isLaptopBattery)
            return "unknown";
        if (dev.state === UPowerDeviceState.Charging)
            return "charging";
        if (dev.state === UPowerDeviceState.Discharging)
            return "discharging";
        if (dev.state === UPowerDeviceState.FullyCharged)
            return "fullyCharged";
        if (dev.state === UPowerDeviceState.PendingCharge)
            return "charging";
        return "unknown";
    }

    readonly property string timeRemaining: {
        var dev = UPower.displayDevice;
        if (!dev || !dev.isLaptopBattery)
            return "";
        var seconds = root.charging ? dev.timeToFull : dev.timeToEmpty;
        if (!seconds || seconds <= 0)
            return "";
        var hours = Math.floor(seconds / 3600);
        var minutes = Math.floor((seconds % 3600) / 60);
        if (hours > 0)
            return hours + "." + (minutes < 10 ? "0" : "") + minutes + " hours";
        return minutes + " minutes";
    }

    readonly property bool available: present

    // ═══════════════════════════════════════════
    // ICON (10-step, unified for widget + popup)
    // ═══════════════════════════════════════════

    function getBatteryIcon() {
        if (!present)
            return "󰂎";
        if (charging) {
            if (percentage < 20)
                return "󰢟";
            if (percentage < 40)
                return "󰢜";
            if (percentage < 60)
                return "󰂆";
            if (percentage < 80)
                return "󰂇";
            return "󰂋";
        }
        if (percentage < 10)
            return "󰂃";
        if (percentage < 20)
            return "󰁺";
        if (percentage < 30)
            return "󰁻";
        if (percentage < 40)
            return "󰁼";
        if (percentage < 50)
            return "󰁽";
        if (percentage < 60)
            return "󰁾";
        if (percentage < 70)
            return "󰁿";
        if (percentage < 80)
            return "󰂀";
        if (percentage < 90)
            return "󰂁";
        return "󰁹";
    }

    // ═══════════════════════════════════════════
    // POWER PROFILES (bonus from UPower module)
    // ═══════════════════════════════════════════

    readonly property string powerProfile: {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            return "Power Saver";
        case PowerProfile.Balanced:
            return "Balanced";
        case PowerProfile.Performance:
            return "Performance";
        default:
            return "";
        }
    }

    function cyclePowerProfile() {
        switch (PowerProfiles.profile) {
        case PowerProfile.PowerSaver:
            PowerProfiles.profile = PowerProfile.Balanced;
            break;
        case PowerProfile.Balanced:
            PowerProfiles.profile = PowerProfile.Performance;
            break;
        case PowerProfile.Performance:
            PowerProfiles.profile = PowerProfile.PowerSaver;
            break;
        }
    }

    // ═══════════════════════════════════════════
    // BATTERY HEALTH
    // ═══════════════════════════════════════════

    readonly property real healthPercentage: {
        var dev = UPower.displayDevice;
        return (dev && dev.healthSupported) ? Math.round(dev.healthPercentage * 100) : -1;
    }
}
