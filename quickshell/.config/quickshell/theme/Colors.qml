pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ═══════════════════════════════════════════
    // MODE
    // ═══════════════════════════════════════════
    property string mode: "dark"  // "dark" | "light"

    // ═══════════════════════════════════════════
    // HELPER FUNCTIONS
    // ═══════════════════════════════════════════
    function hexToColor(hex) {
        if (!hex || hex.length < 7)
            return "#000000";
        return Qt.rgba(parseInt(hex.slice(1, 3), 16) / 255, parseInt(hex.slice(3, 5), 16) / 255, parseInt(hex.slice(5, 7), 16) / 255, 1.0);
    }

    function rgba(r, g, b, a) {
        return Qt.rgba(r, g, b, a);
    }

    // Apply alpha to an existing color
    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    // ═══════════════════════════════════════════
    // RAW MATERIAL YOU TOKENS (source for mapping)
    // These are loaded from matugen JSON or use fallback defaults
    // Fallbacks: shadcn neutral palette (pure grays, no color tint)
    // ═══════════════════════════════════════════
    property color primary: "#e5e5e5"
    property color on_primary: "#171717"
    property color primaryContainer: "#262626"
    property color secondary: "#a1a1a1"
    property color on_secondary: "#262626"
    property color secondaryContainer: "#262626"
    property color tertiary: "#a1a1a1"
    property color on_tertiary: "#262626"
    property color tertiaryContainer: "#262626"
    property color surface: "#0a0a0a"
    property color on_surface: "#fafafa"
    property color surfaceVariant: "#262626"
    property color on_surface_variant: "#a1a1a1"
    property color outline: "#737373"
    property color outlineVariant: "#262626"
    property color error: "#ff6467"
    property color on_error: "#0a0a0a"
    property color errorContainer: "#ff6467"
    property color on_error_container: "#0a0a0a"
    property color background: "#0a0a0a"
    property color on_background: "#fafafa"
    property color shadow: "#000000"
    property color inverseSurface: "#fafafa"
    property color inverse_on_surface: "#171717"
    property color inversePrimary: "#171717"
    property color surfaceContainer: "#0a0a0a"
    property color surfaceContainerHigh: "#171717"
    property color surfaceContainerHighest: "#262626"
    property color surfaceContainerLow: "#0a0a0a"
    property color scrim: "#000000"
    property color sourceColor: "#737373"

    // ═══════════════════════════════════════════
    // SEMANTIC COLORS (shadcn-inspired defaults)
    // ═══════════════════════════════════════════
    property color success: "#22c55e"
    property color warning: "#f59e0b"

    // Desktop clock tokens
    property color desktopClockText: Qt.rgba(0.98, 0.98, 0.98, 0.85)
    property color desktopClockSubtext: Qt.rgba(0.98, 0.98, 0.98, 0.55)
    // error is already defined above from Material You

    // ═══════════════════════════════════════════
    // DERIVED BAR / WIDGET TOKENS
    // Default values below; overwritten by deriveTokens() at runtime.
    // ═══════════════════════════════════════════

    // Header segment (icon block)
    property color widgetHeaderBg: Qt.rgba(0.039, 0.039, 0.039, 0.75)
    property color widgetHeaderFg: Qt.rgba(0.980, 0.980, 0.980, 0.85)

    // Content segment (text block)
    property color widgetContentBg: Qt.rgba(0.039, 0.039, 0.039, 0.62)
    property color widgetContentFg: Qt.rgba(0.980, 0.980, 0.980, 0.82)

    // Focused/active state (elevated dark surface)
    property color widgetFocusedBg: Qt.rgba(0.149, 0.149, 0.149, 0.82)
    property color widgetFocusedFg: Qt.rgba(0.980, 0.980, 0.980, 1.0)

    // Hover states
    property color widgetHoverHeaderBg: Qt.rgba(0.149, 0.149, 0.149, 0.60)
    property color widgetHoverContentBg: Qt.rgba(0.149, 0.149, 0.149, 0.45)

    // Inline bar widgets (volume/brightness hover bars)
    property color widgetBarTrack: Qt.rgba(0.980, 0.980, 0.980, 0.30)
    property color widgetBarFill: Qt.rgba(0.980, 0.980, 0.980, 1.0)

    // ═══════════════════════════════════════════
    // DERIVED POPUP TOKENS
    // ═══════════════════════════════════════════

    // Panel background (dark surface, slightly translucent)
    property color popupBg: Qt.rgba(0.091, 0.091, 0.091, 0.85)

    // Header section (elevated dark surface)
    property color popupHeaderBg: Qt.rgba(0.149, 0.149, 0.149, 0.90)
    property color popupHeaderFg: Qt.rgba(0.980, 0.980, 0.980, 0.95)

    // Content area (subtle light tint on dark bg)
    property color popupContentBg: Qt.rgba(0.980, 0.980, 0.980, 0.04)
    property color popupContentFg: Qt.rgba(0.980, 0.980, 0.980, 0.90)

    // Buttons — subtle light tint
    property color popupButtonBg: Qt.rgba(0.980, 0.980, 0.980, 0.06)
    property color popupButtonHoverBg: Qt.rgba(0.980, 0.980, 0.980, 0.10)
    property color popupButtonFg: Qt.rgba(0.980, 0.980, 0.980, 0.90)

    // Progress bars / sliders (light on dark)
    property color popupBarTrack: Qt.rgba(0.980, 0.980, 0.980, 0.12)
    property color popupBarFill: Qt.rgba(0.980, 0.980, 0.980, 0.70)

    // Borders — subtle outline
    property color popupBorder: Qt.rgba(0.451, 0.451, 0.451, 0.50)

    // Separator — very subtle
    property color popupSeparator: Qt.rgba(0.451, 0.451, 0.451, 0.20)

    // Muted / secondary text
    property color popupMuted: "#a1a1a1"

    // Hover bg for list items
    property color popupHoverBg: Qt.rgba(0.980, 0.980, 0.980, 0.08)

    // Accent border (BarPopup shell ring — breathing animation)
    property color popupBorderAccent: Qt.rgba(0.980, 0.980, 0.980, 0.15)

    // ═══════════════════════════════════════════
    // UTILITY
    // ═══════════════════════════════════════════
    property color barBackground: Qt.rgba(0, 0, 0, 0)
    property color barBorder: Qt.rgba(0, 0, 0, 0)

    // Blur tint (derived by deriveTokens())
    property color barBlurTint: Qt.rgba(0, 0, 0, 1)
    property real barBlurTintOpacity: 0.3

    // ═══════════════════════════════════════════
    // TOKEN DERIVATION
    // Single source of truth for all derived tokens.
    // Computes widget/popup/semantic colors from base M3 palette tokens + mode.
    // ═══════════════════════════════════════════
    function deriveTokens() {
        if (root.mode === "dark") {
            // Widget tokens — dark translucent surfaces from M3 palette
            root.widgetHeaderBg = withAlpha(root.surfaceContainerHigh, 0.75);
            root.widgetHeaderFg = withAlpha(root.on_surface, 0.85);
            root.widgetContentBg = withAlpha(root.surfaceContainer, 0.62);
            root.widgetContentFg = withAlpha(root.on_surface, 0.82);
            root.widgetFocusedBg = withAlpha(root.surfaceContainerHighest, 0.82);
            root.widgetFocusedFg = withAlpha(root.on_surface, 1.0);
            root.widgetHoverHeaderBg = withAlpha(root.surfaceContainerHighest, 0.60);
            root.widgetHoverContentBg = withAlpha(root.surfaceContainerHighest, 0.45);
            root.widgetBarTrack = withAlpha(root.on_surface, 0.3);
            root.widgetBarFill = withAlpha(root.on_surface, 1.0);

            // Popup tokens — dark surfaces, light text (matching bar theme)
            root.popupBg = withAlpha(root.surfaceContainerHigh, 0.85);
            root.popupHeaderBg = withAlpha(root.surfaceContainerHighest, 0.90);
            root.popupHeaderFg = withAlpha(root.on_surface, 0.95);
            root.popupContentBg = withAlpha(root.on_surface, 0.04);
            root.popupContentFg = withAlpha(root.on_surface, 0.90);
            root.popupButtonBg = withAlpha(root.on_surface, 0.06);
            root.popupButtonHoverBg = withAlpha(root.on_surface, 0.10);
            root.popupButtonFg = withAlpha(root.on_surface, 0.90);
            root.popupBarTrack = withAlpha(root.on_surface, 0.12);
            root.popupBarFill = withAlpha(root.on_surface, 0.70);
            root.popupBorder = withAlpha(root.outline, 0.50);
            root.popupSeparator = withAlpha(root.outline, 0.20);
            root.popupMuted = root.on_surface_variant;
            root.popupHoverBg = withAlpha(root.on_surface, 0.08);
            root.popupBorderAccent = withAlpha(root.on_surface, 0.15);

            // Bar blur tint — dark surface overlay
            root.barBlurTint = root.surface;
            root.barBlurTintOpacity = 0.3;

            // Semantic
            root.success = "#22c55e";
            root.warning = "#f59e0b";

            // Desktop clock — light text on dark wallpaper
            root.desktopClockText = withAlpha(root.on_surface, 0.85);
            root.desktopClockSubtext = withAlpha(root.on_surface, 0.55);
        } else {
            // Widget tokens — light translucent surfaces from M3 palette
            root.widgetHeaderBg = withAlpha(root.surfaceContainerHigh, 0.80);
            root.widgetHeaderFg = withAlpha(root.on_surface, 0.85);
            root.widgetContentBg = withAlpha(root.surfaceContainer, 0.65);
            root.widgetContentFg = withAlpha(root.on_surface, 0.82);
            root.widgetFocusedBg = withAlpha(root.surfaceContainerHighest, 0.88);
            root.widgetFocusedFg = withAlpha(root.on_surface, 1.0);
            root.widgetHoverHeaderBg = withAlpha(root.surfaceContainerHighest, 0.60);
            root.widgetHoverContentBg = withAlpha(root.surfaceContainerHighest, 0.45);
            root.widgetBarTrack = withAlpha(root.on_surface, 0.12);
            root.widgetBarFill = withAlpha(root.on_surface, 0.80);

            // Popup tokens — light surfaces, dark text
            root.popupBg = withAlpha(root.surface, 0.80);
            root.popupHeaderBg = withAlpha(root.surfaceContainerHighest, 0.92);
            root.popupHeaderFg = withAlpha(root.on_surface, 0.92);
            root.popupContentBg = withAlpha(root.on_surface, 0.04);
            root.popupContentFg = withAlpha(root.on_surface, 0.90);
            root.popupButtonBg = withAlpha(root.on_surface, 0.06);
            root.popupButtonHoverBg = withAlpha(root.on_surface, 0.10);
            root.popupButtonFg = withAlpha(root.on_surface, 0.90);
            root.popupBarTrack = withAlpha(root.on_surface, 0.12);
            root.popupBarFill = withAlpha(root.on_surface, 0.70);
            root.popupBorder = withAlpha(root.outline, 0.50);
            root.popupSeparator = withAlpha(root.outline, 0.20);
            root.popupMuted = root.on_surface_variant;
            root.popupHoverBg = withAlpha(root.on_surface, 0.08);
            root.popupBorderAccent = withAlpha(root.on_surface, 0.15);

            // Bar blur tint — light surface overlay
            root.barBlurTint = root.surface;
            root.barBlurTintOpacity = 0.4;

            // Semantic
            root.success = "#16a34a";
            root.warning = "#d97706";

            // Desktop clock — dark text on light wallpaper
            root.desktopClockText = withAlpha(root.on_surface, 0.85);
            root.desktopClockSubtext = withAlpha(root.on_surface, 0.55);
        }
    }

    // ═══════════════════════════════════════════
    // FALLBACK SCHEME APPLICATION
    // Sets base M3 tokens to neutral palette values, then derives all tokens.
    // ═══════════════════════════════════════════
    function applyFallbackDark() {
        root.mode = "dark";

        // Base M3 tokens — shadcn neutral dark palette
        root.primary = "#e5e5e5";
        root.on_primary = "#171717";
        root.primaryContainer = "#262626";
        root.secondary = "#a1a1a1";
        root.on_secondary = "#262626";
        root.secondaryContainer = "#262626";
        root.tertiary = "#a1a1a1";
        root.on_tertiary = "#262626";
        root.tertiaryContainer = "#262626";
        root.surface = "#0a0a0a";
        root.on_surface = "#fafafa";
        root.surfaceVariant = "#262626";
        root.on_surface_variant = "#a1a1a1";
        root.outline = "#737373";
        root.outlineVariant = "#262626";
        root.error = "#ff6467";
        root.on_error = "#0a0a0a";
        root.errorContainer = "#ff6467";
        root.on_error_container = "#0a0a0a";
        root.background = "#0a0a0a";
        root.on_background = "#fafafa";
        root.shadow = "#000000";
        root.inverseSurface = "#fafafa";
        root.inverse_on_surface = "#171717";
        root.inversePrimary = "#171717";
        root.surfaceContainer = "#0a0a0a";
        root.surfaceContainerHigh = "#171717";
        root.surfaceContainerHighest = "#262626";
        root.surfaceContainerLow = "#0a0a0a";
        root.scrim = "#000000";
        root.sourceColor = "#737373";

        root.deriveTokens();
    }

    function applyFallbackLight() {
        root.mode = "light";

        // Base M3 tokens — shadcn neutral light palette
        root.primary = "#171717";
        root.on_primary = "#fafafa";
        root.primaryContainer = "#e5e5e5";
        root.secondary = "#737373";
        root.on_secondary = "#ffffff";
        root.secondaryContainer = "#f5f5f5";
        root.tertiary = "#737373";
        root.on_tertiary = "#ffffff";
        root.tertiaryContainer = "#f5f5f5";
        root.surface = "#ffffff";
        root.on_surface = "#0a0a0a";
        root.surfaceVariant = "#f5f5f5";
        root.on_surface_variant = "#737373";
        root.outline = "#737373";
        root.outlineVariant = "#e5e5e5";
        root.error = "#e7000b";
        root.on_error = "#ffffff";
        root.errorContainer = "#e7000b";
        root.on_error_container = "#ffffff";
        root.background = "#ffffff";
        root.on_background = "#0a0a0a";
        root.shadow = "#000000";
        root.inverseSurface = "#171717";
        root.inverse_on_surface = "#fafafa";
        root.inversePrimary = "#e5e5e5";
        root.surfaceContainer = "#fafafa";
        root.surfaceContainerHigh = "#f5f5f5";
        root.surfaceContainerHighest = "#e5e5e5";
        root.surfaceContainerLow = "#ffffff";
        root.scrim = "#000000";
        root.sourceColor = "#737373";

        root.deriveTokens();
    }

    // ═══════════════════════════════════════════
    // MATUGEN INTEGRATION
    // ═══════════════════════════════════════════
    function loadColors() {
        const text = themeFile.text();
        if (!text)
            return;
        try {
            const colors = JSON.parse(text);
            if (colors.mode === "light" || colors.is_dark_mode === false) {
                root.mode = "light";
            } else {
                root.mode = "dark";
            }
            const scheme = colors.colors;
            if (!scheme)
                return;

            const variant = root.mode === "light" ? "light" : "dark";

            function mc(token) {
                const entry = scheme[token];
                if (!entry)
                    return null;
                const v = entry[variant] || entry["default"];
                if (!v)
                    return null;
                return hexToColor(v.color);
            }

            root.primary = mc("primary") || root.primary;
            root.on_primary = mc("on_primary") || root.on_primary;
            root.primaryContainer = mc("primary_container") || root.primaryContainer;
            root.secondary = mc("secondary") || root.secondary;
            root.on_secondary = mc("on_secondary") || root.on_secondary;
            root.secondaryContainer = mc("secondary_container") || root.secondaryContainer;
            root.tertiary = mc("tertiary") || root.tertiary;
            root.on_tertiary = mc("on_tertiary") || root.on_tertiary;
            root.tertiaryContainer = mc("tertiary_container") || root.tertiaryContainer;
            root.surface = mc("surface") || root.surface;
            root.on_surface = mc("on_surface") || root.on_surface;
            root.surfaceVariant = mc("surface_variant") || root.surfaceVariant;
            root.on_surface_variant = mc("on_surface_variant") || root.on_surface_variant;
            root.outline = mc("outline") || root.outline;
            root.outlineVariant = mc("outline_variant") || root.outlineVariant;
            root.error = mc("error") || root.error;
            root.on_error = mc("on_error") || root.on_error;
            root.errorContainer = mc("error_container") || root.errorContainer;
            root.on_error_container = mc("on_error_container") || root.on_error_container;
            root.background = mc("background") || root.background;
            root.on_background = mc("on_background") || root.on_background;
            root.shadow = mc("shadow") || root.shadow;
            root.inverseSurface = mc("inverse_surface") || root.inverseSurface;
            root.inverse_on_surface = mc("inverse_on_surface") || root.inverse_on_surface;
            root.inversePrimary = mc("inverse_primary") || root.inversePrimary;
            root.scrim = mc("scrim") || root.scrim;
            root.sourceColor = mc("source_color") || root.sourceColor;
            root.surfaceContainer = mc("surface_container") || root.surfaceContainer;
            root.surfaceContainerHigh = mc("surface_container_high") || root.surfaceContainerHigh;
            root.surfaceContainerHighest = mc("surface_container_highest") || root.surfaceContainerHighest;
            root.surfaceContainerLow = mc("surface_container_low") || root.surfaceContainerLow;

            root.applyMatugenScheme();
        } catch (e) {
            // JSON parse failed - keep current colors
        }
    }

    function applyMatugenScheme() {
        root.deriveTokens();
    }

    // ═══════════════════════════════════════════
    // FILE WATCHER FOR MATUGEN COLORS
    // ═══════════════════════════════════════════
    FileView {
        id: themeFile
        path: {
            const cacheHome = Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache");
            return cacheHome + "/matugen/colors.json";
        }
        watchChanges: true
        onFileChanged: {
            themeFile.reload();
        }
        onLoaded: {
            root.loadColors();
        }
    }

    // ═══════════════════════════════════════════
    // INITIALIZATION
    // ═══════════════════════════════════════════
    Component.onCompleted: {
        // Apply fallback on startup — loadColors() will override if matugen JSON exists
        if (root.mode === "dark") {
            root.applyFallbackDark();
        } else {
            root.applyFallbackLight();
        }
    }
}
