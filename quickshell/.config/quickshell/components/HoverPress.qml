pragma ComponentBehavior: Bound

import "anims"
import "../theme"
import QtQuick

// Reusable hover/press scale behavior.
// Apply to any Item to get hoverScale/pressScale animation with auto-reset.
Item {
    id: root

    property bool isPressed: false
    readonly property bool isHovered: hoverHandler.hovered

    scale: {
        if (isPressed)
            return Animations.pressScale;
        if (isHovered)
            return Animations.hoverScale;
        return 1.0;
    }

    HoverHandler {
        id: hoverHandler
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        propagateComposedEvents: true
        onPressed: function (mouse) {
            root.isPressed = true;
            mouse.accepted = false;
            pressReset.start();
        }
        onReleased: function (mouse) {
            root.isPressed = false;
            mouse.accepted = false;
        }
        onClicked: function (mouse) {
            mouse.accepted = false;
        }
    }

    Timer {
        id: pressReset
        interval: 150
        onTriggered: root.isPressed = false
    }

    Behavior on scale {
        ScaleSpring {}
    }
}
