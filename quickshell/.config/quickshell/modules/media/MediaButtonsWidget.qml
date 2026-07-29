import "../../components"
import "../../config"
import "../../services"
import "../../theme"
import "../../components/anims"
import QtQuick

Item {
    id: root

    width: row.width
    height: Typography.barHeight

    Row {
        id: row

        spacing: 0

        Segment {
            normalBg: Colors.widgetHeaderBg
            hoverBg: Colors.widgetHoverHeaderBg
            hovered: prevMouse.containsMouse
            text: "󰒮"
            fontFamily: Typography.barIconFontFamily
            fontPointSize: Typography.barIconPointSize
            textColor: Colors.widgetHeaderFg

            MouseArea {
                id: prevMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: MediaPlayer.prev()
            }
        }

        Segment {
            id: playSeg

            normalBg: Colors.widgetHeaderBg
            hoverBg: Colors.widgetHoverHeaderBg
            hovered: playMouse.containsMouse
            width: Math.max(iconPlay.implicitWidth, iconPause.implicitWidth) + Spacing.widgetPadding

            Text {
                id: iconPlay

                anchors.centerIn: parent
                text: "󰐊"
                font.family: Typography.barIconFontFamily
                font.pointSize: Typography.barIconPointSize + 2
                color: Colors.widgetHeaderFg
                opacity: MediaPlayer.playing ? 0 : 1
                rotation: MediaPlayer.playing ? -90 : 0
                scale: MediaPlayer.playing ? 0.5 : 1

                Behavior on opacity {
                    NumberAnimation {
                        duration: Animations.iconSwapDuration
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on rotation {
                    NumberAnimation {
                        duration: Animations.iconSwapDuration
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Animations.iconSwapDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Text {
                id: iconPause

                anchors.centerIn: parent
                text: "󰏤"
                font.family: Typography.barIconFontFamily
                font.pointSize: Typography.barIconPointSize + 2
                color: Colors.widgetHeaderFg
                opacity: MediaPlayer.playing ? 1 : 0
                rotation: MediaPlayer.playing ? 0 : 90
                scale: MediaPlayer.playing ? 1 : 0.5

                Behavior on opacity {
                    NumberAnimation {
                        duration: Animations.iconSwapDuration
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on rotation {
                    NumberAnimation {
                        duration: Animations.iconSwapDuration
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: Animations.iconSwapDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }

            MouseArea {
                id: playMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: MediaPlayer.playPause()
            }
        }

        Segment {
            normalBg: Colors.widgetHeaderBg
            hoverBg: Colors.widgetHoverHeaderBg
            hovered: nextMouse.containsMouse
            text: "󰒭"
            fontFamily: Typography.barIconFontFamily
            fontPointSize: Typography.barIconPointSize
            textColor: Colors.widgetHeaderFg

            MouseArea {
                id: nextMouse

                anchors.fill: parent
                hoverEnabled: true
                onClicked: MediaPlayer.next()
            }
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
