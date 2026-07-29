import "../components/anims"
import "../theme"
import QtQuick

Item {
    id: root

    property color headerBg: Colors.widgetHeaderBg
    property color contentBg: Colors.widgetContentBg
    property color headerFg: Colors.widgetHeaderFg
    property color contentFg: Colors.widgetContentFg
    property string headerText: ""
    property string contentText: ""
    property int headerPadding: Spacing.widgetPadding / 2
    property int contentPadding: Spacing.widgetPadding / 2
    property bool reversed: false
    property bool interactive: true

    // Text swap animation — driven by parent
    property string displayHeader: headerText
    property string displayContent: contentText
    property real swapOpacity: 1.0
    property real swapOffset: 0.0

    signal clicked
    signal rightClicked
    signal scrollUp
    signal scrollDown

    implicitWidth: headerRect.width + contentRect.width
    implicitHeight: Typography.barHeight

    // HoverHandler for reliable hover detection (handles focus loss
    // when FocusGrab backdrop intercepts input — MouseArea can get stuck)
    HoverHandler {
        id: hoverHandler
    }

    // Normal:   [header][content] — header anchored left, content right of it
    // Reversed: [content][header] — content anchored left, header right of it
    Rectangle {
        id: headerRect

        x: reversed ? contentRect.width : 0
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: headerText === "" ? 0 : (headerLabel.width + headerPadding * 2)
        color: (!root.interactive || !hoverHandler.hovered) ? headerBg : Colors.widgetHoverHeaderBg
        radius: 0

        Text {
            id: headerLabel

            anchors.centerIn: parent
            text: root.displayHeader
            font.family: Typography.barIconFontFamily
            font.pointSize: Typography.barIconPointSize
            color: headerFg
            opacity: root.swapOpacity
            visible: root.displayHeader !== ""

            Behavior on opacity {
                TextSwapFade {}
            }
        }

        Behavior on color {
            ColorFade {}
        }
    }

    Rectangle {
        id: contentRect

        x: reversed ? 0 : headerRect.width
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: contentText === "" ? 0 : (contentLabel.width + contentPadding * 2)
        color: (!root.interactive || !hoverHandler.hovered) ? contentBg : Colors.widgetHoverContentBg
        radius: 0

        Text {
            id: contentLabel

            anchors.centerIn: parent
            text: root.displayContent
            font.family: Typography.barFontFamily
            font.pointSize: Typography.barFontPointSize
            color: contentFg
            opacity: root.swapOpacity
            visible: root.displayContent !== ""

            Behavior on opacity {
                TextSwapFade {}
            }
        }

        Behavior on color {
            ColorFade {}
        }
    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        enabled: root.interactive
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: function (mouse) {
            if (mouse.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
        onWheel: function (wheel) {
            if (wheel.angleDelta.y > 0)
                root.scrollUp();
            else
                root.scrollDown();
        }
        hoverEnabled: root.interactive
        cursorShape: root.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
