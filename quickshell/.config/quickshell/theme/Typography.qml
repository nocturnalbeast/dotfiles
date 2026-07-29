pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../config"

Singleton {
    id: root

    // ═══════════════════════════════════════════
    // SIZING & FONTS
    // ═══════════════════════════════════════════
    readonly property real barHeightPct: Config.barHeightPct
    readonly property int barHeight: Math.round(Qt.application.screens[0].height * barHeightPct / 100)
    readonly property real textFontPct: 60
    readonly property real iconFontPct: 80
    readonly property int barTextPixelSize: Math.round(root.barHeight * root.textFontPct / 100)
    readonly property int barIconPixelSize: Math.round(root.barHeight * root.iconFontPct / 100)
    readonly property int barFontPointSize: Math.round(root.barTextPixelSize * 0.75)
    readonly property int barIconPointSize: Math.round(root.barIconPixelSize * 0.75)
    readonly property string barFontFamily: Config.barFontFamily
    readonly property string barIconFontFamily: Config.barIconFontFamily

    // ═══════════════════════════════════════════
    // SEMANTIC FONT SIZE TOKENS
    // ═══════════════════════════════════════════

    // Large stat displays in system popups (CPU, Memory, Battery, Disk)
    readonly property int bigStatSize: barFontPointSize + 12

    // OSD toggle icon (fills the square)
    readonly property int osdToggleIconSize: bigStatSize + 20

    // Media player album art overlay text
    readonly property int mediaArtSize: barFontPointSize + 10

    // Popup header / section titles
    readonly property int popupHeaderSize: barFontPointSize + 2

    // Popup header icon size
    readonly property int popupHeaderIconSize: barIconPointSize + 2

    // Slightly larger popup text (volume percentage, brightness value)
    readonly property int popupSubHeaderSize: barFontPointSize + 1

    // Muted / secondary labels in popups
    readonly property int popupMutedSize: barFontPointSize - 1

    // Tiny labels (app names, seek times, section headers)
    readonly property int popupTinySize: barFontPointSize - 2

    // ═══════════════════════════════════════════
    // DESKTOP CLOCK FONTS
    // ═══════════════════════════════════════════
    readonly property int clockTimePt: 72
    readonly property int clockDatePt: 15
}
