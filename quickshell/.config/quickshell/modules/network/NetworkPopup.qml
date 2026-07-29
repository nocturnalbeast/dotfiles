import "../../services"
import "../../theme"
import "../../components"
import "../../config"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Spacing.popupSectionSpacing

    PopupHeader {
        iconText: NetworkService.getNetworkIcon()
        titleText: "Network"
    }

    Rectangle {
        Layout.fillWidth: true
        height: Spacing.popupRowHeight
        color: Colors.popupContentBg

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Spacing.popupContentMargin
            anchors.rightMargin: Spacing.popupContentMargin

            Text {
                font.family: Typography.barFontFamily
                text: NetworkService.connectionType === "wifi" ? NetworkService.ssid : (NetworkService.connectionType === "ethernet" ? "Wired • " + NetworkService.interfaceName : "Disconnected")
                font.pointSize: Typography.barFontPointSize
                font.weight: Font.Medium
                color: Colors.popupContentFg
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: NetworkService.connectionType === "wifi" && NetworkService.connected ? NetworkService.getSignalIcon(NetworkService.signalStrength) + " " + NetworkService.signalStrength + "%" : ""
                font.family: Typography.barIconFontFamily
                font.pointSize: Typography.barFontPointSize
                color: Colors.popupContentFg
            }
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        visible: NetworkService.connectionType === "ethernet"
        spacing: Spacing.popupButtonSpacing

        Rectangle {
            Layout.fillWidth: true
            height: Spacing.popupRowHeight
            color: Colors.popupContentBg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Spacing.popupContentMargin
                anchors.rightMargin: Spacing.popupContentMargin

                Text {
                    font.family: Typography.barIconFontFamily
                    text: "󰈀"
                    font.pointSize: Typography.barFontPointSize
                    color: Colors.popupContentFg
                }

                Text {
                    font.family: Typography.barFontFamily
                    text: NetworkService.interfaceName
                    font.pointSize: Typography.barFontPointSize
                    color: Colors.popupContentFg
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    font.family: Typography.barFontFamily
                    text: NetworkService.localIp
                    font.pointSize: Typography.barFontPointSize
                    color: Colors.popupMuted
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: Spacing.popupRowHeight
            color: Colors.popupContentBg

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Spacing.popupContentMargin
                anchors.rightMargin: Spacing.popupContentMargin

                Text {
                    font.family: Typography.barFontFamily
                    text: "󰁅 " + NetworkService.downSpeed + "  󰁝 " + NetworkService.upSpeed
                    font.pointSize: Typography.barFontPointSize
                    color: Colors.popupContentFg
                }
            }
        }
    }

    // Disabled: WiFi scanning triggers upstream QS segfault
    // (NMWirelessNetwork::updateReferenceAp use-after-free).
    // Re-enable when upstream fixes the bug.
    // Rectangle {
    //     visible: (NetworkService.connectionType === "wifi" || NetworkService.connectionType === "disconnected")
    //     Layout.fillWidth: true
    //     height: Spacing.popupButtonHeight
    //     radius: Spacing.popupRadius
    //     color: scanMouse.containsMouse ? Colors.popupButtonHoverBg : Colors.popupButtonBg
    //     border.color: Colors.popupBorder
    //     border.width: Spacing.popupBorderWidth
    //
    //     Row {
    //         anchors.centerIn: parent
    //         spacing: Spacing.popupHeaderSpacing
    //
    //         Text {
    //             id: scanIcon
    //
    //             font.family: Typography.barIconFontFamily
    //             text: ""
    //             font.pointSize: Typography.barFontPointSize
    //             color: Colors.popupContentFg
    //             verticalAlignment: Text.AlignVCenter
    //
    //             RotationAnimation {
    //                 id: scanSpin
    //
    //                 target: scanIcon
    //                 from: 0
    //                 to: 360
    //                 duration: Animations.scanSpinDuration
    //                 loops: Animation.Infinite
    //                 running: NetworkService.scanning
    //                 onStopped: scanIcon.rotation = 0
    //             }
    //         }
    //
    //         Text {
    //             font.family: Typography.barFontFamily
    //             text: NetworkService.scanning ? "Scanning..." : "Scan WiFi"
    //             font.pointSize: Typography.barFontPointSize
    //             color: Colors.popupContentFg
    //             verticalAlignment: Text.AlignVCenter
    //         }
    //     }
    //
    //     MouseArea {
    //         id: scanMouse
    //
    //         anchors.fill: parent
    //         hoverEnabled: true
    //         cursorShape: Qt.PointingHandCursor
    //         onClicked: {
    //             if (!NetworkService.scanning)
    //                 NetworkService.scanWifi();
    //         }
    //     }
    // }
    //
    // ListView {
    //     visible: (NetworkService.connectionType === "wifi" || NetworkService.connectionType === "disconnected")
    //     Layout.fillWidth: true
    //     Layout.preferredHeight: Math.min(contentHeight + Spacing.popupListPadding, Spacing.popupListMaxHeight)
    //     spacing: Spacing.popupListSpacing
    //     clip: true
    //     model: NetworkService.wifiNetworks
    //
    //     PopupListTransitions {
    //         id: tx
    //     }
    //
    //     add: tx.addTransition
    //     remove: tx.removeTransition
    //     displaced: tx.displacedTransition
    //
    //     delegate: PopupListDelegate {
    //         id: netDelegate
    //         normalColor: modelData.connected ? Colors.popupHoverBg : "transparent"
    //         onClicked: {
    //             if (modelData.connected)
    //                 NetworkService.disconnectNetwork(modelData);
    //             else
    //                 NetworkService.connectToNetwork(modelData);
    //         }
    //
    //         Text {
    //             font.family: Typography.barIconFontFamily
    //             text: NetworkService.getSignalIcon(Math.round(modelData.signalStrength * 100))
    //             font.pointSize: Typography.barFontPointSize
    //             color: Colors.popupContentFg
    //         }
    //
    //         Text {
    //             font.family: Typography.barFontFamily
    //             text: modelData.name || "Unknown"
    //             font.pointSize: Typography.barFontPointSize
    //             color: Colors.popupContentFg
    //             Layout.fillWidth: true
    //             elide: Text.ElideRight
    //         }
    //
    //         Text {
    //             font.family: Typography.barFontFamily
    //             text: modelData.connected ? "Connected" : ""
    //             font.pointSize: Typography.barFontPointSize - 1
    //             color: Colors.success
    //             visible: modelData.connected
    //         }
    //     }
    // }
}
