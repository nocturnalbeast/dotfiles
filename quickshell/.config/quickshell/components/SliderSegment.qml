import "anims"
import QtQuick
import "../theme"

Item {
    id: root

    property string contentText: ""
    property string headerText: ""
    property real value: 0
    property bool showBar: true
    property color contentFg: Colors.widgetContentFg
    property bool hovered: hoverArea.containsMouse

    signal clicked
    signal scrollUp
    signal scrollDown
    signal rightClicked

    // Reversed layout: [content][bar (hover)][header]
    width: contentRect.width + barRect.width + headerRect.width
    height: Typography.barHeight

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onWheel: function (wheel) {
            if (wheel.angleDelta.y > 0)
                root.scrollUp();
            else
                root.scrollDown();
        }
    }

    Rectangle {
        id: contentRect
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: contentLabel.width + Spacing.widgetPadding
        color: root.hovered ? Colors.widgetHoverContentBg : Colors.widgetContentBg

        Text {
            id: contentLabel
            anchors.centerIn: parent
            text: root.contentText
            font.family: Typography.barFontFamily
            font.pointSize: Typography.barFontPointSize
            color: root.contentFg
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: function (mouse) {
                if (mouse.button === Qt.RightButton)
                    root.rightClicked();
                else
                    root.clicked();
            }
        }

        Behavior on color {
            ColorFade {}
        }
    }

    Rectangle {
        id: barRect
        anchors.left: contentRect.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: (root.hovered && root.showBar) ? Spacing.hoverBarWidth : 0
        color: Colors.widgetContentBg
        clip: true

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: function (mouse) {
                if (mouse.button === Qt.RightButton)
                    root.rightClicked();
                else
                    root.clicked();
            }
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: Spacing.inlineBarMargin
            anchors.right: parent.right
            anchors.rightMargin: Spacing.inlineBarMargin
            height: Spacing.inlineBarHeight
            radius: Spacing.inlineBarRadius
            color: Colors.widgetBarTrack

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.min(root.value, 1)
                radius: parent.radius
                color: Colors.widgetBarFill
                Behavior on width {
                    NumberAnimation {
                        duration: Animations.barFillDuration
                        easing.type: Easing.OutQuint
                    }
                }
            }
        }

        Behavior on width {
            NumberAnimation {
                duration: Animations.animDuration
                easing.type: Easing.OutQuad
            }
        }
    }

    Rectangle {
        id: headerRect
        anchors.left: barRect.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: headerLabel.width + Spacing.widgetPadding
        color: root.hovered ? Colors.widgetHoverHeaderBg : Colors.widgetHeaderBg

        Text {
            id: headerLabel
            anchors.centerIn: parent
            text: root.headerText
            font.family: Typography.barIconFontFamily
            font.pointSize: Typography.barIconPointSize
            color: Colors.widgetHeaderFg
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: function (mouse) {
                if (mouse.button === Qt.RightButton)
                    root.rightClicked();
                else
                    root.clicked();
            }
        }

        Behavior on color {
            ColorFade {}
        }
    }
}
