import "../../services"
import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

ColumnLayout {
    spacing: Spacing.popupSectionSpacing

    PopupHeader {
        iconText: AudioService.getVolumeIcon()
        titleText: "Volume"
    }

    // Master volume row
    Rectangle {
        Layout.fillWidth: true
        height: Spacing.popupDelegateHeight
        color: Colors.popupContentBg
        radius: Spacing.popupRadius

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Spacing.popupDelegatePaddingH
            anchors.rightMargin: Spacing.popupDelegatePaddingH
            spacing: Spacing.popupSectionSpacing

            Text {
                font.family: Typography.barFontFamily
                text: Math.round(AudioService.volume * 100) + "%"
                font.pointSize: Typography.popupSubHeaderSize
                font.weight: Font.Medium
                color: AudioService.volume > 1.005 ? Colors.error : Colors.popupContentFg
                Layout.alignment: Qt.AlignVCenter
            }

            PopupSlider {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                value: AudioService.volume
                fullValue: 1
                onMoved: function (val) {
                    AudioService.setVolume(val);
                }
            }

            Rectangle {
                width: Spacing.popupTinyButtonWidth
                height: width
                radius: Spacing.popupRadius
                color: muteMouse.containsMouse ? Colors.popupButtonHoverBg : Colors.popupContentBg
                border.color: AudioService.muted ? Colors.error : Colors.popupMuted
                border.width: Spacing.popupBorderWidth

                Text {
                    anchors.centerIn: parent
                    text: AudioService.muted ? "󰝟" : "󰕾"
                    font.family: Typography.barIconFontFamily
                    font.pointSize: Typography.popupMutedSize
                    color: AudioService.muted ? Colors.error : Colors.popupContentFg
                }

                MouseArea {
                    id: muteMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: AudioService.toggleMute()
                }
            }
        }
    }

    // Per-app volume mixer
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Spacing.popupListSpacing
        visible: AudioService.linkedStreams.length > 0

        Text {
            font.family: Typography.barFontFamily
            text: "Applications"
            font.pointSize: Typography.popupMutedSize
            font.weight: Font.Medium
            color: Colors.popupMuted
            Layout.leftMargin: Spacing.popupContentMargin
        }

        Repeater {
            model: AudioService.linkedStreams

            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                height: Spacing.popupDelegateHeight
                color: Colors.popupContentBg
                radius: Spacing.popupRadius

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Spacing.popupDelegatePaddingH
                    anchors.rightMargin: Spacing.popupDelegatePaddingH
                    spacing: Spacing.popupSectionSpacing

                    Text {
                        font.family: Typography.barFontFamily
                        text: AudioService.getNodeName(modelData)
                        font.pointSize: Typography.popupMutedSize
                        color: Colors.popupContentFg
                        Layout.preferredWidth: Spacing.volumeAppNameWidth
                        elide: Text.ElideRight
                        Layout.alignment: Qt.AlignVCenter
                    }

                    PopupSlider {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        value: modelData.audio ? modelData.audio.volume : 0
                        fullValue: 1
                        onMoved: function (val) {
                            AudioService.setNodeVolume(modelData, val);
                        }
                    }

                    Text {
                        font.family: Typography.barFontFamily
                        text: Math.round((modelData.audio ? modelData.audio.volume : 0) * 100) + "%"
                        font.pointSize: Typography.popupTinySize
                        color: Colors.popupMuted
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }
    }

    // Output device selector
    ColumnLayout {
        Layout.fillWidth: true
        spacing: Spacing.popupListSpacing
        visible: AudioService.sinks.length > 1

        Text {
            font.family: Typography.barFontFamily
            text: "Output Device"
            font.pointSize: Typography.popupMutedSize
            font.weight: Font.Medium
            color: Colors.popupMuted
            Layout.leftMargin: Spacing.popupContentMargin
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Spacing.popupButtonSpacing

            Repeater {
                model: AudioService.sinks

                delegate: PopupButton {
                    required property var modelData
                    Layout.fillWidth: true
                    label: modelData.description || modelData.name || "Unknown"
                    buttonHeight: Spacing.popupButtonHeight
                    borderColor: modelData === Pipewire.defaultAudioSink ? Colors.primary : Colors.popupMuted
                    textColor: modelData === Pipewire.defaultAudioSink ? Colors.primary : Colors.popupContentFg
                    onClicked: AudioService.setDefaultSink(modelData)
                }
            }
        }
    }
}
