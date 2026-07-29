import "../../components"
import "../../services"
import QtQuick

Item {
    id: root

    width: seg.implicitWidth
    height: seg.implicitHeight

    PollRef {
        service: KeyboardService
    }

    BarSegment {
        id: seg

        reversed: true
        interactive: false
        headerText: "󰌌"
        contentText: KeyboardService.layout
    }
}
