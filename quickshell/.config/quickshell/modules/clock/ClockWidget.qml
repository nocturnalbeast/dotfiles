import "../../components"
import "../../config"
import "../../theme"
import "../../services"
import QtQuick
import Quickshell

Item {
    id: root

    signal clicked

    width: row.width
    height: Typography.barHeight

    opacity: WmDetector.isWorkspaceEmpty ? 0.0 : 1.0
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation {
            duration: 300
            easing.type: Easing.InOutCubic
        }
    }

    SystemClock {
        id: sysClock

        precision: SystemClock.Seconds
    }

    Row {
        id: row

        spacing: 0

        Segment {
            hovered: mouseArea.containsMouse
            text: Qt.formatDateTime(sysClock.date, "ddd dd, MMM")
            textWeight: Font.Medium
            normalBg: Colors.widgetContentBg
            hoverBg: Colors.widgetHoverContentBg
        }

        Segment {
            hovered: mouseArea.containsMouse
            text: Config.use24Hour ? Qt.formatDateTime(sysClock.date, "HH:mm") : Qt.formatDateTime(sysClock.date, "hh:mm AP")
            normalBg: Colors.widgetFocusedBg
            hoverBg: Colors.widgetHoverHeaderBg
            textColor: Colors.widgetFocusedFg
        }

        Segment {
            hovered: mouseArea.containsMouse
            text: "󰥔"
            fontFamily: Typography.barIconFontFamily
            fontPointSize: Typography.barIconPointSize
            textColor: Colors.widgetHeaderFg
            normalBg: Colors.widgetHeaderBg
            hoverBg: Colors.widgetHoverHeaderBg
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                Config.use24Hour = !Config.use24Hour;
                Config.save();
            } else {
                root.clicked();
            }
        }
        onWheel: function (wheel) {
            if (wheel.angleDelta.y > 0)
                Visibility.calendarMonthOffset++;
            else
                Visibility.calendarMonthOffset--;
        }
    }
}
