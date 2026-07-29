import "../../services"
import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Spacing.popupSectionSpacing

    function formatTime(date) {
        if (!date)
            return "N/A";
        return date.toLocaleTimeString(Qt.locale(), "HH:mm");
    }

    PopupHeader {
        iconText: WeatherService.currentIcon
        titleText: "Weather"
    }

    // Location + last updated
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Spacing.popupContentMargin
        Layout.rightMargin: Spacing.popupContentMargin

        Text {
            text: WeatherService.cityName
            font.family: Typography.barFontFamily
            font.pointSize: Typography.popupMutedSize
            font.weight: Font.Medium
            color: Colors.popupContentFg
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            text: "Updated " + formatTime(WeatherService.lastUpdated)
            font.family: Typography.barFontFamily
            font.pointSize: Typography.popupTinySize
            color: Colors.popupMuted
        }
    }

    // Current conditions card
    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: Spacing.popupContentMargin
        Layout.rightMargin: Spacing.popupContentMargin
        Layout.preferredHeight: 80
        color: Colors.popupContentBg
        radius: Spacing.popupRadius

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Spacing.popupContentMargin
            anchors.rightMargin: Spacing.popupDelegatePaddingH

            Text {
                text: WeatherService.currentIcon
                font.family: Typography.barIconFontFamily
                font.pointSize: Typography.popupHeaderIconSize + 24
                color: Colors.popupContentFg
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: WeatherService.tempString(WeatherService.currentTemp)
                    font.family: Typography.barFontFamily
                    font.pointSize: Typography.bigStatSize
                    font.weight: Font.Medium
                    color: Colors.popupContentFg
                }

                Text {
                    text: WeatherService.currentCondition
                    font.family: Typography.barFontFamily
                    font.pointSize: Typography.popupMutedSize
                    color: Colors.popupMuted
                }

                Text {
                    text: "Feels like " + WeatherService.tempString(WeatherService.currentFeelsLike)
                    font.family: Typography.barFontFamily
                    font.pointSize: Typography.popupTinySize
                    color: Colors.popupMuted
                }
            }
        }
    }

    // Stats row
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Spacing.popupContentMargin
        Layout.rightMargin: Spacing.popupContentMargin
        spacing: Spacing.popupButtonSpacing

        PopupInfoRow {
            Layout.fillWidth: true
            label: "󰖎 Humidity"
            value: WeatherService.currentHumidity + "%"
        }

        PopupInfoRow {
            Layout.fillWidth: true
            label: "󰖝 Wind"
            value: WeatherService.currentWindSpeed.toFixed(1) + " km/h"
        }
    }

    // Separator
    Rectangle {
        Layout.fillWidth: true
        height: Spacing.popupSeparatorHeight
        color: Colors.popupSeparator
    }

    // 7-day forecast header
    Text {
        text: "7-Day Forecast"
        font.family: Typography.barFontFamily
        font.pointSize: Typography.popupMutedSize
        font.weight: Font.Medium
        color: Colors.popupMuted
        Layout.leftMargin: Spacing.popupContentMargin
    }

    // Forecast grid
    ColumnLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Spacing.popupContentMargin
        Layout.rightMargin: Spacing.popupContentMargin
        spacing: Spacing.popupButtonSpacing

        Repeater {
            model: WeatherService.forecast

            delegate: Rectangle {
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredHeight: Spacing.popupDelegateHeight
                color: Colors.popupContentBg
                radius: Spacing.popupRadius

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Spacing.popupDelegatePaddingH
                    anchors.rightMargin: Spacing.popupDelegatePaddingH

                    Text {
                        text: modelData.dayName
                        font.family: Typography.barFontFamily
                        font.pointSize: Typography.popupMutedSize
                        font.weight: Font.Medium
                        color: Colors.popupContentFg
                        Layout.preferredWidth: 40
                    }

                    Text {
                        text: modelData.icon
                        font.family: Typography.barIconFontFamily
                        font.pointSize: Typography.barIconPointSize
                        color: Colors.popupContentFg
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: WeatherService.tempString(modelData.high)
                        font.family: Typography.barFontFamily
                        font.pointSize: Typography.popupMutedSize
                        font.weight: Font.Medium
                        color: Colors.popupContentFg
                    }

                    Text {
                        text: WeatherService.tempString(modelData.low)
                        font.family: Typography.barFontFamily
                        font.pointSize: Typography.popupTinySize
                        color: Colors.popupMuted
                    }
                }
            }
        }
    }
}
