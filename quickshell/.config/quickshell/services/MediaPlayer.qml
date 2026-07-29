pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    // ═══════════════════════════════════════════
    // BACKWARD-COMPATIBLE PROPERTIES
    // ═══════════════════════════════════════════
    readonly property string artist: activePlayer ? activePlayer.trackArtist : ""
    readonly property string title: activePlayer ? activePlayer.trackTitle : ""
    readonly property string album: activePlayer ? activePlayer.trackAlbum : ""
    readonly property string albumArt: activePlayer ? activePlayer.trackArtUrl : ""
    readonly property bool playing: activePlayer ? activePlayer.isPlaying : false
    readonly property bool available: activePlayer !== null

    // ═══════════════════════════════════════════
    // NEW PROPERTIES
    // ═══════════════════════════════════════════

    // Playback position / length
    readonly property real position: activePlayer ? activePlayer.position : 0
    readonly property real trackLength: activePlayer ? activePlayer.length : 0
    readonly property bool positionSupported: activePlayer ? activePlayer.positionSupported : false

    // Capability flags
    readonly property bool canSeek: activePlayer ? activePlayer.canSeek : false
    readonly property bool canGoNext: activePlayer ? activePlayer.canGoNext : false
    readonly property bool canGoPrevious: activePlayer ? activePlayer.canGoPrevious : false
    readonly property bool canTogglePlaying: activePlayer ? activePlayer.canTogglePlaying : false

    // Loop / Shuffle
    readonly property int loopState: activePlayer ? activePlayer.loopState : MprisLoopState.None
    readonly property bool shuffle: activePlayer ? activePlayer.shuffle : false
    readonly property bool loopSupported: activePlayer ? activePlayer.loopSupported : false
    readonly property bool shuffleSupported: activePlayer ? activePlayer.shuffleSupported : false
    readonly property string loopIcon: activePlayer ? (activePlayer.loopState === MprisLoopState.Track ? "󰑘" : activePlayer.loopState === MprisLoopState.Playlist ? "󰑖" : "󰑗") : "󰑗"
    readonly property bool loopActive: activePlayer ? activePlayer.loopState !== MprisLoopState.None : false

    // Volume
    readonly property real volume: activePlayer ? activePlayer.volume : 0
    readonly property bool volumeSupported: activePlayer ? activePlayer.volumeSupported : false

    // Multi-player
    readonly property var players: Mpris.players.values
    readonly property int playerCount: players ? players.length : 0
    readonly property string activePlayerName: activePlayer ? activePlayer.identity : ""

    // Active player resolution: explicit selection overrides auto-detection
    readonly property var activePlayer: _selectedPlayer ?? _autoPlayer

    // ═══════════════════════════════════════════
    // INTERNAL STATE
    // ═══════════════════════════════════════════
    property var _selectedPlayer: null
    property var _autoPlayer: null

    // ═══════════════════════════════════════════
    // FUNCTIONS — BACKWARD-COMPATIBLE
    // ═══════════════════════════════════════════
    function playPause() {
        if (activePlayer)
            activePlayer.togglePlaying();
    }
    function next() {
        if (activePlayer && activePlayer.canGoNext)
            activePlayer.next();
    }
    function prev() {
        if (activePlayer && activePlayer.canGoPrevious)
            activePlayer.previous();
    }
    function stop() {
        if (activePlayer)
            activePlayer.stop();
    }

    // ═══════════════════════════════════════════
    // FUNCTIONS — NEW
    // ═══════════════════════════════════════════
    function seek(offset) {
        if (activePlayer && activePlayer.canSeek)
            activePlayer.seek(offset);
    }
    function setPosition(pos) {
        if (activePlayer && activePlayer.canSeek && activePlayer.positionSupported)
            activePlayer.position = pos;
    }
    function setActivePlayer(player) {
        root._selectedPlayer = player;
    }
    function clearPlayerSelection() {
        root._selectedPlayer = null;
    }
    function cycleLoopState() {
        if (!activePlayer || !activePlayer.loopSupported)
            return;
        var s = activePlayer.loopState;
        activePlayer.loopState = (s === MprisLoopState.None) ? MprisLoopState.Track : (s === MprisLoopState.Track) ? MprisLoopState.Playlist : MprisLoopState.None;
    }
    function toggleShuffle() {
        if (!activePlayer || !activePlayer.shuffleSupported)
            return;
        activePlayer.shuffle = !activePlayer.shuffle;
    }
    function setVolume(vol) {
        if (!activePlayer || !activePlayer.volumeSupported)
            return;
        activePlayer.volume = Math.max(0, Math.min(vol, 1));
    }
    function formatTime(seconds) {
        if (!seconds || isNaN(seconds) || !isFinite(seconds) || seconds < 0)
            return "0:00";
        var m = Math.floor(seconds / 60);
        var s = Math.floor(seconds % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    // ═══════════════════════════════════════════
    // PLAYER TRACKING
    // ═══════════════════════════════════════════

    // Watch each player — auto-switch when one starts playing
    Instantiator {
        model: Mpris.players
        delegate: Connections {
            required property var modelData
            target: modelData
            function onPlaybackStateChanged() {
                if (modelData.isPlaying && !root._selectedPlayer)
                    root._autoPlayer = modelData;
            }
        }
    }

    // Handle players appearing / disappearing
    Connections {
        target: Mpris.players
        function onValuesChanged() {
            root._syncAutoPlayer();
        }
        Component.onCompleted: {
            root._syncAutoPlayer();
        }
    }

    function _syncAutoPlayer() {
        if (root._autoPlayer && !Mpris.players.values.includes(root._autoPlayer))
            root._autoPlayer = null;
        if (root._selectedPlayer && !Mpris.players.values.includes(root._selectedPlayer))
            root._selectedPlayer = null;
        if (!root._autoPlayer && Mpris.players.values.length > 0) {
            for (var i = 0; i < Mpris.players.values.length; i++) {
                var p = Mpris.players.values[i];
                if (p.isPlaying) {
                    root._autoPlayer = p;
                    return;
                }
            }
            root._autoPlayer = Mpris.players.values[0];
        }
    }

    // ═══════════════════════════════════════════
    // POSITION TRACKING
    // ═══════════════════════════════════════════
    Timer {
        interval: 1000
        repeat: true
        running: root.activePlayer !== null && root.playing
        onTriggered: {
            if (root.activePlayer)
                root.activePlayer.positionChanged();
        }
    }
}
