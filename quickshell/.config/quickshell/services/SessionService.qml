pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool open: false

    signal closed

    function lock() {
        root.close();
        LockService.lock();
    }

    function suspend() {
        Quickshell.execDetached(["bash", "-c", "systemctl suspend || loginctl suspend"]);
    }

    function hibernate() {
        Quickshell.execDetached(["bash", "-c", "systemctl hibernate || loginctl hibernate"]);
    }

    function reboot() {
        Quickshell.execDetached(["bash", "-c", "systemctl reboot || loginctl reboot"]);
    }

    function shutdown() {
        Quickshell.execDetached(["bash", "-c", "systemctl poweroff || loginctl poweroff"]);
    }

    function logout() {
        root.close();
        WmBackend.logout();
    }

    function toggle() {
        if (root.open) {
            root.close();
        } else {
            Visibility.closeAll();
            root.open = true;
        }
    }

    function close() {
        root.open = false;
        root.closed();
    }
}
