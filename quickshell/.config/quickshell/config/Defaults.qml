pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    // Bar defaults
    readonly property real barHeightPct: 2.5
    readonly property string barPosition: "top"

    // Feature toggles
    readonly property bool barBlurEnabled: false
    readonly property real barBlurStrength: 0.6

    // Widget preferences
    readonly property string barFontFamily: "Inter Display"
    readonly property string barIconFontFamily: "Symbols Nerd Font"

    // Animation speed multiplier: 0=off, 1=normal, 2=slow (for testing)
    readonly property real animSpeed: 1.0

    // Clock format: false = 12h (default), true = 24h
    readonly property bool use24Hour: false

    // Media widget scroll mode: "volume" = adjust player volume, "track" = skip tracks
    readonly property string mediaScrollMode: "volume"

    // Caffeine: true = autolock disabled on startup
    readonly property bool caffeineEnabled: false

    // Weather
    readonly property real weatherLocationLat: 0
    readonly property real weatherLocationLon: 0
    readonly property string weatherCity: ""
    readonly property bool weatherUseFahrenheit: false
    readonly property int weatherRefreshMinutes: 15

    // OSD
    readonly property string osdPosition: "bottom-center"
    readonly property int osdOffsetX: 0
    readonly property int osdOffsetY: 0
    readonly property int osdMarginX: 24
    readonly property int osdMarginY: 24
    readonly property int osdTimeout: 2000
}
