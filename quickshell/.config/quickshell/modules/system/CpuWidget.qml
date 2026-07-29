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
            text: "󰍛"
            fontFamily: Typography.barIconFontFamily
            fontPointSize: Typography.barIconPointSize
            textColor: Colors.widgetHeaderFg
            normalBg: Colors.widgetHeaderBg
            hoverBg: Colors.widgetHoverHeaderBg
        }

        Segment {
            hovered: root.hovered
            width: coreRow.width + Spacing.widgetPadding / 2
            normalBg: Colors.widgetContentBg
            hoverBg: Colors.widgetHoverContentBg

            Row {
                id: coreRow

                anchors.centerIn: parent
                spacing: Spacing.coreBarSpacing

                Repeater {
                    model: SystemStats.coreLoads

                    Rectangle {
                        width: Spacing.coreBarWidth
                        height: Typography.barHeight - Spacing.verticalBarInset
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        radius: Spacing.popupRadius
                        color: Colors.widgetBarTrack

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: parent.height * Math.min(modelData / 100, 1)
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
            }
        }

        Segment {
            hovered: root.hovered
            normalBg: Colors.widgetContentBg
            hoverBg: Colors.widgetHoverContentBg
            text: {
                var pct = Math.round(SystemStats.cpuPercent) + "%";
                var freq = SystemStats.cpuFrequency;
                if (freq > 0) {
                    if (freq >= 1000)
                        pct += " @ " + (freq / 1000).toFixed(1) + "GHz";
                    else
                        pct += " @ " + Math.round(freq) + "MHz";
                }
                return pct;
            }
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
