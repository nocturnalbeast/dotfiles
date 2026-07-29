import "../theme"
import QtQuick

// Minimalistic progress bar matching bar segment styling
// headerBg color for track, contentBg for fill
Rectangle {
    id: root

    property real value: 0 // 0.0 to 1.0
    property real fullValue: 1 // max value
    property int barHeight: Spacing.inlineBarHeight
    property bool showHandle: true

    signal moved(real newValue)

    height: barHeight + (showHandle ? Spacing.sliderHandlePadding : 0)
    color: "transparent"

    Rectangle {
        id: track

        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: root.barHeight
        radius: height / 2
        color: Colors.popupBarTrack

        Rectangle {
            id: fill

            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(parent.height, parent.width * Math.min(root.value / root.fullValue, 1))
            radius: parent.radius
            color: Colors.popupBarFill
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: function (mouse) {
            var pct = mouse.x / width;
            root.moved(Math.max(0, Math.min(1, pct)) * root.fullValue);
        }
        onPositionChanged: function (mouse) {
            if (pressed) {
                var pct = mouse.x / width;
                root.moved(Math.max(0, Math.min(1, pct)) * root.fullValue);
            }
        }
    }
}
