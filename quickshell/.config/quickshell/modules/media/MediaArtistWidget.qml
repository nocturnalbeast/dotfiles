import "../../components"
import "../../config"
import "../../services"
import "../../theme"
import QtQuick

Item {
    id: root

    signal clicked
    signal rightClicked

    width: seg.width
    height: Typography.barHeight

    Segment {
        id: seg

        normalBg: Colors.widgetContentBg
        hoverBg: Colors.widgetHoverContentBg
        width: artistMarquee.implicitWidth + Spacing.widgetPadding
        hovered: mouse.containsMouse

        MarqueeText {
            id: artistMarquee

            anchors.verticalCenter: parent.verticalCenter
            x: Spacing.widgetInnerMargin
            maxWidth: 200
            text: MediaPlayer.artist || "Unknown"
            font.family: Typography.barFontFamily
            font.pointSize: Typography.barFontPointSize
            color: Colors.widgetContentFg
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
    }

    // Scroll overlay — captures wheel events without blocking clicks
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function (wheel) {
            if (Config.mediaScrollMode === "volume") {
                var vol = MediaPlayer.volume;
                if (wheel.angleDelta.y > 0)
                    MediaPlayer.setVolume(Math.min(1, vol + 0.05));
                else
                    MediaPlayer.setVolume(Math.max(0, vol - 0.05));
            } else if (Config.mediaScrollMode === "track") {
                if (wheel.angleDelta.y > 0)
                    MediaPlayer.prev();
                else
                    MediaPlayer.next();
            }
        }
    }
}
