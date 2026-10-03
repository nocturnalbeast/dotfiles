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
            disable(true);
        else
            enable(true);
    }

    // persistChange: only user-initiated toggles write to disk. The startup
    // path must read, never write — persisting at startup previously raced
    // the async config load and wiped config.json.
    function enable(persistChange) {
        LockService.stopDaemon();
        enabled = true;
        since = new Date();
        if (persistChange)
            persist();
    }

    function disable(persistChange) {
        LockService.startDaemon();
        enabled = false;
        since = null;
        if (persistChange)
            persist();
    }

    function persist() {
        Config.set("caffeineEnabled", enabled);
    }

    Component.onCompleted: {
        if (Config.caffeineEnabled)
            enable(false);
        else
            disable(false);
    }
}
