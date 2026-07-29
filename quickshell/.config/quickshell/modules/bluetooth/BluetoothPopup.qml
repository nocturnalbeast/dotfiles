import "../../services"
import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Spacing.popupSectionSpacing

    PopupHeader {
        iconText: "󰂯"
        titleText: "Bluetooth"
        iconColor: BluetoothService.enabled ? Colors.popupContentFg : Colors.popupMuted
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Spacing.popupButtonSpacing

        PopupButton {
            Layout.fillWidth: true
            label: BluetoothService.enabled ? "⭘  Power Off" : "⏽  Power On"
            iconFont: true
            onClicked: BluetoothService.togglePower()
        }

        PopupButton {
            Layout.fillWidth: true
            label: "  Scan"
            iconFont: true
            opacity: BluetoothService.enabled ? 1 : 0.4
            onClicked: BluetoothService.scanDevices()
        }
    }

    ListView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight + Spacing.popupListPadding, Spacing.popupListMaxHeight)
        spacing: Spacing.popupListSpacing
        clip: true
        model: BluetoothService.devices

        PopupListTransitions {
            id: tx
        }

        add: tx.addTransition
        remove: tx.removeTransition
        displaced: tx.displacedTransition

        delegate: PopupListDelegate {
            id: devDelegate
            onClicked: {
                if (modelData.connected)
                    BluetoothService.disconnectDevice(modelData);
                else
                    BluetoothService.connectDevice(modelData);
            }

            Text {
                font.family: Typography.barIconFontFamily
                text: "󰋋"
                font.pointSize: Typography.barFontPointSize
                color: Colors.popupContentFg
            }

            Text {
                font.family: Typography.barFontFamily
                text: modelData.name || modelData.address || "Unknown"
                font.pointSize: Typography.barFontPointSize
                color: Colors.popupContentFg
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                font.family: Typography.barFontFamily
                text: modelData.connected ? "Disconnect" : "Connect"
                font.pointSize: Typography.barFontPointSize - 1
                color: modelData.connected ? Colors.error : Colors.popupContentFg
                visible: devDelegate.containsMouse || modelData.connected
            }
        }
    }

    Text {
        font.family: Typography.barFontFamily
        text: BluetoothService.devices.length === 0 ? "No devices found" : ""
        font.pointSize: Typography.barFontPointSize
        color: Colors.popupMuted
        Layout.fillWidth: true
        horizontalAlignment: Text.AlignHCenter
        topPadding: Spacing.popupSectionSpacing
        bottomPadding: Spacing.popupSectionSpacing
        visible: BluetoothService.devices.length === 0
    }
}
