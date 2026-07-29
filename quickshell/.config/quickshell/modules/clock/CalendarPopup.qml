import "../../services"
import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property date currentDate: new Date()

    // Sync with ClockWidget scroll — when offset changes, shift the displayed month
    property bool _syncing: false

    Connections {
        target: Visibility
        function onCalendarMonthOffsetChanged() {
            if (root._syncing)
                return;
            root._syncing = true;
            var today = new Date();
            root.currentDate = new Date(today.getFullYear(), today.getMonth() + Visibility.calendarMonthOffset, 1);
            root._syncing = false;
        }
    }

    function monthName(month) {
        var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
        return months[month];
    }

    function dayName(day) {
        var days = ["S", "M", "T", "W", "T", "F", "S"];
        return days[day];
    }

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function firstDayOfMonth(year, month) {
        return new Date(year, month, 1).getDay();
    }

    function isToday(day) {
        var today = new Date();
        return day === today.getDate() && currentDate.getMonth() === today.getMonth() && currentDate.getFullYear() === today.getFullYear();
    }

    spacing: Spacing.popupSectionSpacing

    PopupHeader {
        iconText: "󰃭"
        titleText: "Calendar"
    }

    Rectangle {
        Layout.fillWidth: true
        height: Spacing.popupButtonHeight
        color: Colors.popupContentBg

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Spacing.popupContentMargin
            anchors.rightMargin: Spacing.popupContentMargin

            PopupButton {
                fixedWidth: Spacing.popupTinyButtonWidth
                label: "◀"
                onClicked: currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1)
            }

            PopupButton {
                label: "Today"
                visible: {
                    var today = new Date();
                    return currentDate.getMonth() !== today.getMonth() || currentDate.getFullYear() !== today.getFullYear();
                }
                onClicked: {
                    Visibility.calendarMonthOffset = 0;
                    currentDate = new Date();
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                height: Spacing.calendarCellHeight
                radius: Spacing.popupRadius
                color: Colors.popupHeaderBg

                Text {
                    font.family: Typography.barFontFamily
                    anchors.centerIn: parent
                    text: monthName(currentDate.getMonth()) + " " + currentDate.getFullYear()
                    font.pointSize: Typography.barFontPointSize
                    font.weight: Font.Medium
                    color: Colors.popupHeaderFg
                    leftPadding: Spacing.calendarMonthPadding
                    rightPadding: Spacing.calendarMonthPadding
                }
            }

            Item {
                Layout.fillWidth: true
            }

            PopupButton {
                fixedWidth: Spacing.popupTinyButtonWidth
                label: "▶"
                onClicked: currentDate = new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1)
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Spacing.popupListSpacing

        Repeater {
            model: 7

            delegate: Rectangle {
                Layout.fillWidth: true
                height: Spacing.calendarCellHeight
                color: Colors.popupHeaderBg

                Text {
                    font.family: Typography.barFontFamily
                    anchors.centerIn: parent
                    text: dayName(index)
                    font.pointSize: Typography.popupMutedSize
                    font.weight: Font.Medium
                    color: Colors.popupHeaderFg
                }
            }
        }
    }

    Grid {
        id: dayGrid

        property int firstDay: firstDayOfMonth(currentDate.getFullYear(), currentDate.getMonth())
        property int numDays: daysInMonth(currentDate.getFullYear(), currentDate.getMonth())

        Layout.fillWidth: true
        Layout.preferredHeight: implicitHeight
        columns: 7
        rowSpacing: Spacing.popupListSpacing
        columnSpacing: Spacing.popupListSpacing

        Repeater {
            model: dayGrid.firstDay + dayGrid.numDays

            delegate: Rectangle {
                width: (dayGrid.width - 6 * dayGrid.columnSpacing) / 7
                height: width * 0.75
                radius: Spacing.popupRadius
                color: {
                    if (index < dayGrid.firstDay)
                        return "transparent";

                    if (isToday(index - dayGrid.firstDay + 1))
                        return Colors.popupHoverBg;

                    if (dayMouse.containsMouse)
                        return Colors.popupContentBg;

                    return "transparent";
                }
                visible: index >= dayGrid.firstDay
                border.color: isToday(index - dayGrid.firstDay + 1) ? Colors.popupSeparator : Colors.popupMuted
                border.width: isToday(index - dayGrid.firstDay + 1) ? Spacing.popupBorderWidth : 0

                Text {
                    font.family: Typography.barFontFamily
                    anchors.centerIn: parent
                    text: index - dayGrid.firstDay + 1
                    font.pointSize: Typography.popupMutedSize
                    color: isToday(index - dayGrid.firstDay + 1) ? Colors.popupHeaderFg : Colors.popupContentFg
                    font.weight: isToday(index - dayGrid.firstDay + 1) ? Font.Medium : Font.Normal
                }

                MouseArea {
                    id: dayMouse

                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: index >= dayGrid.firstDay
                }
            }
        }
    }

    // Middle-click anywhere to reset to today
    MouseArea {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        acceptedButtons: Qt.MiddleButton
        onPressed: function (mouse) {
            mouse.accepted = true;
        }
        onClicked: function (mouse) {
            if (mouse.button === Qt.MiddleButton) {
                Visibility.calendarMonthOffset = 0;
                root.currentDate = new Date();
            }
        }
    }
}
