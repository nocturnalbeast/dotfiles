import "../../services"
import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Spacing.popupListSpacing

    PopupHeader {
        iconText: "󰍛"
        titleText: "Memory"
    }

    BigStatLabel {
        text: Math.round(SystemStats.memoryPercent) + "%"
    }

    PopupProgressBar {
        Layout.fillWidth: true
        Layout.topMargin: Spacing.popupSectionSpacing
        value: SystemStats.memoryPercent / 100
        threshold: 0.9
    }

    PopupInfoRow {
        label: "RAM"
        value: SystemStats.memoryUsed + " / " + SystemStats.memoryTotal
    }

    // ── Swap (visible only when swap is active) ──────
    PopupProgressBar {
        Layout.fillWidth: true
        Layout.topMargin: Spacing.popupSectionSpacing
        value: Math.min(SystemStats.swapPercent / 100, 1)
        threshold: 0.9
        visible: SystemStats.swapPercent > 0
    }

    PopupInfoRow {
        label: "Swap"
        value: SystemStats.swapUsed + " / " + SystemStats.swapTotal
        visible: SystemStats.swapPercent > 0
    }
}
