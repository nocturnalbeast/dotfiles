import "../../components"
import "../../services"
import "../../theme"
import QtQuick

Item {
    id: root

    signal clicked
    property bool hovered: mouseArea.containsMouse

    PollRef {
        service: SystemStats
    }

    width: row.width
    height: Typography.barHeight

    Row {
        id: row

        spacing: 0

        Segment {
            hovered: root.hovered
            text: ""
            fontFamily: Typography.barIconFontFamily
            fontPointSize: Typography.barIconPointSize
            textColor: Colors.widgetHeaderFg
            normalBg: Colors.widgetHeaderBg
            hoverBg: Colors.widgetHoverHeaderBg
        }

        Segment {
            hovered: root.hovered
            width: Spacing.trayItemWidth
            normalBg: Colors.widgetContentBg
            hoverBg: Colors.widgetHoverContentBg

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: Spacing.inlineBarMargin
                anchors.right: parent.right
                anchors.rightMargin: Spacing.inlineBarMargin
                height: Typography.barHeight - Spacing.verticalBarInset
                radius: Spacing.inlineBarRadius
                color: Colors.widgetBarTrack

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: parent.height * Math.min(SystemStats.memoryPercent / 100, 1)
                    radius: parent.radius
                    color: Colors.widgetBarFill

                    Behavior on height {
                        NumberAnimation {
                            duration: Animations.barFillDuration
                            easing.type: Easing.OutQuint
                        }
                    }
                }
            }
        }

        Segment {
            hovered: root.hovered
            normalBg: Colors.widgetContentBg
            hoverBg: Colors.widgetHoverContentBg
            text: SystemStats.memoryUsed + "/" + SystemStats.memoryTotal + (SystemStats.swapPercent > 0 ? " | S: " + SystemStats.swapUsed + "/" + SystemStats.swapTotal : "")
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
