import QtQuick

// Self-contained bar module slot: ShadowedModule + optional BarPopup.
// In a Repeater/DelegateChooser, widget IDs aren't accessible externally,
// so the popup is co-located and anchored directly to the ShadowedModule.
Item {
    id: root

    default property alias content: shadowedModule.content

    // Popup configuration — set popupComponent to enable the popup.
    property Component popupComponent: null
    property real anchorOverrideX: -1
    property real anchorOverrideWidth: -1
    property var barWindow: null
    property bool popupLazy: false

    readonly property bool popupOpen: popupLoader.item ? popupLoader.item.isOpen : false

    width: shadowedModule.width
    height: shadowedModule.height

    ShadowedModule {
        id: shadowedModule
    }

    Loader {
        id: popupLoader
        active: root.popupComponent !== null
        sourceComponent: BarPopup {
            anchorItem: shadowedModule
            barWindow: root.barWindow
            contentComponent: root.popupComponent
            anchorOverrideX: root.anchorOverrideX
            anchorOverrideWidth: root.anchorOverrideWidth
            lazyContent: root.popupLazy
        }
    }

    function togglePopup() {
        if (popupLoader.item)
            popupLoader.item.toggle();
    }
}
