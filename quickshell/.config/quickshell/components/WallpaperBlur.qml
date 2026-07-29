import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../theme"

// Frosted-glass blur background for bar modules.
// Loads the wallpaper, positions it to align with screen coordinates,
// applies MultiEffect blur, and overlays a semi-transparent tint.
// The parent Item clips to show only the module's portion.
Item {
    id: root

    clip: true
    // Stay invisible until position is computed to prevent flicker.
    visible: Shadows.barBlurEnabled && _positionReady

    // ── Wallpaper path (symlink) ──
    readonly property string _symlinkPath: Quickshell.env("HOME") + "/.config/wm/current_wallpaper"

    // ── Screen geometry (resolved from PanelWindow) ──
    readonly property var _win: Window.window
    readonly property var _scr: _win ? _win.screen : null
    readonly property real _screenW: _scr ? _scr.geometry.width : 1920
    readonly property real _screenH: _scr ? _scr.geometry.height : 1080

    // ── Global position of the layerWrap on screen ──
    // Deferred to ensure layout is complete before mapping coordinates.
    property real _globalX: 0
    property real _globalY: 0
    property bool _positionReady: false

    // Incremented on wallpaper change to force Image reload
    property int _reloadCounter: 0

    function _updatePosition() {
        // Walk up past innerRow → layerWrap to get correct global position.
        // mapToGlobal from inside a layer.enabled item gives (0,0),
        // so we go to the layerWrap's parent chain instead.
        var target = root.parent; // layerWrap
        // Walk up until we find an item whose parent is NOT in the layer
        // (i.e. the ShadowedModule root or above)
        while (target && target.parent) {
            if (target.parent === root.Window.content || target.parent === root.Window.window) {
                break;
            }
            // If parent has layer.enabled, keep going up
            if (target.parent.layer && target.parent.layer.enabled) {
                target = target.parent;
            } else {
                break;
            }
        }
        if (target) {
            var pos = target.mapToGlobal(0, 0);
            root._globalX = pos.x;
            root._globalY = pos.y;
            root._positionReady = true;
        }
    }

    // ── Debounced position update ──
    // Component.onCompleted is too early — layout hasn't settled.
    // Geometry changes during layout transitions (bar switch, fullscreen)
    // restart the timer so position is computed only once after settling.
    Timer {
        id: posTimer
        interval: 100
        running: true
        repeat: false
        onTriggered: root._updatePosition()
    }

    function _scheduleUpdate() {
        posTimer.restart();
    }

    Connections {
        target: root.parent
        function onXChanged() {
            root._scheduleUpdate();
        }
        function onYChanged() {
            root._scheduleUpdate();
        }
        function onWidthChanged() {
            root._scheduleUpdate();
        }
    }

    // ── Watch wallpaper symlink for changes ──
    FileView {
        id: wallpaperWatcher
        path: root._symlinkPath
        watchChanges: true
        onFileChanged: {
            wallpaperWatcher.reload();
            root._reloadCounter++;
        }
    }

    // ── Full-screen wallpaper image ──
    // Uses PreserveAspectCrop to match xwallpaper --zoom (fill mode):
    // scale to cover, maintain aspect ratio, center, crop excess.
    Image {
        id: wallpaperImg
        visible: false // rendered by MultiEffect, not directly
        asynchronous: true
        cache: true

        source: root._symlinkPath
        fillMode: Image.PreserveAspectCrop

        // Size the image to cover the full screen area
        width: root._screenW
        height: root._screenH

        // Position: offset so the visible portion behind this module
        // aligns at (0, 0) in local coordinates. Parent clip hides the rest.
        x: -root._globalX
        y: -root._globalY
    }

    // ── Blur effect applied to the wallpaper ──
    MultiEffect {
        source: wallpaperImg
        x: wallpaperImg.x
        y: wallpaperImg.y
        width: wallpaperImg.width
        height: wallpaperImg.height

        blurEnabled: true
        blur: Shadows.barBlurStrength
        blurMax: 32
    }

    // ── Semi-transparent tint overlay ──
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Colors.barBlurTint.r, Colors.barBlurTint.g, Colors.barBlurTint.b, Colors.barBlurTintOpacity)
    }
}
