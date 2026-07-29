import "../../theme"
import QtQuick

Rectangle {
    id: button

    property string icon: ""
    property string label: ""
    property string keyHint: ""

    signal triggered

    width: Spacing.sessionButtonSize
    height: Spacing.sessionButtonSize
    color: mouseArea.containsMouse ? Colors.popupButtonHoverBg : Colors.popupButtonBg
    radius: 0

    border.width: button.activeFocus ? Spacing.popupBorderWidth : 0
    border.color: Colors.popupBorder

    scale: mouseArea.containsMouse ? Animations.hoverScale : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Animations.scaleAnimDuration
            easing.type: Easing.OutCubic
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Animations.animDuration
        }
    }

    Behavior on border.width {
        NumberAnimation {
            duration: Animations.animDuration
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        Item {
            width: parent.width
            height: parent.height - labelLabel.height - keyLabel.height - 12

            Text {
                anchors.centerIn: parent
                text: button.icon
                font.family: Typography.barIconFontFamily
                font.pointSize: Typography.bigStatSize
                color: Colors.popupContentFg
            }
        }

        Text {
            id: labelLabel
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: button.label
            font.family: Typography.barFontFamily
            font.pointSize: Spacing.sessionButtonLabelSize
            color: Colors.popupContentFg
        }

        Text {
            id: keyLabel
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            text: button.keyHint
            font.family: Typography.barFontFamily
            font.pointSize: Spacing.sessionButtonKeySize
            color: Colors.popupMuted
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: button.triggered()
    }

    Keys.onEnterPressed: button.triggered()
    Keys.onReturnPressed: button.triggered()
    Keys.onPressed: function (event) {
        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return)
            button.triggered();
    }
}
