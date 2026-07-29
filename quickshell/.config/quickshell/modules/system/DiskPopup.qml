import "../../services"
import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Spacing.popupListSpacing

    // ─── Header + Root Drive ────────────────────
    PopupHeader {
        iconText: "󰋊"
        titleText: "Disk"
    }

    BigStatLabel {
        text: Math.round(DiskService.rootPercent) + "%"
        errorThreshold: 90
        errorValue: DiskService.rootPercent
    }

    PopupProgressBar {
        Layout.fillWidth: true
        Layout.topMargin: Spacing.popupSectionSpacing
        value: Math.min(DiskService.rootPercent / 100, 1)
        threshold: 0.9
    }

    PopupInfoRow {
        label: "Root (/)"
        value: DiskService.rootUsed + " / " + DiskService.rootTotal
    }

    // ─── Section 2: Other System Drives ─────────
    Text {
        font.family: Typography.barFontFamily
        Layout.fillWidth: true
        Layout.topMargin: Spacing.popupSectionSpacing
        text: "System"
        font.pointSize: Typography.barFontPointSize
        font.weight: Font.Medium
        color: Colors.popupMuted
        visible: DiskService.systemDrives.length > 1
    }

    Repeater {
        model: DiskService.systemDrives
        delegate: ColumnLayout {
            Layout.fillWidth: true
            spacing: Spacing.popupListSpacing
            visible: modelData.mountpoint !== "/"

            PopupInfoRow {
                label: modelData.label || modelData.name
                value: modelData.used + " / " + modelData.size
            }

            PopupProgressBar {
                Layout.fillWidth: true
                value: Math.min((modelData.percent || 0) / 100, 1)
                threshold: 0.9
            }
        }
    }

    // ─── Section 3: Mounted External Drives ─────
    Text {
        font.family: Typography.barFontFamily
        Layout.fillWidth: true
        Layout.topMargin: Spacing.popupSectionSpacing
        text: "Mounted"
        font.pointSize: Typography.barFontPointSize
        font.weight: Font.Medium
        color: Colors.popupMuted
        visible: DiskService.mountedExternal.length > 0
    }

    Repeater {
        model: DiskService.mountedExternal
        delegate: ColumnLayout {
            Layout.fillWidth: true
            spacing: Spacing.popupListSpacing

            Rectangle {
                Layout.fillWidth: true
                height: Spacing.popupDelegateHeight
                color: Colors.popupContentBg
                radius: Spacing.popupRadius

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Spacing.popupDelegatePaddingH
                    anchors.rightMargin: Spacing.popupDelegatePaddingH

                    Text {
                        font.family: Typography.barFontFamily
                        text: modelData.label || modelData.name
                        color: Colors.popupMuted
                        font.pointSize: Typography.barFontPointSize
                        Layout.fillWidth: true
                    }

                    Text {
                        font.family: Typography.barFontFamily
                        text: modelData.used + " / " + modelData.size
                        color: Colors.popupContentFg
                        font.pointSize: Typography.barFontPointSize
                        font.weight: Font.Medium
                    }

                    Text {
                        text: "󰍵"
                        font.family: Typography.barIconFontFamily
                        font.pointSize: Typography.barIconPointSize
                        color: Colors.popupMuted
                        Layout.leftMargin: Spacing.diskIconMargin
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: DiskService.unmountDevice(modelData.path, modelData.mapperPath)
                        }
                    }
                }
            }

            PopupProgressBar {
                Layout.fillWidth: true
                value: Math.min((modelData.percent || 0) / 100, 1)
                threshold: 0.9
            }
        }
    }

    // ─── Section 4: Unmounted Drives ────────────
    Text {
        font.family: Typography.barFontFamily
        Layout.fillWidth: true
        Layout.topMargin: Spacing.popupSectionSpacing
        text: "Available"
        font.pointSize: Typography.barFontPointSize
        font.weight: Font.Medium
        color: Colors.popupMuted
        visible: DiskService.unmountedDrives.length > 0
    }

    Repeater {
        model: DiskService.unmountedDrives
        delegate: Rectangle {
            Layout.fillWidth: true
            height: Spacing.popupDelegateHeight
            color: Colors.popupContentBg
            radius: Spacing.popupRadius

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Spacing.popupDelegatePaddingH
                anchors.rightMargin: Spacing.popupDelegatePaddingH

                Text {
                    font.family: Typography.barFontFamily
                    text: modelData.label || modelData.name
                    color: Colors.popupMuted
                    font.pointSize: Typography.barFontPointSize
                    Layout.fillWidth: true
                }

                Text {
                    font.family: Typography.barFontFamily
                    text: modelData.fstype + " " + modelData.size
                    color: Colors.popupContentFg
                    font.pointSize: Typography.barFontPointSize
                    font.weight: Font.Medium
                }

                Text {
                    text: "󰍉"
                    font.family: Typography.barIconFontFamily
                    font.pointSize: Typography.barIconPointSize
                    color: Colors.popupMuted
                    Layout.leftMargin: Spacing.diskIconMargin
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: DiskService.mountDevice(modelData.path)
                    }
                }
            }
        }
    }
}
