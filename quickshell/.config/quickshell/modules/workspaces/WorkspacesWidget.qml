import "../../services"
import "../../theme"
import "../../components"
import QtQuick

Item {
    id: root

    property var currentWorkspaces: WmBackend.workspaces
    property var focusedWs: {
        var ws = root.currentWorkspaces;
        for (var i = 0; i < ws.length; i++) {
            if (ws[i].focused)
                return ws[i];
        }
        return null;
    }

    signal clicked

    function getWorkspaceIcon(index) {
        var icons = ["", "󰇧", "󰅴", "󰉋", "󰈯", "󰈙", "", "󰇚", "󰓅", ""];
        if (index >= 0 && index < icons.length && icons[index] !== "")
            return icons[index];

        return "";
    }

    // ── Swap animation state ──
    property string displayHeader: ""
    property string displayContent: ""
    property real swapOpacity: 1.0
    property real swapOffset: 0.0
    property bool initialized: false

    function _targetHeader() {
        return root.focusedWs ? (getWorkspaceIcon(root.focusedWs.index) || "") : "";
    }

    function _targetContent() {
        return root.focusedWs ? root.focusedWs.name : "";
    }

    onFocusedWsChanged: {
        if (!initialized)
            return;

        if (displayHeader === _targetHeader() && displayContent === _targetContent())
            return;

        // Fade out + slide left
        swapOpacity = 0;
        swapOffset = -12;
        swapTimer.start();
    }

    Timer {
        id: swapTimer

        interval: Animations.textSwapDuration
        onTriggered: {
            displayHeader = root._targetHeader();
            displayContent = root._targetContent();
            // Slide in from right
            swapOffset = 12;
            swapOpacity = 1;
            // Then snap offset to 0 after fade-in
            resetTimer.start();
        }
    }

    Timer {
        id: resetTimer

        interval: Animations.textSwapDuration
        onTriggered: {
            swapOffset = 0;
        }
    }

    Component.onCompleted: {
        displayHeader = _targetHeader();
        displayContent = _targetContent();
        initialized = true;
    }

    width: wsRow.implicitWidth
    height: wsRow.implicitHeight

    Row {
        id: wsRow

        spacing: 0

        BarSegment {
            visible: root.focusedWs !== null
            headerText: root._targetHeader()
            contentText: root._targetContent()
            displayHeader: root.displayHeader
            displayContent: root.displayContent
            swapOpacity: root.swapOpacity
            swapOffset: root.swapOffset
            contentBg: Colors.widgetFocusedBg
            contentFg: Colors.widgetFocusedFg
            onClicked: root.clicked()
            onScrollUp: {
                if (root.focusedWs && root.focusedWs.index > 0)
                    WmBackend.focusWorkspace(root.focusedWs.index - 1);
            }
            onScrollDown: {
                if (root.focusedWs)
                    WmBackend.focusWorkspace(root.focusedWs.index + 1);
            }
        }
    }
}
