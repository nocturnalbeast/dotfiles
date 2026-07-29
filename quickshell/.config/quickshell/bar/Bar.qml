import Quickshell
import QtQuick
import "../components/anims"
import "../theme"
import "../services"

PanelWindow {
    id: bar
    property int activeBar: Visibility.activeBar

    anchors {
        top: true
        left: true
        right: true
    }

    // Dynamic sizing based on screen dimensions
    // Per-screen bar height computed locally (Typography.barHeight uses primary screen)
    readonly property int computedBarHeight: Math.round(screen.height * Typography.barHeightPct / 100)

    implicitHeight: computedBarHeight + Shadows.barShadowBlur
    exclusiveZone: computedBarHeight + wmOuterGap
    color: "transparent"
    aboveWindows: false

    // Fullscreen handling: animate bar sliding off-screen.
    // PanelWindow.visible toggle causes malloc corruption —
    // instead, slide a child wrapper off-screen via negative topMargin.
    property bool _shouldHide: {
        if (Visibility.manualHidden)
            return true;
        if (WmBackend.hasFullscreen)
            return true;
        return false;
    }

    // Margins: equal padding on all sides from WM outer gap
    property int wmOuterGap: WindowGapService.windowGap

    margins {
        left: wmOuterGap
        right: wmOuterGap
        top: wmOuterGap
        bottom: -Shadows.barShadowBlur
    }

    // Bar content wrapper — this is what slides on/off screen
    Item {
        id: barContent
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        height: bar.computedBarHeight

        // Slide off-screen when fullscreen app detected
        anchors.topMargin: bar._shouldHide ? -height : 0

        Behavior on anchors.topMargin {
            SlideY {}
        }

        // ── Empty-bar-area scroll ──
        // Scroll → cycle workspaces, Shift+Scroll → cycle windows.
        // Only fires when NOT over a module widget (over separator or empty gap).
        // If over a module, event.accepted = false lets it propagate to the module.
        // Note: horizontal scroll (tilt-wheel / buttons 6-7) is NOT translated to
        // wheel events by Quickshell on X11, so Shift+vertical is used instead.
        WheelHandler {
            target: barContent
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad

            onWheel: function (event) {
                var loader = (Visibility.activeBar === 0) ? mainLoader : monLoader;
                if (!loader || !loader.item)
                    return;

                // Map event position to BarLayout coordinates
                var lp = barContent.mapToItem(loader.item, event.x, event.y);
                var row = loader.item.childAt(lp.x, lp.y);

                if (row) {
                    // Found a Row — check if we're over a module or separator
                    var rp = loader.item.mapToItem(row, lp.x, lp.y);
                    var child = row.childAt(rp.x, rp.y);
                    // Separators are 4px wide; modules are wider
                    if (child && child.width > Spacing.separatorWidth) {
                        // Over a module — let the module handle the wheel event
                        event.accepted = false;
                        return;
                    }
                }

                // Empty area or separator — handle bar-level scroll
                var delta = event.angleDelta.y || event.angleDelta.x || event.pixelDelta.y || event.pixelDelta.x;
                if (delta === 0)
                    return;

                if (event.modifiers & Qt.ShiftModifier) {
                    // Shift+Scroll → window cycling
                    WmBackend.cycleWindow(delta > 0 ? -1 : 1);
                } else {
                    // Scroll → workspace cycling
                    var ws = WmBackend.workspaces;
                    var idx = -1;
                    for (var i = 0; i < ws.length; i++) {
                        if (ws[i].focused) {
                            idx = i;
                            break;
                        }
                    }
                    if (idx >= 0) {
                        if (delta > 0 && idx > 0)
                            WmBackend.focusWorkspace(idx - 1);
                        else if (delta < 0 && idx < ws.length - 1)
                            WmBackend.focusWorkspace(idx + 1);
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            visible: Visibility.activeBarPopup !== null
            z: 0
            onClicked: Visibility.closeAllBarPopups()
        }

        Item {
            id: layoutSwitcher
            z: 1
            anchors.fill: parent

            Loader {
                id: mainLoader
                x: 0
                width: parent.width
                height: parent.height
                active: Visibility.activeBar === 0
                sourceComponent: BarLayout {
                    mode: 0
                    barWindow: bar
                }

                opacity: Visibility.activeBar === 0 ? 1 : 0
                y: Visibility.activeBar === 0 ? 0 : -20

                Behavior on opacity {
                    NumberAnimation {
                        duration: Animations.barSlideDuration
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on y {
                    SlideY {}
                }
            }

            Loader {
                id: monLoader
                x: 0
                width: parent.width
                height: parent.height
                active: Visibility.activeBar === 1
                sourceComponent: BarLayout {
                    mode: 1
                    barWindow: bar
                }

                opacity: Visibility.activeBar === 1 ? 1 : 0
                y: Visibility.activeBar === 1 ? 0 : 20

                Behavior on opacity {
                    NumberAnimation {
                        duration: Animations.barSlideDuration
                        easing.type: Easing.OutCubic
                    }
                }
                Behavior on y {
                    SlideY {}
                }
            }
        }
    }
}
