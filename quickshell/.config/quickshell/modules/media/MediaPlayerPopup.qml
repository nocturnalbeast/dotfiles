import "../../services"
import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Spacing.popupSectionSpacing

    PopupHeader {
        iconText: "󰝚"
        titleText: "Now Playing"
    }

    // Track info + seek + volume — grouped with tighter internal spacing
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Spacing.popupListSpacing

        // Track info with album art
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Spacing.albumArtRowHeight
            color: Colors.popupContentBg
            radius: Spacing.popupRadius

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Spacing.popupDelegatePaddingH
                anchors.rightMargin: Spacing.popupDelegatePaddingH
                anchors.topMargin: Spacing.popupDelegatePaddingH
                anchors.bottomMargin: Spacing.popupDelegatePaddingH
                spacing: Spacing.popupDelegatePaddingH

                Rectangle {
                    width: Spacing.albumArtSize
                    height: Spacing.albumArtSize
                    radius: Spacing.popupRadius
                    color: Colors.popupContentBg
                    clip: true

                    Image {
                        id: artImage
                        anchors.fill: parent
                        source: MediaPlayer.albumArt
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: status === Image.Ready
                    }

                    Text {
                        font.family: Typography.barFontFamily
                        anchors.centerIn: parent
                        text: "󰎇"
                        font.pointSize: Typography.mediaArtSize
                        color: Colors.popupMuted
                        visible: !artImage.visible
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Spacing.popupListSpacing

                    Text {
                        font.family: Typography.barFontFamily
                        text: MediaPlayer.title || "No Track"
                        font.pointSize: Typography.barFontPointSize
                        font.weight: Font.Medium
                        color: Colors.popupContentFg
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        font.family: Typography.barFontFamily
                        text: (MediaPlayer.artist || "—") + "  •  " + (MediaPlayer.album || "—")
                        font.pointSize: Typography.popupMutedSize
                        color: Colors.popupMuted
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Seek bar
        Rectangle {
            Layout.fillWidth: true
            height: Spacing.mediaControlRowHeight
            color: Colors.popupContentBg
            radius: Spacing.popupRadius
            visible: MediaPlayer.available && MediaPlayer.positionSupported

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Spacing.popupDelegatePaddingH
                anchors.rightMargin: Spacing.popupDelegatePaddingH
                spacing: Spacing.popupDelegatePaddingH

                Text {
                    font.family: Typography.barFontFamily
                    text: MediaPlayer.formatTime(MediaPlayer.position)
                    font.pointSize: Typography.popupTinySize
                    color: Colors.popupMuted
                    Layout.alignment: Qt.AlignVCenter
                }

                PopupSlider {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    value: MediaPlayer.trackLength > 0 ? MediaPlayer.position / MediaPlayer.trackLength : 0
                    fullValue: 1
                    onMoved: function (val) {
                        MediaPlayer.setPosition(val * MediaPlayer.trackLength);
                    }
                }

                Text {
                    font.family: Typography.barFontFamily
                    text: MediaPlayer.formatTime(MediaPlayer.trackLength)
                    font.pointSize: Typography.popupTinySize
                    color: Colors.popupMuted
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // Scroll to seek ±10 seconds
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.NoButton
                onWheel: function (wheel) {
                    if (!MediaPlayer.available || !MediaPlayer.canSeek || !MediaPlayer.positionSupported)
                        return;
                    var delta = wheel.angleDelta.y > 0 ? 10 : -10;
                    var newPos = Math.max(0, Math.min(MediaPlayer.trackLength, MediaPlayer.position + delta));
                    MediaPlayer.setPosition(newPos);
                }
            }
        }

        // Volume slider
        Rectangle {
            Layout.fillWidth: true
            height: Spacing.mediaControlRowHeight
            color: Colors.popupContentBg
            radius: Spacing.popupRadius
            visible: MediaPlayer.available && MediaPlayer.volumeSupported

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Spacing.popupDelegatePaddingH
                anchors.rightMargin: Spacing.popupDelegatePaddingH
                spacing: Spacing.popupDelegatePaddingH

                Text {
                    text: "󰕾"
                    font.family: Typography.barIconFontFamily
                    font.pointSize: Typography.barFontPointSize
                    color: Colors.popupMuted
                }

                PopupSlider {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    value: Math.min(MediaPlayer.volume, 1)
                    fullValue: 1
                    onMoved: function (val) {
                        MediaPlayer.setVolume(val);
                    }
                }

                Text {
                    font.family: Typography.barFontFamily
                    text: Math.round(MediaPlayer.volume * 100) + "%"
                    font.pointSize: Typography.popupTinySize
                    color: Colors.popupMuted
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }

    // Transport controls
    RowLayout {
        Layout.fillWidth: true
        spacing: Spacing.popupButtonSpacing
        visible: MediaPlayer.available

        PopupButton {
            Layout.fillWidth: true
            iconFont: true
            label: "󰒝"
            buttonHeight: Spacing.popupButtonHeight
            visible: MediaPlayer.shuffleSupported
            borderColor: MediaPlayer.shuffle ? Colors.primary : Colors.popupMuted
            textColor: MediaPlayer.shuffle ? Colors.primary : Colors.popupContentFg
            onClicked: MediaPlayer.toggleShuffle()
        }

        PopupButton {
            Layout.fillWidth: true
            iconFont: true
            label: "󰒮"
            buttonHeight: Spacing.popupButtonHeight
            onClicked: MediaPlayer.prev()
        }

        PopupButton {
            Layout.fillWidth: true
            iconFont: true
            label: MediaPlayer.playing ? "󰏤" : "󰐊"
            buttonHeight: Spacing.popupButtonHeight
            onClicked: MediaPlayer.playPause()
        }

        PopupButton {
            Layout.fillWidth: true
            iconFont: true
            label: "󰒭"
            buttonHeight: Spacing.popupButtonHeight
            onClicked: MediaPlayer.next()
        }

        PopupButton {
            Layout.fillWidth: true
            iconFont: true
            label: MediaPlayer.loopIcon
            buttonHeight: Spacing.popupButtonHeight
            visible: MediaPlayer.loopSupported
            borderColor: MediaPlayer.loopActive ? Colors.primary : Colors.popupMuted
            textColor: MediaPlayer.loopActive ? Colors.primary : Colors.popupContentFg
            onClicked: MediaPlayer.cycleLoopState()
        }
    }

    // Player selector
    RowLayout {
        Layout.fillWidth: true
        spacing: Spacing.popupButtonSpacing
        visible: MediaPlayer.playerCount > 1

        Repeater {
            model: MediaPlayer.players
            delegate: PopupButton {
                required property var modelData
                Layout.fillWidth: true
                label: modelData.identity || "Unknown"
                buttonHeight: Spacing.popupButtonHeightSm
                borderColor: modelData === MediaPlayer.activePlayer ? Colors.primary : Colors.popupMuted
                textColor: modelData === MediaPlayer.activePlayer ? Colors.primary : Colors.popupContentFg
                onClicked: MediaPlayer.setActivePlayer(modelData)
            }
        }
    }

    // Fallback
    Text {
        font.family: Typography.barFontFamily
        text: "No media player running"
        font.pointSize: Typography.barFontPointSize
        color: Colors.popupMuted
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        visible: !MediaPlayer.available
        topPadding: Spacing.popupSectionSpacing
        bottomPadding: Spacing.popupSectionSpacing
    }
}
