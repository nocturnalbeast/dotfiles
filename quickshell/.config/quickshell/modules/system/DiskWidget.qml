import "../../services"
import "../../theme"
import "../../components"
import QtQuick

BarSegment {
    id: seg

    reversed: false
    headerText: "󰋊"
    contentText: Math.round(DiskService.rootPercent) + "% of " + DiskService.rootTotal
}
