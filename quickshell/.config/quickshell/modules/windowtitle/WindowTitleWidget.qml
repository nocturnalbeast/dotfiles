import "../../components/anims"
import "../../services"
import "../../theme"
import QtQuick

Rectangle {
    id: root

    property int maxChars: 45
    property string currentTitle: WmBackend.focusedWindowTitle
    // Displayed text is decoupled from currentTitle — only updated by swapAnim
    property string displayText: ""
    property real titleOpacity: 1.0
    property real titleOffset: 0

    height: Typography.barHeight
    color: Colors.widgetContentBg
    implicitWidth: Math.min(titleLabel.implicitWidth + Spacing.widgetPadding, 400)
    clip: true

    Component.onCompleted: {
        displayText = formatTitle(currentTitle);
        titleOpacity = (!currentTitle || currentTitle === "") ? 0.5 : 1;
    }

    function formatTitle(title) {
        if (!title || title === "")
            return "No window";
        if (title.length > root.maxChars)
            return title.substring(0, root.maxChars) + "...";
        return title;
    }

    onCurrentTitleChanged: {
        titleOffset = -16;
        titleOpacity = 0;
        textSwapTimer.start();
    }

    Timer {
        id: textSwapTimer

        interval: Animations.textSwapDuration + 10
        onTriggered: {
            root.displayText = root.formatTitle(root.currentTitle);
            root.titleOpacity = (!root.currentTitle || root.currentTitle === "") ? 0.5 : 1;
            root.titleOffset = 16;
            titleSlideInTimer.start();
        }
    }

    Timer {
        id: titleSlideInTimer

        interval: 20
        onTriggered: root.titleOffset = 0
    }

    Text {
        id: titleLabel

        anchors.verticalCenter: parent.verticalCenter
        x: Spacing.widgetInnerMargin + root.titleOffset
        font.family: Typography.barFontFamily
        font.pointSize: Typography.barFontPointSize
        color: Colors.widgetContentFg
        text: root.displayText
        opacity: root.titleOpacity

        Behavior on opacity {
            TextSwapFade {}
        }

        Behavior on x {
            TextSwapFade {}
        }
    }
}
