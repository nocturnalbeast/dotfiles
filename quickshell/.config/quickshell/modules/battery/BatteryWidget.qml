import "../../services"
import "../../theme"
import "../../components"
import QtQuick

Item {
    id: root

    signal clicked

    function getBatteryText() {
        let pct = Math.round(BatteryService.percentage) + "%";
        if (BatteryService.state === "fullyCharged")
            return pct;

        if (BatteryService.timeRemaining)
            return pct + " [" + BatteryService.timeRemaining + "]";

        return pct;
    }

    width: seg.implicitWidth
    height: seg.implicitHeight
    visible: BatteryService.present

    BarSegment {
        id: seg

        headerText: BatteryService.getBatteryIcon()
        contentText: getBatteryText()
        onClicked: root.clicked()
        onScrollUp: BatteryService.cyclePowerProfile()
        onScrollDown: BatteryService.cyclePowerProfile()
    }
}
