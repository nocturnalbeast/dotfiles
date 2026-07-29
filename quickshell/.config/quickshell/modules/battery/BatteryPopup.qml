import "../../services"
import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Spacing.popupSectionSpacing

    PopupHeader {
        iconText: BatteryService.getBatteryIcon()
        titleText: "Battery"
        iconColor: BatteryService.percentage < 20 ? Colors.error : Colors.popupContentFg
    }

    BigStatLabel {
        text: BatteryService.present ? Math.round(BatteryService.percentage) + "%" : "N/A"
        errorThreshold: 20
        errorValue: BatteryService.percentage
        errorWhenBelow: true
    }

    Rectangle {
        Layout.fillWidth: true
        height: Spacing.popupDelegateHeight
        radius: Spacing.popupRadius
        color: Colors.popupContentBg

        Text {
            font.family: Typography.barFontFamily
            anchors.centerIn: parent
            text: {
                if (!BatteryService.present)
                    return "No battery detected";

                if (BatteryService.charging)
                    return "Charging";

                if (BatteryService.state === "fullyCharged")
                    return "Fully Charged";

                return "Discharging";
            }
            font.pointSize: Typography.barFontPointSize
            color: Colors.popupContentFg
        }
    }

    PopupProgressBar {
        Layout.fillWidth: true
        value: BatteryService.percentage / 100
        threshold: 0.2
        errorWhenBelow: true
        visible: BatteryService.present
    }
}
