import "../../components"
import "../../services"
import QtQuick

Item {
    id: root

    signal clicked
    visible: WeatherService.ready

    PollRef {
        service: WeatherService
    }

    width: seg.implicitWidth
    height: seg.implicitHeight

    BarSegment {
        id: seg

        reversed: true
        headerText: WeatherService.currentIcon
        contentText: WeatherService.tempString(WeatherService.currentTemp)
        onClicked: root.clicked()
        onScrollUp: WeatherService.refresh()
        onScrollDown: WeatherService.refresh()
    }
}
