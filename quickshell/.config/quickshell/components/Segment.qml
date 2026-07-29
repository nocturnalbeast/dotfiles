pragma ComponentBehavior: Bound

import "anims"
import "../theme"
import QtQuick

Rectangle {
    id: root

    // Theming
    property color normalBg: Colors.widgetContentBg
    property color hoverBg: Colors.widgetHoverContentBg
    property int padding: Spacing.widgetPadding / 2

    // Hover state — set externally by parent
    property bool hovered: false

    // Text convenience (use when content is simple text)
    property string text: ""
    property string fontFamily: Typography.barFontFamily
    property real fontPointSize: Typography.barFontPointSize
    property color textColor: Colors.widgetContentFg
    property alias textWeight: label.font.weight

    // Custom content — children override text display
    default property alias contentChildren: contentSlot.data

    // Layout
    implicitHeight: Typography.barHeight
    implicitWidth: text !== "" ? label.width + padding * 2 : 0

    color: hovered ? hoverBg : normalBg

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        font.family: root.fontFamily
        font.pointSize: root.fontPointSize
        color: root.textColor
        visible: root.text !== ""
    }

    Item {
        id: contentSlot

        anchors.fill: parent
    }

    Behavior on color {
        ColorFade {}
    }
}
