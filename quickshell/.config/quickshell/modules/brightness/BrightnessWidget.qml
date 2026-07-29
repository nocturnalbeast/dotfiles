import "../../components"
import "../../services"
import "../../theme"
import QtQuick

Item {
    id: root

    property bool hovered: slider.hovered
    property real displayedBrightness: 0
    signal clicked
    visible: BrightnessService.available

    Component.onCompleted: {
        displayedBrightness = BrightnessService.percentage;
    }

    PollRef {
        service: BrightnessService
    }

    Connections {
        target: BrightnessService
        function onPercentageChanged() {
            root.displayedBrightness = BrightnessService.percentage;
        }
    }

    Behavior on displayedBrightness {
        NumberAnimation {
            duration: Animations.valueAnimDuration
            easing.type: Easing.OutQuint
        }
    }

    width: slider.width
    height: slider.height

    SliderSegment {
        id: slider

        contentText: Math.round(root.displayedBrightness) + "%"
        headerText: BrightnessService.getBrightnessIcon()
        value: BrightnessService.percentage / 100
        showBar: true
        contentFg: Colors.widgetContentFg
        onClicked: root.clicked()
        onScrollUp: BrightnessService.increaseBrightness()
        onScrollDown: BrightnessService.decreaseBrightness()
        onRightClicked: BrightnessService.toggleNightLight()
    }
}
