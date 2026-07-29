pragma ComponentBehavior: Bound

import "../modules/barswitch"
import "../modules/battery"
import "../modules/bluetooth"
import "../modules/brightness"
import "../modules/clock"
import "../modules/idle"
import "../modules/keyboard"
import "../modules/media"
import "../modules/network"
import "../modules/session"
import "../modules/system"
import "../modules/tray"
import "../modules/volume"
import "../modules/weather"
import "../modules/windowtitle"
import "../modules/workspaces"
import "../components" // Separator, ModuleSlot
import "../services"
import QtQuick

Item {
    id: root

    property int mode: 0 // 0 = main, 1 = mon
    property var barWindow: null

    // Toggle the media popup from any media module (artist/title click → buttons slot popup)
    function toggleMediaPopup() {
        // mediaButtons is always at center index 1 when available
        var item = centerRepeater.itemAt(1);
        if (item)
            item.togglePopup();
    }

    // ── Data models (selected by mode) ──

    property var leftModules: mode === 0 ? [
        {
            "type": "barswitch"
        },
        {
            "type": "separator"
        },
        {
            "type": "workspaceWithTitle"
        },
        {
            "type": "separator"
        }
    ] : [
        {
            "type": "barswitch"
        },
        {
            "type": "separator"
        },
        {
            "type": "cpu"
        },
        {
            "type": "separator"
        },
        {
            "type": "memory"
        },
        {
            "type": "separator"
        },
        {
            "type": "disk"
        }
    ]

    property var centerModules: mode === 0 ? (MediaPlayer.available ? [
            {
                "type": "mediaArtist"
            },
            {
                "type": "mediaButtons"
            },
            {
                "type": "mediaTitle"
            }
        ] : []) : [
        {
            "type": "battery"
        }
    ]

    property var rightModules: mode === 0 ? [
        {
            "type": "separator"
        },
        {
            "type": "volume"
        },
        {
            "type": "separator"
        },
        {
            "type": "brightness"
        },
        {
            "type": "separator"
        },
        {
            "type": "bluetooth"
        },
        {
            "type": "separator"
        },
        {
            "type": "clock"
        },
        {
            "type": "separator"
        },
        {
            "type": "keepAwake"
        },
        {
            "type": "separator"
        },
        {
            "type": "tray"
        },
        {
            "type": "separator"
        },
        {
            "type": "sessionPower"
        }
    ] : [
        {
            "type": "separator"
        },
        {
            "type": "uptime"
        },
        {
            "type": "separator"
        },
        {
            "type": "weather"
        },
        {
            "type": "separator"
        },
        {
            "type": "keyboard"
        }
    ]

    // ── Shared delegate chooser (all module types) ──

    DelegateChooser {
        id: moduleDelegate
        role: "type"

        DelegateChoice {
            roleValue: "separator"
            delegate: Separator {}
        }
        DelegateChoice {
            roleValue: "barswitch"
            delegate: ModuleSlot {
                BarSwitchWidget {}
            }
        }

        // ── Main-bar modules ──

        DelegateChoice {
            roleValue: "workspaceWithTitle"
            delegate: ModuleSlot {
                barWindow: root.barWindow
                popupComponent: WorkspaceOverviewPopup {}
                WorkspacesWidget {
                    onClicked: parent.parent.togglePopup()
                }
                WindowTitleWidget {}
            }
        }
        DelegateChoice {
            roleValue: "mediaArtist"
            delegate: ModuleSlot {
                MediaArtistWidget {
                    onClicked: root.toggleMediaPopup()
                    onRightClicked: MediaPlayer.playPause()
                }
            }
        }
        DelegateChoice {
            roleValue: "mediaButtons"
            delegate: ModuleSlot {
                barWindow: root.barWindow
                popupLazy: true
                popupComponent: MediaPlayerPopup {}
                MediaButtonsWidget {}
            }
        }
        DelegateChoice {
            roleValue: "mediaTitle"
            delegate: ModuleSlot {
                MediaTitleWidget {
                    onClicked: root.toggleMediaPopup()
                    onRightClicked: MediaPlayer.playPause()
                }
            }
        }
        DelegateChoice {
            roleValue: "volume"
            delegate: ModuleSlot {
                barWindow: root.barWindow
                popupComponent: VolumePopup {}
                VolumeWidget {
                    onClicked: parent.parent.togglePopup()
                }
            }
        }
        DelegateChoice {
            roleValue: "brightness"
            delegate: ModuleSlot {
                barWindow: root.barWindow
                popupComponent: BrightnessPopup {}
                BrightnessWidget {
                    onClicked: parent.parent.togglePopup()
                }
            }
        }
        DelegateChoice {
            roleValue: "bluetooth"
            delegate: ModuleSlot {
                barWindow: root.barWindow
                popupLazy: true
                popupComponent: BluetoothPopup {}
                BluetoothWidget {
                    onClicked: parent.parent.togglePopup()
                }
            }
        }
        DelegateChoice {
            roleValue: "clock"
            delegate: ModuleSlot {
                barWindow: root.barWindow
                popupLazy: true
                popupComponent: CalendarPopup {}
                ClockWidget {
                    onClicked: parent.parent.togglePopup()
                }
            }
        }
        DelegateChoice {
            roleValue: "keyboard"
            delegate: ModuleSlot {
                KeyboardWidget {}
            }
        }
        DelegateChoice {
            roleValue: "weather"
            delegate: ModuleSlot {
                barWindow: root.barWindow
                popupLazy: true
                popupComponent: WeatherPopup {}
                WeatherWidget {
                    onClicked: parent.parent.togglePopup()
                }
            }
        }
        DelegateChoice {
            roleValue: "keepAwake"
            delegate: ModuleSlot {
                KeepAwakeWidget {}
            }
        }
        DelegateChoice {
            roleValue: "sessionPower"
            delegate: ModuleSlot {
                SessionPowerButton {}
            }
        }
        DelegateChoice {
            roleValue: "tray"
            delegate: ModuleSlot {
                SystemTrayWidget {
                    barWindow: root.barWindow
                }
            }
        }

        // ── Mon-bar modules ──

        DelegateChoice {
            roleValue: "cpu"
            delegate: ModuleSlot {
                barWindow: root.barWindow
                popupComponent: CpuPopup {}
                CpuWidget {
                    onClicked: parent.parent.togglePopup()
                }
            }
        }
        DelegateChoice {
            roleValue: "memory"
            delegate: ModuleSlot {
                barWindow: root.barWindow
                popupComponent: MemoryPopup {}
                MemoryWidget {
                    onClicked: parent.parent.togglePopup()
                }
            }
        }
        DelegateChoice {
            roleValue: "battery"
            delegate: ModuleSlot {
                barWindow: root.barWindow
                popupComponent: BatteryPopup {}
                BatteryWidget {
                    onClicked: parent.parent.togglePopup()
                }
            }
        }
        DelegateChoice {
            roleValue: "disk"
            delegate: ModuleSlot {
                barWindow: root.barWindow
                popupComponent: DiskPopup {}
                DiskWidget {
                    onClicked: parent.parent.togglePopup()
                }
            }
        }
        DelegateChoice {
            roleValue: "uptime"
            delegate: ModuleSlot {
                UptimeWidget {}
            }
        }
    }

    // ── Layout rows ──

    Row {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0
        Repeater {
            model: root.leftModules
            delegate: moduleDelegate
        }
    }

    Row {
        id: centerRow

        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        // Dynamic center detection:
        // Odd count  → center of middle item
        // Even count → midpoint between the two middle items
        property real _centerMidX: {
            var n = centerRepeater.count;
            if (n === 0)
                return width / 2;
            if (n % 2 === 1) {
                var item = centerRepeater.itemAt(Math.floor(n / 2));
                return item ? (item.x + item.width / 2) : width / 2;
            } else {
                var left = centerRepeater.itemAt(n / 2 - 1);
                return left ? (left.x + left.width) : width / 2;
            }
        }

        x: Math.round(root.width / 2 - _centerMidX)

        Repeater {
            id: centerRepeater
            model: root.centerModules
            delegate: moduleDelegate
        }
    }

    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        spacing: 0
        Repeater {
            model: root.rightModules
            delegate: moduleDelegate
        }
        }

        // Disabled: NetworkService singleton triggers upstream QS segfault
        // (NMWirelessNetwork::updateReferenceAp use-after-free). Re-enable
        // when upstream fixes the bug, including the "network" entry in
        // rightModules mode 1 + its preceding separator.
        // DelegateChoice {
        //     roleValue: "network"
        //     delegate: ModuleSlot {
        //         barWindow: root.barWindow
        //         popupLazy: true
        //         popupComponent: NetworkPopup {}
        //         NetworkWidget {
        //             onClicked: parent.parent.togglePopup()
        //         }
        //     }
        // }
    }
