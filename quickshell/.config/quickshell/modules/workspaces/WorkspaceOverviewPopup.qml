import "../../services"
import "../../theme"
import "../../components"
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    function getWorkspaces() {
        return WmBackend.workspaces || [];
    }

    spacing: Spacing.popupSectionSpacing

    PopupHeader {
        iconText: "󰍺"
        titleText: "Workspaces"
    }

    GridView {
        Layout.fillWidth: true
        Layout.preferredHeight: contentHeight
        cellWidth: Spacing.workspaceCellWidth
        cellHeight: Spacing.workspaceCellHeight
        model: getWorkspaces()

        delegate: Rectangle {
            width: GridView.view.cellWidth - Spacing.workspaceIndicatorMargin
            height: GridView.view.cellHeight - 4
            radius: Spacing.popupRadius
            color: {
                if (modelData.focused)
                    return Colors.popupHoverBg;

                if (wsMouse.containsMouse)
                    return Colors.popupContentBg;

                return "transparent";
            }
            border.color: modelData.occupied ? Colors.popupMuted : "transparent"
            border.width: Spacing.popupBorderWidth

            Text {
                font.family: Typography.barFontFamily
                anchors.centerIn: parent
                text: modelData.name
                font.pointSize: Typography.barFontPointSize
                font.weight: modelData.focused ? Font.Medium : Font.Normal
                color: modelData.focused ? Colors.popupContentFg : Colors.popupMuted
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: Spacing.workspaceIndicatorMargin
                width: Spacing.workspaceIndicatorWidth
                height: Spacing.popupSeparatorHeight
                color: Colors.popupContentFg
                visible: modelData.focused
            }

            MouseArea {
                id: wsMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: WmBackend.focusWorkspace(modelData.index)
            }
        }
    }
}
