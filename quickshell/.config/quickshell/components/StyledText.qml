pragma ComponentBehavior: Bound

import "anims"
import "../theme"
import QtQuick

Text {
    property color themeColor: Colors.widgetContentFg
    color: themeColor
    font.family: Typography.barFontFamily
    font.pointSize: Typography.barFontPointSize
    verticalAlignment: Text.AlignVCenter

    Behavior on color {
        ColorFade {}
    }
}
