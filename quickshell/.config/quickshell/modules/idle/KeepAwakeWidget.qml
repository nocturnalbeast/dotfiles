import "../../components"
import "../../services"
import QtQuick

Item {
    id: root

    width: seg.implicitWidth
    height: seg.implicitHeight

    BarSegment {
        id: seg

        reversed: true
        interactive: true
        headerText: CaffeineService.enabled ? "󰅶" : "󰒲"
        contentText: ""
        onClicked: CaffeineService.toggle()
    }
}
