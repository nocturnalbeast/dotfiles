import "../../services"
import "../../theme"
import QtQuick
import QtQuick.Effects

Item {
    id: root

    property bool isToggle: OsdManager.activeType === "bluetooth" || OsdManager.activeType === "wifi" || OsdManager.activeType === "caffeine"

    property real osdOpacity: OsdManager.visible ? 1.0 : 0.0
    property real osdScale: OsdManager.visible ? 1.0 : 0.92

    Behavior on osdOpacity {
        NumberAnimation {
            duration: Animations.osdFadeDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on osdScale {
        NumberAnimation {
            duration: Animations.osdFadeDuration
            easing.type: Easing.OutCubic
        }
    }

    opacity: osdOpacity
    scale: osdScale

    Rectangle {
        anchors.fill: parent
        color: Colors.popupBg
        radius: Spacing.popupRadius
        border.color: Colors.popupBorder
        border.width: Spacing.popupBorderWidth

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(Shadows.shadowColor.r, Shadows.shadowColor.g, Shadows.shadowColor.b, 0.5)
            shadowBlur: 0.5
            shadowVerticalOffset: 4
            shadowHorizontalOffset: 0
        }

        // Toggle mode: big centered icon
        Text {
            anchors.centerIn: parent
            visible: root.isToggle
            text: OsdManager.activeIcon
            font.family: Typography.barIconFontFamily
            font.pointSize: Typography.osdToggleIconSize
            color: OsdManager.activeState ? Colors.success : Colors.popupContentFg
        }

        // Slider mode: icon + progress bar + value text
        Row {
            id: row
            visible: !root.isToggle
            anchors.fill: parent
            anchors.leftMargin: Spacing.osdPadding
            anchors.rightMargin: Spacing.osdPadding
            spacing: Spacing.osdPadding

            Text {
                id: iconItem
                text: OsdManager.activeIcon
                font.family: Typography.barIconFontFamily
                font.pointSize: Typography.popupHeaderIconSize
                color: Colors.popupContentFg
                verticalAlignment: Text.AlignVCenter
                height: parent.height
            }

            Rectangle {
                width: row.width - iconItem.width - valueText.width - Spacing.osdPadding * 2
                height: Spacing.osdBarHeight
                anchors.verticalCenter: parent.verticalCenter
                color: Colors.popupBarTrack
                radius: Spacing.popupRadius

                Rectangle {
                    height: parent.height
                    width: Math.max(0, parent.width * Math.min(OsdManager.activeValue, 1.0))
                    color: OsdManager.activeMuted ? Colors.error : Colors.popupBarFill
                    radius: Spacing.popupRadius
                }
            }

            Text {
                id: valueText
                text: Math.round(OsdManager.activeValue * 100) + "%"
                font.family: Typography.barFontFamily
                font.pointSize: Typography.popupMutedSize
                font.weight: Font.Medium
                color: Colors.popupContentFg
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
                height: parent.height
                width: Spacing.osdValueWidth
            }
        }
    }
}
