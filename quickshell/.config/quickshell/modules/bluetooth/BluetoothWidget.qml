import "../../services"
import "../../theme"
import "../../components"
import QtQuick

Item {
    id: root

    signal clicked

    width: seg.implicitWidth
    height: seg.implicitHeight

    BarSegment {
        id: seg

        reversed: true
        headerText: BluetoothService.enabled ? "󰂯" : "󰂲"
        contentText: BluetoothService.connected ? BluetoothService.connectedDevice : (BluetoothService.enabled ? "On" : "Off")
        onClicked: root.clicked()
        onRightClicked: BluetoothService.togglePower()
    }
}
