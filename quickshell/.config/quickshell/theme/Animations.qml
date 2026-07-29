pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../config"

Singleton {
    id: root

    // ═══════════════════════════════════════════
    // ANIMATION CONSTANTS
    // All durations scaled by Config.animSpeed (0=instant, 1=normal, 2=slow)
    // ═══════════════════════════════════════════

    // Duration constants (ms)
    readonly property int animDuration: Math.max(0, Math.round(150 * Config.animSpeed))
    readonly property int fadeAnimDuration: Math.max(0, Math.round(120 * Config.animSpeed))
    readonly property int popupAnimDuration: Math.max(0, Math.round(200 * Config.animSpeed))
    readonly property int barSlideDuration: Math.max(0, Math.round(200 * Config.animSpeed))
    readonly property int scaleAnimDuration: Math.max(0, Math.round(200 * Config.animSpeed))
    readonly property int textSwapDuration: Math.max(0, Math.round(100 * Config.animSpeed))
    readonly property int iconSwapDuration: Math.max(0, Math.round(150 * Config.animSpeed))
    readonly property int barFillDuration: Math.max(0, Math.round(800 * Config.animSpeed))
    readonly property int breathDuration: Math.max(0, Math.round(15000 * Config.animSpeed))
    readonly property int valueAnimDuration: Math.max(0, Math.round(120 * Config.animSpeed))
    readonly property int clockFadeDuration: Math.max(0, Math.round(100 * Config.animSpeed))
    readonly property int clockSlideDuration: Math.max(0, Math.round(600 * Config.animSpeed))
    readonly property int osdFadeDuration: Math.max(0, Math.round(200 * Config.animSpeed))
    readonly property int sessionBackdropDuration: Math.max(0, Math.round(200 * Config.animSpeed))
    readonly property int sessionButtonScaleDuration: Math.max(0, Math.round(150 * Config.animSpeed))

    // Scale factors (not affected by speed)
    readonly property real hoverScale: 1.05
    readonly property real pressScale: 0.95
}
