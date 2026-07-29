pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "../config"

Singleton {
    id: root

    // ═══════════════════════════════════════════
    // SHADOW TOKENS
    // ═══════════════════════════════════════════

    // Popup shadow tokens (matching picom: shadow-radius=16, shadow-opacity=0.60, offset=-12/-12)
    readonly property int shadowBlur: 16
    readonly property real shadowOpacity: 0.60
    readonly property real shadowOffsetX: -12
    readonly property real shadowOffsetY: -12
    readonly property color shadowColor: "#000000"

    // Bar widget shadow tokens (subtler than popup shadows)
    readonly property int barShadowBlur: 16
    readonly property real barShadowOpacity: 0.30
    readonly property real barShadowOffsetX: 4
    readonly property real barShadowOffsetY: 4

    // Bar blur tokens (frosted-glass wallpaper blur behind modules)
    property bool barBlurEnabled: Config.barBlurEnabled
    property real barBlurStrength: Config.barBlurStrength
}
