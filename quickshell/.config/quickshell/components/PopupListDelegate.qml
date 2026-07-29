import "../theme"
import "anims"
import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property alias mouseArea: mouse
    property alias containsMouse: mouse.containsMouse
    property color normalColor: Colors.popupContentBg

    signal clicked

    width: ListView.view ? ListView.view.width : 0
    height: Spacing.popupDelegateHeight
    radius: Spacing.popupRadius
    color: mouse.containsMouse ? Colors.popupHoverBg : root.normalColor
    transformOrigin: Item.TopLeft
    scale: mouse.containsMouse ? 1.02 : 1.0

    Behavior on scale {
        ScaleSpring {}
    }

    default property alias contentData: contentLayout.data

    RowLayout {
        id: contentLayout
        anchors.fill: parent
        anchors.leftMargin: Spacing.popupDelegatePaddingH
        anchors.rightMargin: Spacing.popupDelegatePaddingH
        spacing: Spacing.popupHeaderSpacing
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
