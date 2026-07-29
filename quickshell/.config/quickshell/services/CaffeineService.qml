pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../config"

Singleton {
    id: root

    property bool enabled: false
    property var since: null

    function toggle() {
        if (enabled)
            disable();
        else
            enable();
    }

    function enable() {
        LockService.stopDaemon();
        enabled = true;
        since = new Date();
        persist();
    }

    function disable() {
        LockService.startDaemon();
        enabled = false;
        since = null;
        persist();
    }

    function persist() {
        Config.caffeineEnabled = enabled;
        Config.save();
    }

    Component.onCompleted: {
        if (Config.caffeineEnabled)
            enable();
        else
            disable();
    }
}
