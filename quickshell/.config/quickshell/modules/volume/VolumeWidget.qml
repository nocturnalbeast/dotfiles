import "../../components"
import "../../services"
import "../../theme"
import QtQuick

Item {
    id: root

    property bool hovered: slider.hovered
    property real displayedVolume: 0
    signal clicked

    Component.onCompleted: displayedVolume = AudioService.volume

    Connections {
        target: AudioService
        function onVolumeChanged() {
            root.displayedVolume = AudioService.volume;
        }
    }

    Behavior on displayedVolume {
        NumberAnimation {
            duration: Animations.valueAnimDuration
            easing.type: Easing.OutQuint
        }
    }

    width: slider.width
    height: slider.height

    SliderSegment {
        id: slider

        contentText: AudioService.muted ? "Muted" : Math.round(root.displayedVolume * 100) + "%"
        headerText: AudioService.getVolumeIcon()
        value: AudioService.volume
        showBar: !AudioService.muted
        contentFg: AudioService.volume > 1.005 ? Colors.error : Colors.widgetContentFg
        onClicked: root.clicked()
        onScrollUp: AudioService.increaseVolume()
        onScrollDown: AudioService.decreaseVolume()
        onRightClicked: AudioService.toggleMute()
    }
}
