//@ pragma DropExpensiveFonts
//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import "bar"
import "theme"
import "modules/desktopclock"
import "modules/osd"
import "modules/session"
import "services"
import "components"

ShellRoot {
    // ── WM Padding Helpers ──
    // Dispatches WM-specific commands to enable/disable bar padding.
    // bspwm:  bspc config top_padding 0 | ~/.config/bspwm/set-monitors
    // spectrwm: spectrwm-region-helper disable_padding | spectrwm-region-helper
    Process {
        id: wmPaddingProc
        running: false
        property string _action: ""

        command: {
            if (!WmDetector.isX11)
                return ["true"]; // no-op on Wayland
            const wm = WmDetector.wmName;
            if (_action === "disable") {
                if (wm === "bspwm")
                    return ["bspc", "config", "top_padding", "0"];
                if (wm === "spectrwm")
                    return ["spectrwm-region-helper", "disable_padding"];
            } else if (_action === "enable") {
                if (wm === "bspwm")
                    return [Quickshell.env("HOME") + "/.config/bspwm/set-monitors"];
                if (wm === "spectrwm")
                    return ["spectrwm-region-helper"];
            }
            return ["true"]; // no-op for unsupported WMs
        }
    }

    // ── Per-Domain IPC Handlers ──
    // Usage: qs ipc call <target> <command> [args]
    //
    // Targets:
    //   bar        – bar visibility, switching, dimensions
    //   volume     – audio volume control
    //   brightness – screen brightness control
    //   media      – media playback control
    //   lock       – screen lock & idle daemon control
    //   weather    – weather data & refresh
    //   shell      – shell-level commands (popups, etc.)

    // ── Bar IPC ──
    // Usage: qs ipc call bar <command>
    // Commands: switchBar, hideBar, showBar, toggleBar,
    //   hideBarReclaim, showBarReclaim, toggleBarReclaim,
    //   isBarHidden, getBarDimensions
    IpcHandler {
        target: "bar"

        function switchBar(): void {
            Visibility.switchBar();
        }

        // hideBar / showBar / toggleBar: bar only
        // hideBarReclaim / showBarReclaim / toggleBarReclaim: bar + WM padding
        function hideBar(): void {
            Visibility.manualHidden = true;
        }

        function hideBarReclaim(): void {
            Visibility.manualHidden = true;
            wmPaddingProc._action = "disable";
            wmPaddingProc.running = true;
        }

        function showBar(): void {
            Visibility.manualHidden = false;
        }

        function showBarReclaim(): void {
            Visibility.manualHidden = false;
            wmPaddingProc._action = "enable";
            wmPaddingProc.running = true;
        }

        function toggleBar(): void {
            if (Visibility.manualHidden) {
                showBar();
            } else {
                hideBar();
            }
        }

        function toggleBarReclaim(): void {
            if (Visibility.manualHidden) {
                showBarReclaim();
            } else {
                hideBarReclaim();
            }
        }

        // Returns "yes" or "no"
        function isBarHidden(): string {
            return Visibility.manualHidden ? "yes" : "no";
        }

        // Returns the bar font family name.
        function getBarFont(): string {
            return Typography.barFontFamily;
        }

        // Returns bar dimensions per monitor, newline-delimited.
        // Format: <screen_name>:<horz_margin>:<vert_margin>:<bar_height>:<usable_width>
        // Example: DP-1:10:10:27:1880
        function getBarDimensions(): string {
            const gap = WindowGapService.windowGap;
            const lines = [];
            for (const s of Quickshell.screens) {
                const barHeight = Math.round(s.height * Typography.barHeightPct / 100);
                const usableWidth = s.width - 2 * gap;
                lines.push(`${s.name}:${gap}:${gap}:${barHeight}:${usableWidth}`);
            }
            return lines.join("\n");
        }
    }

    // ── Volume IPC ──
    // Usage: qs ipc call volume <command>
    // Commands: up, down, mute, set(vol), get
    IpcHandler {
        target: "volume"

        function up(): void {
            AudioService.increaseVolume();
        }

        function down(): void {
            AudioService.decreaseVolume();
        }

        function mute(): void {
            AudioService.toggleMute();
        }

        function set(vol: real): void {
            AudioService.setVolume(vol);
        }

        function get(): string {
            return Math.round(AudioService.volume * 100).toString();
        }
    }

    // ── Brightness IPC ──
    // Usage: qs ipc call brightness <command>
    // Commands: up, down, set(pct), get
    IpcHandler {
        target: "brightness"

        function up(): void {
            BrightnessService.increaseBrightness();
        }

        function down(): void {
            BrightnessService.decreaseBrightness();
        }

        function set(pct: int): void {
            BrightnessService.setBrightness(pct);
        }

        function get(): string {
            return Math.round(BrightnessService.percentage).toString();
        }
    }

    // ── Media IPC ──
    // Usage: qs ipc call media <command>
    // Commands: playPause, next, prev
    IpcHandler {
        target: "media"

        function playPause(): void {
            MediaPlayer.playPause();
        }

        function next(): void {
            MediaPlayer.next();
        }

        function prev(): void {
            MediaPlayer.prev();
        }
    }

    // ── Lock IPC ──
    // Usage: qs ipc call lock <command>
    // Commands: lock, start, stop, status
    IpcHandler {
        target: "lock"

        function lock(): void {
            LockService.lock();
        }

        function start(): void {
            LockService.startDaemon();
        }

        function stop(): void {
            LockService.stopDaemon();
        }

        function status(): string {
            return LockService.daemonRunning ? "running" : "stopped";
        }
    }

    // ── Weather IPC ──
    // Usage: qs ipc call weather <command>
    // Commands: refresh, status
    IpcHandler {
        target: "weather"

        function refresh(): void {
            WeatherService.refresh();
        }

        function status(): string {
            return WeatherService.ready ? "ready" : "pending";
        }
    }

    // ── Shell IPC ──
    // Usage: qs ipc call shell <command>
    // Commands: closePopups
    IpcHandler {
        target: "shell"

        function closePopups(): void {
            Visibility.closeAll();
        }
    }

    // ── Session IPC ──
    // Usage: qs ipc call session <command>
    // Commands: toggle, lock, suspend, reboot, shutdown, logout
    IpcHandler {
        target: "session"

        function toggle(): void {
            SessionService.toggle();
        }

        function lock(): void {
            SessionService.lock();
        }

        function suspend(): void {
            SessionService.suspend();
        }

        function reboot(): void {
            SessionService.reboot();
        }

        function shutdown(): void {
            SessionService.shutdown();
        }

        function logout(): void {
            SessionService.logout();
        }
    }

    Variants {
        model: Quickshell.screens

        DesktopClock {
            required property var modelData

            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Loader {
            required property var modelData

            asynchronous: false
            source: WmDetector.isX11 ? "modules/session/SessionScreen.qml" : "modules/session/SessionScreenWlr.qml"
            onLoaded: if (item)
                item.screen = modelData
        }
    }

    Variants {
        model: Quickshell.screens

        OsdWindow {
            required property var modelData

            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens

        Bar {
            required property var modelData

            screen: modelData
        }
    }

}
