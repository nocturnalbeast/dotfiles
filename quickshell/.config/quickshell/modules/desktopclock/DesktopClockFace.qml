import "../../components/anims"
import "../../theme"
import "../../services"
import QtQuick
import Quickshell

Item {
    id: root

    property bool fadeIn: false

    // Expose inner content for click-through mask
    property Item innerItem: clockContent

    SystemClock {
        id: sysClock
        precision: SystemClock.Seconds
    }

    property bool _placementReady: WallpaperPlacement.placement !== null && WallpaperPlacement.useAiPlacement
    property real _placementX: _placementReady ? WallpaperPlacement.placement.center_x_pct / 100 : -1
    property real _placementY: _placementReady ? WallpaperPlacement.placement.center_y_pct / 100 : -1

    Column {
        id: clockContent

        property bool _initialPlacement: true

        opacity: root.fadeIn ? 1.0 : 0.0

        x: root._placementX >= 0 ? root.width * root._placementX - width / 2 : root.width - width - Spacing.desktopClockFallbackOffset
        y: root._placementY >= 0 ? root.height * root._placementY - height / 2 : root.height - height - Spacing.desktopClockFallbackOffset

        spacing: 2

        Behavior on opacity {
            NumberAnimation {
                duration: Animations.clockFadeDuration
                easing.type: Easing.OutCubic
            }
        }
        Behavior on x {
            enabled: !clockContent._initialPlacement
            NumberAnimation {
                duration: Animations.clockSlideDuration
                easing.type: Easing.OutExpo
            }
        }
        Behavior on y {
            enabled: !clockContent._initialPlacement
            NumberAnimation {
                duration: Animations.clockSlideDuration
                easing.type: Easing.OutExpo
            }
        }

        onXChanged: {
            if (root._placementReady && clockContent._initialPlacement)
                clockContent._initialPlacement = false;
        }

        // Large time display
        Text {
            id: timeLabel

            font.family: Typography.barFontFamily
            font.pointSize: Typography.clockTimePt
            font.weight: Font.DemiBold
            color: Colors.desktopClockText
            text: Qt.formatDateTime(sysClock.date, "h:mm AP")

            Behavior on color {
                ColorFade {}
            }
        }

        // Date display
        Text {
            id: dateLabel

            anchors.horizontalCenter: parent.horizontalCenter
            font.family: Typography.barFontFamily
            font.pointSize: Typography.clockDatePt
            font.weight: Font.Normal
            color: Colors.desktopClockSubtext
            text: Qt.formatDateTime(sysClock.date, "dddd, MMMM d")

            Behavior on color {
                ColorFade {}
            }
        }
    }
}
