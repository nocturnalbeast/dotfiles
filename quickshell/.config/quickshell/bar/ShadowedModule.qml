import QtQuick
import QtQuick.Effects
import "../components/anims"
import "../components"
import "../theme"

Item {
    id: root

    default property alias content: innerRow.children

    // Forward togglePopup to parent ModuleSlot (if present)
    function togglePopup() {
        if (parent && typeof parent.togglePopup === "function")
            parent.togglePopup();
    }

    width: layerWrap.width
    height: layerWrap.height
    anchors.verticalCenter: parent.verticalCenter

    scale: {
        if (hoverPress.isPressed)
            return Animations.pressScale;
        if (hoverPress.isHovered)
            return Animations.hoverScale;
        return 1.0;
    }

    // Layer wrapper: captures blur bg + widget content into a single
    // FBO, then applies the shadow via MultiEffect.
    Item {
        id: layerWrap
        function togglePopup() {
            root.togglePopup();
        }
        width: innerRow.width
        height: innerRow.height
        layer.enabled: true
        layer.textureSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(Shadows.shadowColor.r, Shadows.shadowColor.g, Shadows.shadowColor.b, Shadows.barShadowOpacity)
            shadowBlur: Shadows.barShadowBlur / 32.0
            shadowVerticalOffset: Shadows.barShadowOffsetY
            shadowHorizontalOffset: Shadows.barShadowOffsetX
            blurMax: Shadows.barShadowBlur
        }

        // Frosted-glass blur background behind widget content.
        // Positioned first for lower z-order inside the layer.
        WallpaperBlur {
            anchors.fill: parent
        }

        // Widget row on top of the blur background.
        Row {
            id: innerRow
            spacing: 0
        }
    }

    // Reusable hover/press state tracker — overrides scale to 1.0
    // so only ShadowedModule's own scale binding animates.
    HoverPress {
        id: hoverPress
        anchors.fill: parent
        scale: 1.0
    }

    Behavior on scale {
        ScaleSpring {}
    }
}
