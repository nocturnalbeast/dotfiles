pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── Config file path ──
    readonly property string configPath: Quickshell.env("HOME") + "/.config/quickshell/config.json"

    // ── Raw JSON data ──
    property var _data: ({})

    // ── Watched file view (live reload on change) ──
    FileView {
        path: root.configPath
        watchChanges: true
        onLoaded: {
            try {
                root._data = JSON.parse(text());
            } catch (e) {
                // Config file missing or invalid — use defaults
                root._data = {};
            }
        }
        onLoadFailed: {
            root._data = {};
        }
    }

    // ── Typed config properties with JSON override + defaults fallback ──
    property real barHeightPct: _data.barHeightPct ?? Defaults.barHeightPct
    property string barPosition: _data.barPosition ?? Defaults.barPosition
    property bool barBlurEnabled: _data.barBlurEnabled ?? Defaults.barBlurEnabled
    property real barBlurStrength: _data.barBlurStrength ?? Defaults.barBlurStrength
    property string barFontFamily: _data.barFontFamily ?? Defaults.barFontFamily
    property string barIconFontFamily: _data.barIconFontFamily ?? Defaults.barIconFontFamily
    property real animSpeed: _data.animSpeed ?? Defaults.animSpeed
    property bool use24Hour: _data.use24Hour ?? Defaults.use24Hour
    property string mediaScrollMode: _data.mediaScrollMode ?? Defaults.mediaScrollMode
    property bool caffeineEnabled: _data.caffeineEnabled ?? Defaults.caffeineEnabled
    property real weatherLocationLat: _data.weatherLocationLat ?? Defaults.weatherLocationLat
    property real weatherLocationLon: _data.weatherLocationLon ?? Defaults.weatherLocationLon
    property string weatherCity: _data.weatherCity ?? Defaults.weatherCity
    property bool weatherUseFahrenheit: _data.weatherUseFahrenheit ?? Defaults.weatherUseFahrenheit
    property int weatherRefreshMinutes: _data.weatherRefreshMinutes ?? Defaults.weatherRefreshMinutes
    property string osdPosition: _data.osdPosition ?? Defaults.osdPosition
    property int osdOffsetX: _data.osdOffsetX ?? Defaults.osdOffsetX
    property int osdOffsetY: _data.osdOffsetY ?? Defaults.osdOffsetY
    property int osdMarginX: _data.osdMarginX ?? Defaults.osdMarginX
    property int osdMarginY: _data.osdMarginY ?? Defaults.osdMarginY
    property int osdTimeout: _data.osdTimeout ?? Defaults.osdTimeout

    // ── Persistence ──
    function save() {
        var obj = {};
        // Only write properties that differ from defaults
        if (root.barHeightPct !== Defaults.barHeightPct)
            obj.barHeightPct = root.barHeightPct;
        if (root.barPosition !== Defaults.barPosition)
            obj.barPosition = root.barPosition;
        if (root.barBlurEnabled !== Defaults.barBlurEnabled)
            obj.barBlurEnabled = root.barBlurEnabled;
        if (root.barBlurStrength !== Defaults.barBlurStrength)
            obj.barBlurStrength = root.barBlurStrength;
        if (root.barFontFamily !== Defaults.barFontFamily)
            obj.barFontFamily = root.barFontFamily;
        if (root.barIconFontFamily !== Defaults.barIconFontFamily)
            obj.barIconFontFamily = root.barIconFontFamily;
        if (root.animSpeed !== Defaults.animSpeed)
            obj.animSpeed = root.animSpeed;
        if (root.use24Hour !== Defaults.use24Hour)
            obj.use24Hour = root.use24Hour;
        if (root.mediaScrollMode !== Defaults.mediaScrollMode)
            obj.mediaScrollMode = root.mediaScrollMode;
        if (root.caffeineEnabled !== Defaults.caffeineEnabled)
            obj.caffeineEnabled = root.caffeineEnabled;
        if (root.weatherLocationLat !== Defaults.weatherLocationLat)
            obj.weatherLocationLat = root.weatherLocationLat;
        if (root.weatherLocationLon !== Defaults.weatherLocationLon)
            obj.weatherLocationLon = root.weatherLocationLon;
        if (root.weatherCity !== Defaults.weatherCity)
            obj.weatherCity = root.weatherCity;
        if (root.weatherUseFahrenheit !== Defaults.weatherUseFahrenheit)
            obj.weatherUseFahrenheit = root.weatherUseFahrenheit;
        if (root.weatherRefreshMinutes !== Defaults.weatherRefreshMinutes)
            obj.weatherRefreshMinutes = root.weatherRefreshMinutes;
        if (root.osdPosition !== Defaults.osdPosition)
            obj.osdPosition = root.osdPosition;
        if (root.osdOffsetX !== Defaults.osdOffsetX)
            obj.osdOffsetX = root.osdOffsetX;
        if (root.osdOffsetY !== Defaults.osdOffsetY)
            obj.osdOffsetY = root.osdOffsetY;
        if (root.osdMarginX !== Defaults.osdMarginX)
            obj.osdMarginX = root.osdMarginX;
        if (root.osdMarginY !== Defaults.osdMarginY)
            obj.osdMarginY = root.osdMarginY;
        if (root.osdTimeout !== Defaults.osdTimeout)
            obj.osdTimeout = root.osdTimeout;

        var json = JSON.stringify(obj, null, 2);
        // Escape single quotes for bash
        var escaped = json.replace(/'/g, "'\\''");
        saveProc.command = ["bash", "-c", "echo '" + escaped + "' > '" + root.configPath + "'"];
        saveProc.running = true;
    }

    Process {
        id: saveProc
        running: false
        command: ["true"]
    }

    function resetToDefaults() {
        root._data = {};
        resetProc.running = true;
    }

    Process {
        id: resetProc
        running: false
        command: ["rm", "-f", root.configPath]
    }
}
