import "../theme"
import QtQuick
import QtQuick.Layouts

// Reusable popup header: centered icon + title + full-width 1px separator
// Maia popover header pattern: title row above, separator spanning full width below
ColumnLayout {
    id: root

    property string iconText: ""
    property string titleText: ""
    property color iconColor: Colors.popupContentFg
    property color titleColor: Colors.popupContentFg

    spacing: 0

    // Centered header row: icon + title
    Row {
        Layout.alignment: Qt.AlignHCenter
        topPadding: Spacing.popupHeaderTopPadding
        bottomPadding: Spacing.popupHeaderBottomPadding
        spacing: Spacing.popupHeaderSpacing

        Text {
            font.family: Typography.barIconFontFamily
            text: root.iconText
            font.pointSize: Typography.popupHeaderIconSize
            color: root.iconColor
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: root.titleText
            font.family: Typography.barFontFamily
            font.pointSize: Typography.popupHeaderSize
            font.weight: Font.Medium
            color: root.titleColor
            verticalAlignment: Text.AlignVCenter
        }
    }

    // Full-width separator (Maia: h-px bg-border/50)
    Rectangle {
        Layout.fillWidth: true
        height: Spacing.popupSeparatorHeight
        color: Colors.popupSeparator
    }
}
