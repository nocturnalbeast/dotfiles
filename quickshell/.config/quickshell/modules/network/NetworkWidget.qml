import "../../components"
import "../../services"
import "../../theme"
import QtQuick

Item {
    id: root

    signal clicked
    property bool hovered: hoverArea.containsMouse

    PollRef {
        service: NetworkService
    }

    function getRevealText() {
        if (!NetworkService.connected)
            return "";

        let parts = [];
        if (NetworkService.connectionType === "wifi" && NetworkService.ssid)
            parts.push(NetworkService.ssid);

        if (NetworkService.interfaceName)
            parts.push(NetworkService.interfaceName);

        if (NetworkService.localIp)
            parts.push(NetworkService.localIp);

        return parts.join(" · ");
    }

    width: row.width
    height: Typography.barHeight

    MouseArea {
        id: hoverArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    Row {
        id: row

        spacing: 0

        Segment {
            id: contentSeg

            hovered: root.hovered
            normalBg: Colors.widgetContentBg
            hoverBg: Colors.widgetHoverContentBg
            text: NetworkService.connected ? (NetworkService.upSpeed + " | " + NetworkService.downSpeed) : "Off"

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clicked()
            }
        }

        Rectangle {
            height: Typography.barHeight
            width: root.hovered && NetworkService.connected ? (revealLabel.width + Spacing.revealPadding) : 0
            color: Colors.widgetHoverContentBg
            clip: true

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.clicked()
            }

            Text {
                id: revealLabel

                anchors.centerIn: parent
                text: getRevealText()
                font.family: Typography.barFontFamily
                font.pointSize: Typography.popupMutedSize
                color: Colors.widgetContentFg
                opacity: 0.8
            }

            Behavior on width {
                NumberAnimation {
                    duration: Animations.animDuration
                    easing.type: Easing.OutQuad
                }
            }
        }

        Segment {
            id: headerSeg

            hovered: root.hovered
            text: NetworkService.getNetworkIcon()
            fontFamily: Typography.barIconFontFamily
            fontPointSize: Typography.barIconPointSize
            textColor: Colors.widgetHeaderFg
            normalBg: Colors.widgetHeaderBg
            hoverBg: Colors.widgetHoverHeaderBg

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function (mouse) {
                    if (mouse.button === Qt.RightButton)
                        NetworkService.toggleWifi();
                    else
                        root.clicked();
                }
            }
        }
    }
}
