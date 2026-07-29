pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    // ═══════════════════════════════════════════
    // DIMENSION TOKENS
    // ═══════════════════════════════════════════

    // Widget (bar) dimensions
    readonly property int widgetPadding: 16
    readonly property int widgetInnerMargin: 8
    readonly property int separatorWidth: 4

    // Inline bar (volume/brightness hover bars)
    readonly property int hoverBarWidth: 60
    readonly property int inlineBarHeight: 6
    readonly property int inlineBarMargin: 4
    readonly property int inlineBarRadius: 3
    readonly property real trackOpacity: 0.3
    readonly property real fillOpacity: 1.0
    readonly property int verticalBarInset: 10

    // Popup dimensions — Maia style, zero radius
    // Width is screen-percentage (uniform across all monitors)
    readonly property real popupWidthPct: 13
    // Gap between bar module and popup window
    readonly property int popupAnchorGap: 4
    readonly property int popupContentMargin: 12
    readonly property int popupShellPadding: 12
    readonly property int popupSectionSpacing: 10
    readonly property int popupHeaderSpacing: 6
    readonly property int popupButtonSpacing: 4
    readonly property int popupListSpacing: 2
    readonly property int popupButtonHeight: 36
    readonly property int popupButtonHeightSm: 32
    readonly property int popupRowHeight: 28
    readonly property int popupDelegateHeight: 36
    readonly property int popupDelegatePaddingH: 12
    readonly property int popupRadius: 0
    readonly property int popupBorderWidth: 1
    readonly property int popupSeparatorHeight: 1
    readonly property int popupSmallButtonWidth: 44
    readonly property int popupTinyButtonWidth: 22
    // Popup list views (device/network lists)
    readonly property int popupListMaxHeight: 260
    readonly property int popupListPadding: 4

    // System tray
    readonly property int trayItemWidth: 28
    readonly property int trayIconSize: 22

    // Media player popup
    readonly property int albumArtSize: 80
    readonly property int albumArtRowHeight: 90
    readonly property int mediaControlRowHeight: 36

    // Calendar popup
    readonly property int calendarCellHeight: 20
    readonly property int calendarMonthPadding: 6

    // Workspace overview popup
    readonly property int workspaceCellWidth: 56
    readonly property int workspaceCellHeight: 44
    readonly property int workspaceIndicatorWidth: 12
    readonly property int workspaceIndicatorMargin: 4

    // CPU widget & popup
    readonly property int coreLabelWidth: 20
    readonly property int corePctWidth: 30
    readonly property int coreBarWidth: 4
    readonly property int coreBarSpacing: 2

    // Volume popup
    readonly property int volumeAppNameWidth: 80

    // Desktop clock
    readonly property int desktopClockFallbackOffset: 60

    // Reveal animation (network widget hover expand)
    readonly property int revealPadding: 12

    // Disk popup icon margins
    readonly property int diskIconMargin: 4

    // Popup header vertical padding
    readonly property int popupHeaderTopPadding: 2
    readonly property int popupHeaderBottomPadding: 6

    // Popup slider handle padding
    readonly property int sliderHandlePadding: 8

    // Icon-label spacing (BarButton, etc.)
    readonly property int iconLabelSpacing: 4

    // OSD dimensions
    readonly property int osdWidth: 240
    readonly property int osdHeight: 52
    readonly property int osdToggleSize: 110
    readonly property int osdPadding: 14
    readonly property int osdBarHeight: 6
    readonly property int osdValueWidth: 36

    // Session menu
    readonly property int sessionButtonSize: 100
    readonly property int sessionButtonIconSize: 38
    readonly property int sessionButtonLabelSize: 12
    readonly property int sessionButtonKeySize: 10
    readonly property int sessionGridSpacing: 16
    readonly property int sessionGridColumns: 3
}
