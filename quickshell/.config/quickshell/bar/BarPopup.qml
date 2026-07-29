import "../components/anims"
import "../components"
import "../services"
import "../theme"
import QtQuick
import QtQuick.Effects
import Quickshell

// Reusable popup wrapper for bar module popups.
// Uses opacity + scale animation (Axenide/Ambxst pattern).
// Height is dynamic: shrinks to fit content, capped at popupHeight.
// If content exceeds popupHeight, it scrolls inside a Flickable.
// Usage: BarPopup { anchorItem: someBarItem; barWindow: bar; contentComponent: comp }
Item {
    id: root

    // The bar module item to anchor the popup below
    property Item anchorItem: parent
    // Optional: override anchor rect for sub-element centering
    // When set (x >= 0), these replace the default full-item anchor rect
    property real anchorOverrideX: -1
    property real anchorOverrideWidth: -1
    // The PanelWindow (Bar.qml) — must be set by the parent layout
    property var barWindow: null
    // The popup's content component
    property Component contentComponent: null
    // Width: screen-percentage for uniform appearance across monitors
    readonly property real popupWidth: barWindow ? Math.round(barWindow.screen.width * Spacing.popupWidthPct / 100) : 320
    // When true, popup content is only created when the popup is visible,
    // deferring initial creation and freeing memory when closed.
    // The PopupWindow stays persistent (no flicker); only the inner content is lazy.
    property bool lazyContent: false

    signal popupOpened
    signal popupClosed

    function open() {
        popupOpacity = 0;
        popupScale = 0.95;
        Qt.callLater(function () {
            popupWindow.visible = true;
            Visibility.registerBarPopup(root);
            popupOpacity = 1;
            popupScale = 1;
        });
        popupOpened();
    }

    function close() {
        popupOpacity = 0;
        popupScale = 0.95;
        closeTimer.restart();
        popupClosed();
    }

    function toggle() {
        if (popupWindow.visible && isOpen)
            close();
        else
            open();
    }

    // Animation state
    property real popupOpacity: 0
    property real popupScale: 0.95

    readonly property bool isOpen: popupWindow.visible

    Timer {
        id: closeTimer

        interval: Animations.popupAnimDuration + 20
        onTriggered: {
            popupWindow.visible = false;
        }
    }

    PopupWindow {
        id: popupWindow

        visible: false
        implicitWidth: root.popupWidth
        implicitHeight: Math.min(root.barWindow ? Math.round(root.barWindow.screen.height * 0.70) : 600, contentFlickable.contentHeight + Spacing.popupShellPadding * 2)
        color: "transparent"
        anchor.item: root.anchorItem
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        anchor.adjustment: PopupAdjustment.Flip | PopupAdjustment.Slide
        anchor.rect.x: root.anchorOverrideX >= 0 ? root.anchorOverrideX : 0
        anchor.rect.y: root.anchorItem ? root.anchorItem.height + Spacing.popupAnchorGap : 0
        anchor.rect.width: root.anchorOverrideWidth >= 0 ? root.anchorOverrideWidth : (root.anchorItem ? root.anchorItem.width : 0)
        anchor.rect.height: 1

        // Recalculate anchor position when height changes (noctalia pattern)
        onImplicitHeightChanged: {
            if (visible && root.anchorItem) {
                Qt.callLater(function () {
                    popupWindow.anchor.updateAnchor();
                });
            }
        }

        Rectangle {
            id: bg

            anchors.fill: parent
            color: Colors.popupBg
            radius: Spacing.popupRadius
            clip: true
            border.color: Qt.rgba(Colors.popupBorderAccent.r, Colors.popupBorderAccent.g, Colors.popupBorderAccent.b, Colors.popupBorderAccent.a * bg.borderAlpha)
            border.width: Spacing.popupBorderWidth
            property real borderAlpha: 1.0

            SequentialAnimation on borderAlpha {
                loops: Animation.Infinite
                running: bg.visible && popupWindow.visible
                NumberAnimation {
                    to: 0.4
                    duration: Animations.breathDuration / 2
                    easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    to: 1.0
                    duration: Animations.breathDuration / 2
                    easing.type: Easing.InOutSine
                }
            }
            opacity: root.popupOpacity
            scale: root.popupScale
            transformOrigin: Item.Top

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(Shadows.shadowColor.r, Shadows.shadowColor.g, Shadows.shadowColor.b, Shadows.shadowOpacity)
                shadowBlur: Shadows.shadowBlur / 32.0
                shadowVerticalOffset: Shadows.shadowOffsetY
                shadowHorizontalOffset: Shadows.shadowOffsetX
                blurMax: Shadows.shadowBlur
            }

            // Flickable wrapper: enables scrolling when content exceeds popupHeight.
            // Content Loader uses width-only constraint so implicitHeight flows up.
            Flickable {
                id: contentFlickable
                anchors.fill: parent
                anchors.margins: Spacing.popupShellPadding
                contentWidth: width
                contentHeight: contentLoader.item ? contentLoader.item.implicitHeight : 0
                interactive: contentHeight > height
                clip: true

                Loader {
                    id: contentLoader
                    width: contentFlickable.width
                    sourceComponent: root.contentComponent
                    // Lazy popups: content only exists while popup is visible.
                    // Non-lazy popups: content always loaded (default, preserves current behavior).
                    active: !root.lazyContent || popupWindow.visible
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Animations.popupAnimDuration
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scale {
                PopupScale {}
            }
        }

        FocusGrab {
            id: focusGrab
            active: popupWindow.visible
            onCleared: {
                if (popupWindow.visible) {
                    Visibility.activeBarPopup = null;
                    popupWindow.visible = false;
                    popupOpacity = 0;
                    popupScale = 0.95;
                }
            }
        }

        Shortcut {
            sequence: "Escape"
            onActivated: root.close()
        }
    }
}
