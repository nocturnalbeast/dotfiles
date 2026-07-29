import "../../components"
import "../../services"
import "../../theme"
import QtQuick

BarSegment {
    id: seg

    reversed: true
    headerText: "󰅐"
    contentText: SystemStats.uptimeText

    PollRef {
        service: SystemStats
    }
}
