pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    property int _activeCount: 0
    readonly property bool hasActiveGrab: _activeCount > 0

    property var _grabs: ({})

    function requestGrab(grabId, clearCallback) {
        if (_grabs[grabId] === undefined)
            _activeCount++;
        let updated = {};
        Object.keys(_grabs).forEach(k => {
            updated[k] = _grabs[k];
        });
        updated[grabId] = clearCallback;
        _grabs = updated;
    }

    function releaseGrab(grabId) {
        if (_grabs[grabId] !== undefined) {
            let updated = {};
            Object.keys(_grabs).forEach(k => {
                if (k !== grabId)
                    updated[k] = _grabs[k];
            });
            _grabs = updated;
            _activeCount = Math.max(0, _activeCount - 1);
        }
    }

    function clearTopGrab() {
        const keys = Object.keys(_grabs);
        if (keys.length === 0)
            return;
        const topId = keys[keys.length - 1];
        const callback = _grabs[topId];
        releaseGrab(topId);
        if (callback)
            Qt.callLater(callback);
    }
}
