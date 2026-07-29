import "../../services"
import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    spacing: Spacing.popupSectionSpacing

    PopupHeader {
        iconText: BrightnessService.getBrightnessIcon()
        titleText: "Brightness"
    }

    Rectangle {
        Layout.fillWidth: true
        height: Spacing.popupDelegateHeight
        radius: Spacing.popupRadius
        color: Colors.popupContentBg

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Spacing.popupDelegatePaddingH
            anchors.rightMargin: Spacing.popupDelegatePaddingH
            spacing: Spacing.popupSectionSpacing

            Text {
                font.family: Typography.barFontFamily
                text: Math.round(BrightnessService.percentage) + "%"
                font.pointSize: Typography.popupSubHeaderSize
                font.weight: Font.Medium
                color: Colors.popupContentFg
                Layout.alignment: Qt.AlignVCenter
            }

            PopupSlider {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                value: BrightnessService.percentage
                fullValue: 100
                onMoved: function (val) {
                    BrightnessService.setBrightness(val);
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Spacing.popupButtonSpacing

        Repeater {
            model: [25, 50, 75, 100]

            PopupButton {
                Layout.fillWidth: true
                label: modelData + "%"
                onClicked: BrightnessService.setBrightness(modelData)
            }
        }
    }
}
