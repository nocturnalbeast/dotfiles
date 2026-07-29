pragma ComponentBehavior: Bound

import "anims"
import "../theme"
import QtQuick

Rectangle {
    property color themeColor: Colors.widgetContentBg
    color: themeColor

    Behavior on color {
        ColorFade {}
    }
}
