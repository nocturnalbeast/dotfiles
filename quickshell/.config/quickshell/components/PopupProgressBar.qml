import "../theme"
import QtQuick

Rectangle {
    id: root

    property real value: 0
    property real threshold: -1
    property bool errorWhenBelow: false
    property color trackColor: Colors.popupBarTrack
    property color fillColor: Colors.popupBarFill

    height: Spacing.inlineBarHeight
    radius: height / 2
    color: root.trackColor

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * Math.min(root.value, 1)
        radius: parent.radius
        color: {
            if (root.threshold < 0)
                return root.fillColor;
            if (root.errorWhenBelow)
                return root.value < root.threshold ? Colors.error : root.fillColor;
            return root.value > root.threshold ? Colors.error : root.fillColor;
        }
    }
}
