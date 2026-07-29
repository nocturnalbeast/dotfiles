import "../theme"
import QtQuick
import QtQuick.Layouts

// Reusable popup button: Maia outline variant with hover state
// Default: subtle tinted bg + border. Hover: slightly brighter bg.
Rectangle {
    id: root

    property string label: ""
    property bool iconFont: false
    property real fixedWidth: -1 // -1 = fill width
    property color borderColor: Colors.popupBorder
    property color textColor: Colors.popupContentFg
    property real buttonHeight: Spacing.popupButtonHeight
    property real buttonRadius: Spacing.popupRadius

    signal clicked

    Layout.fillWidth: fixedWidth < 0
    width: fixedWidth >= 0 ? fixedWidth : undefined
    height: buttonHeight
    radius: buttonRadius
    color: btnMouse.containsMouse ? Colors.popupButtonHoverBg : Colors.popupButtonBg
    border.color: root.borderColor
    border.width: Spacing.popupBorderWidth

    Text {
        anchors.centerIn: parent
        width: root.width - Spacing.popupBorderWidth * 2 - Spacing.popupDelegatePaddingH
        text: root.label
        font.family: root.iconFont ? Typography.barIconFontFamily : Typography.barFontFamily
        font.pointSize: Typography.barFontPointSize
        color: root.textColor
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }

    MouseArea {
        id: btnMouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
