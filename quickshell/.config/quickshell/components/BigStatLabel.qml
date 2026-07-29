import "../theme"
import QtQuick
import QtQuick.Layouts

Text {
    id: root

    property real errorThreshold: -1
    property real errorValue: 0
    property bool errorWhenBelow: false

    Layout.fillWidth: true
    Layout.topMargin: Spacing.popupSectionSpacing
    horizontalAlignment: Text.AlignHCenter
    font.family: Typography.barFontFamily
    font.pointSize: Typography.bigStatSize
    font.weight: Font.Medium
    color: {
        if (root.errorThreshold < 0)
            return Colors.popupContentFg;
        if (root.errorWhenBelow)
            return root.errorValue < root.errorThreshold ? Colors.error : Colors.popupContentFg;
        return root.errorValue > root.errorThreshold ? Colors.error : Colors.popupContentFg;
    }
}
