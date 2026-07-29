import "../../services"
import "../../theme"
import "../../components"
import QtQuick

BarButton {
    id: root

    icon: Visibility.activeBar === 1 ? "󰔢" : "󰔡"
    onClicked: Visibility.switchBar()

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function (wheel) {
            Visibility.switchBar();
        }
    }
}
