import "../../services"
import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Spacing.popupListSpacing

    PopupHeader {
        iconText: "󰍛"
        titleText: "CPU"
    }

    // ── Large CPU percentage ────────────────────────
    BigStatLabel {
        text: Math.round(SystemStats.cpuPercent) + "%"
    }

    // ── Per-core bars ───────────────────────────────
    Flow {
        Layout.fillWidth: true
        Layout.topMargin: Spacing.popupSectionSpacing
        spacing: Spacing.popupSectionSpacing

        Repeater {
            model: SystemStats.coreLoads

            RowLayout {
                width: (parent.width - Spacing.popupSectionSpacing) / 2
                spacing: Spacing.popupHeaderSpacing

                Text {
                    font.family: Typography.barFontFamily
                    text: "C" + index
                    font.pointSize: Typography.barFontPointSize
                    font.weight: Font.Medium
                    color: Colors.popupContentFg
                    Layout.preferredWidth: Spacing.coreLabelWidth
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: Spacing.inlineBarHeight
                    radius: height / 2
                    color: Colors.popupBarTrack

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.min(modelData / 100, 1)
                        radius: parent.radius
                        color: Colors.popupBarFill
                    }
                }

                Text {
                    font.family: Typography.barFontFamily
                    text: Math.round(modelData) + "%"
                    font.pointSize: Typography.barFontPointSize - 1
                    color: Colors.popupMuted
                    Layout.preferredWidth: Spacing.corePctWidth
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }

    // ── Info rows ───────────────────────────────────
    ColumnLayout {
        Layout.fillWidth: true
        Layout.topMargin: Spacing.popupSectionSpacing
        spacing: Spacing.popupListSpacing

        PopupInfoRow {
            label: "Frequency"
            value: {
                var freq = SystemStats.cpuFrequency;
                if (freq >= 1000)
                    return (freq / 1000).toFixed(1) + "GHz";
                return Math.round(freq) + "MHz";
            }
        }

        PopupInfoRow {
            label: "Temperature"
            value: Math.round(SystemStats.temperature) + "°C"
            valueColor: SystemStats.temperature > 80 ? Colors.error : Colors.popupContentFg
        }

        PopupInfoRow {
            label: "Load Avg"
            value: SystemStats.loadAverage
        }
    }
}
