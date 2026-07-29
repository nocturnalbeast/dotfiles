import "../theme"
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: ""
    property string value: ""
    property color labelColor: Colors.popupMuted
    property color valueColor: Colors.popupContentFg

    Layout.fillWidth: true
    height: Spacing.popupDelegateHeight
    color: Colors.popupContentBg
    radius: Spacing.popupRadius

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Spacing.popupDelegatePaddingH
        anchors.rightMargin: Spacing.popupDelegatePaddingH

        Text {
            text: root.label
            color: root.labelColor
            font.family: Typography.barFontFamily
            font.pointSize: Typography.barFontPointSize
        }

        Item {
            Layout.fillWidth: true
        }

        Text {
            text: root.value
            color: root.valueColor
            font.family: Typography.barFontFamily
            font.pointSize: Typography.barFontPointSize
            font.weight: Font.Medium
        }
    }
}
