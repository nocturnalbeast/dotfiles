import QtQuick
import "../../theme"
import "../../services"

Item {
    id: root

    property var _buttons: [lockBtn, suspendBtn, rebootBtn, shutdownBtn, logoutBtn]

    Connections {
        target: SessionService
        function onOpenChanged() {
            if (SessionService.open) {
                Qt.callLater(function () {
                    lockBtn.forceActiveFocus();
                });
            }
        }
    }

    MouseArea {
        id: backdrop
        anchors.fill: parent
        visible: SessionService.open
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: SessionService.close()

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: SessionService.open ? 0.6 : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: Animations.sessionBackdropDuration
                    easing.type: Easing.OutCubic
                }
            }
        }

        Item {
            id: contentBlock
            anchors.centerIn: parent
            width: 3 * Spacing.sessionButtonSize + 2 * Spacing.sessionGridSpacing + 48
            height: titleText.height + subtitleText.height + buttonGrid.height + hintText.height + 64
            focus: true

            Keys.onPressed: function (event) {
                if (!SessionService.open)
                    return;

                if (event.key === Qt.Key_Escape) {
                    SessionService.close();
                    event.accepted = true;
                    return;
                }

                var focusedIndex = -1;
                for (var i = 0; i < _buttons.length; i++) {
                    if (_buttons[i].activeFocus) {
                        focusedIndex = i;
                        break;
                    }
                }

                if (event.key === Qt.Key_Left) {
                    var next = focusedIndex <= 0 ? _buttons.length - 1 : focusedIndex - 1;
                    _buttons[next].forceActiveFocus();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right) {
                    var next2 = focusedIndex >= _buttons.length - 1 ? 0 : focusedIndex + 1;
                    _buttons[next2].forceActiveFocus();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    if (focusedIndex >= Spacing.sessionGridColumns) {
                        _buttons[focusedIndex - Spacing.sessionGridColumns].forceActiveFocus();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    if (focusedIndex >= 0 && focusedIndex + Spacing.sessionGridColumns < _buttons.length) {
                        _buttons[focusedIndex + Spacing.sessionGridColumns].forceActiveFocus();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_L) {
                    SessionService.lock();
                    event.accepted = true;
                } else if (event.key === Qt.Key_S) {
                    SessionService.suspend();
                    event.accepted = true;
                } else if (event.key === Qt.Key_R) {
                    SessionService.reboot();
                    event.accepted = true;
                } else if (event.key === Qt.Key_P) {
                    SessionService.shutdown();
                    event.accepted = true;
                } else if (event.key === Qt.Key_X) {
                    SessionService.logout();
                    event.accepted = true;
                }
            }

            Text {
                id: titleText
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Session"
                font.family: Typography.barFontFamily
                font.pointSize: Typography.clockTimePt * 0.5
                font.weight: Font.Bold
                color: Colors.popupContentFg
                opacity: SessionService.open ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Animations.sessionBackdropDuration
                    }
                }
            }

            Text {
                id: subtitleText
                anchors.top: titleText.bottom
                anchors.topMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter
                text: "What would you like to do?"
                font.family: Typography.barFontFamily
                font.pointSize: Typography.popupHeaderSize
                color: Colors.popupMuted
                opacity: SessionService.open ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Animations.sessionBackdropDuration
                    }
                }
            }

            Grid {
                id: buttonGrid
                anchors.top: subtitleText.bottom
                anchors.topMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                columns: Spacing.sessionGridColumns
                spacing: Spacing.sessionGridSpacing
                horizontalItemAlignment: Grid.AlignHCenter

                SessionButton {
                    id: lockBtn
                    icon: "󰌾"
                    label: "Lock"
                    keyHint: "L"
                    onTriggered: SessionService.lock()
                }
                SessionButton {
                    id: suspendBtn
                    icon: "󰏦"
                    label: "Suspend"
                    keyHint: "S"
                    onTriggered: SessionService.suspend()
                }
                SessionButton {
                    id: rebootBtn
                    icon: "󰜉"
                    label: "Reboot"
                    keyHint: "R"
                    onTriggered: SessionService.reboot()
                }
                SessionButton {
                    id: shutdownBtn
                    icon: "󰐥"
                    label: "Shutdown"
                    keyHint: "P"
                    onTriggered: SessionService.shutdown()
                }
                SessionButton {
                    id: logoutBtn
                    icon: "󰗹"
                    label: "Logout"
                    keyHint: "X"
                    onTriggered: SessionService.logout()
                }
            }

            Text {
                id: hintText
                anchors.top: buttonGrid.bottom
                anchors.topMargin: 20
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Press ESC to cancel"
                font.family: Typography.barFontFamily
                font.pointSize: Typography.popupMutedSize
                color: Colors.popupMuted
                opacity: SessionService.open ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Animations.sessionBackdropDuration
                    }
                }
            }
        }
    }
}
