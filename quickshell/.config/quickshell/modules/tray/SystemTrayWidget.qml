import "../../theme"
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root

    property bool trayAvailable: false
    property var barWindow: null

    width: trayRow.implicitWidth
    height: Typography.barHeight
    Component.onCompleted: {
        trayAvailable = typeof SystemTray !== "undefined" && typeof SystemTray.items !== "undefined";
    }

    Row {
        id: trayRow

        Repeater {
            model: trayAvailable ? SystemTray.items : []

            delegate: Rectangle {
                id: trayItem
                width: Spacing.trayItemWidth
                height: Typography.barHeight
                color: mouse.containsMouse ? Colors.widgetHoverHeaderBg : Colors.widgetHeaderBg

                IconImage {
                    anchors.centerIn: parent
                    width: Spacing.trayIconSize
                    height: Spacing.trayIconSize
                    source: modelData.icon
                }

                QsMenuAnchor {
                    id: menuAnchor
                    menu: modelData.menu
                    anchor {
                        item: trayItem
                        edges: Edges.Bottom | Edges.Right
                        gravity: Edges.Bottom | Edges.Left
                        adjustment: PopupAdjustment.Flip | PopupAdjustment.SlideX
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: event => {
                        if (event.button === Qt.LeftButton) {
                            modelData.activate();
                        } else if (event.button === Qt.RightButton && modelData.hasMenu) {
                            menuAnchor.open();
                        }
                    }
                }
            }
        }

        Text {
            visible: !trayAvailable || SystemTray.items.count === 0
            text: "Tray"
            font.family: Typography.barFontFamily
            font.pointSize: Typography.barFontPointSize
            color: Colors.widgetContentFg
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
