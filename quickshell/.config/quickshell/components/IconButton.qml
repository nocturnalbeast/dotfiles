pragma ComponentBehavior: Bound

import "anims"
import "../theme"
import QtQuick

// Generic icon-only click target with themed styling.
Item {
    id: root

    property string icon: ""
    property string iconFontFamily: Typography.barIconFontFamily
    property int iconPointSize: Typography.barIconPointSize
    property color fgColor: Colors.widgetHeaderFg
    property color hoverBg: Colors.widgetHoverHeaderBg
    property int size: Typography.barHeight

    signal clicked

    implicitWidth: root.size
    implicitHeight: root.size

    Rectangle {
        anchors.fill: parent
        color: mouseArea.containsMouse ? root.hoverBg : "transparent"
        radius: 0

        Text {
            anchors.centerIn: parent
            text: root.icon
            font.family: root.iconFontFamily
            font.pointSize: root.iconPointSize
            color: root.fgColor
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        Behavior on color {
            ColorFade {}
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
