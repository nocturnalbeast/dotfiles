import "../components/anims"
import "../services"
import "../theme"
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool showLabel: false
    property color bgColor: Colors.widgetHeaderBg
    property color fgColor: Colors.widgetHeaderFg
    property bool hovered: mouseArea.containsMouse
    property Item anchorItem: root

    signal clicked

    color: hovered ? Colors.widgetHoverHeaderBg : bgColor
    implicitWidth: row.width + Spacing.widgetPadding
    implicitHeight: Typography.barHeight

    Row {
        id: row

        anchors.verticalCenter: parent.verticalCenter
        x: Spacing.widgetInnerMargin
        spacing: Spacing.iconLabelSpacing

        Text {
            text: icon
            visible: icon !== ""
            font.family: Typography.barIconFontFamily
            font.pointSize: Typography.barIconPointSize
            color: fgColor
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: label
            visible: showLabel && label !== ""
            font.family: Typography.barFontFamily
            font.pointSize: Typography.barFontPointSize
            color: fgColor
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    Behavior on color {
        ColorFade {}
    }
}
