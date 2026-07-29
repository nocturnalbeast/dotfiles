import "../theme"
import QtQuick

// Seamless looping marquee text. Two copies of the text sit in a Row;
// a Timer steps the x position left each tick. When the first copy scrolls
// fully off-screen the second copy is in exactly the same visual position,
// so resetting x by one cycle-width is invisible → seamless infinite loop.
//
// Usage:
//   MarqueeText {
//       maxWidth: 120
//       text: "Very Long Artist Name"
//       font.family: Typography.barFontFamily
//       font.pointSize: Typography.barFontPointSize
//       color: Colors.widgetContentFg
//   }

Item {
    id: root

    property string text: ""
    property alias font: label.font
    property color color: "white"
    property real maxWidth: 120
    property int scrollSpacing: 40          // gap between text copies
    property int pauseDuration: 1500        // pause at initial position (ms)
    property int tickInterval: 16           // ~60 fps
    property int scrollSpeed: 40            // pixels per second

    readonly property real contentWidth: label.implicitWidth
    readonly property bool overflow: contentWidth > maxWidth

    implicitWidth: overflow ? maxWidth : contentWidth
    implicitHeight: label.implicitHeight
    clip: true

    // ── Scroll state machine ──

    enum State {
        Idle,
        Pausing,
        Scrolling
    }

    property int _state: MarqueeText.State.Idle

    function _reset() {
        _state = MarqueeText.State.Idle;
        row.x = 0;
    }

    function _restart() {
        _reset();
        if (overflow)
            _state = MarqueeText.State.Pausing;
    }

    onTextChanged: _restart()
    onOverflowChanged: {
        if (!overflow)
            _reset();
        else
            _restart();
    }
    Component.onCompleted: {
        if (overflow)
            _state = MarqueeText.State.Pausing;
    }

    // ── Pause timer (delay before each scroll cycle) ──

    Timer {
        id: pauseTimer
        interval: root.pauseDuration
        running: root._state === MarqueeText.State.Pausing
        onTriggered: root._state = MarqueeText.State.Scrolling
    }

    // ── Scroll tick timer ──

    Timer {
        id: scrollTimer
        interval: root.tickInterval
        repeat: true
        running: root._state === MarqueeText.State.Scrolling
        onTriggered: {
            var cycleW = label.width + row.spacing;
            if (cycleW <= 0)
                return;
            var step = root.scrollSpeed * (interval / 1000);
            row.x -= step;
            if (row.x <= -cycleW) {
                row.x += cycleW;  // seamless wrap
                root._state = MarqueeText.State.Pausing;  // pause before next cycle
            }
        }
    }

    // ── Row with two text copies ──

    Row {
        id: row
        height: parent.height
        spacing: root.scrollSpacing

        Text {
            id: label
            text: root.text
            font.family: Typography.barFontFamily
            color: root.color
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            text: root.text
            font: label.font
            color: label.color
            verticalAlignment: Text.AlignVCenter
            visible: root._state !== MarqueeText.State.Idle
        }
    }
}
