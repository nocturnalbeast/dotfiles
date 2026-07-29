import "../theme"
import QtQuick

QtObject {
    id: root

    property Transition addTransition: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Animations.popupAnimDuration
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "scale"
                from: 0.95
                to: 1
                duration: Animations.popupAnimDuration
                easing.type: Easing.OutCubic
            }
        }
    }

    property Transition removeTransition: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: Animations.popupAnimDuration
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                property: "scale"
                to: 0.95
                duration: Animations.popupAnimDuration
                easing.type: Easing.InCubic
            }
        }
    }

    property Transition displacedTransition: Transition {
        NumberAnimation {
            property: "y"
            duration: Animations.popupAnimDuration
            easing.type: Easing.OutCubic
        }
    }
}
