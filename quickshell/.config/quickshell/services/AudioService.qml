pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    // ═══════════════════════════════════════════
    // MASTER VOLUME (default sink)
    // ═══════════════════════════════════════════
    readonly property real volume: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    readonly property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false
    readonly property bool available: Pipewire.ready

    function getVolumeIcon() {
        if (muted || volume === 0)
            return "󰝟";
        if (volume < 0.33)
            return "󰕿";
        if (volume < 0.66)
            return "󰖀";
        return "󰕾";
    }

    function setVolume(vol) {
        if (!available || !Pipewire.defaultAudioSink?.audio)
            return;
        Pipewire.defaultAudioSink.audio.volume = Math.max(0, Math.min(vol, 1.5));
    }

    function toggleMute() {
        if (!available || !Pipewire.defaultAudioSink?.audio)
            return;
        Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
    }

    function increaseVolume() {
        setVolume(volume + 0.05);
    }

    function decreaseVolume() {
        setVolume(volume - 0.05);
    }

    // ═══════════════════════════════════════════
    // MIXER — audio sinks & linked streams
    // ═══════════════════════════════════════════

    // All audio output devices (sinks)
    readonly property var sinks: {
        var result = [];
        var nodes = Pipewire.nodes.values;
        for (var i = 0; i < nodes.length; i++) {
            var n = nodes[i];
            if (n.audio && n.isSink && !n.isStream)
                result.push(n);
        }
        return result;
    }

    // App streams linked to the default sink
    readonly property var linkedStreams: {
        var result = [];
        var groups = sinkLinkTracker.linkGroups;
        for (var i = 0; i < groups.length; i++) {
            var g = groups[i];
            // For sinks: the source of the link is the app producing audio
            var sourceNode = g.source;
            if (sourceNode && sourceNode.audio && sourceNode.isStream)
                result.push(sourceNode);
        }
        return result;
    }

    // Set volume on an arbitrary node (used by per-app mixer)
    function setNodeVolume(node, vol) {
        if (node?.audio)
            node.audio.volume = Math.max(0, Math.min(vol, 1.5));
    }

    // Toggle mute on an arbitrary node
    function toggleNodeMute(node) {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    // Switch the default audio output device
    function setDefaultSink(node) {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    // Get a display name for a stream node
    function getNodeName(node) {
        if (!node)
            return "Unknown";
        var appName = node.properties["application.name"];
        var mediaName = node.properties["media.name"];
        var desc = node.description;
        var name = appName || (desc ? desc : node.name);
        return mediaName ? name + " — " + mediaName : name;
    }

    // ═══════════════════════════════════════════
    // PIPEWIRE OBJECT TRACKING
    // ═══════════════════════════════════════════

    // Bind the default sink so its audio properties become reactive
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    // Track links on the default sink to discover connected app streams
    PwNodeLinkTracker {
        id: sinkLinkTracker
        node: Pipewire.defaultAudioSink
    }

    // Bind all linked streams so their audio properties update reactively
    PwObjectTracker {
        objects: linkedStreams
    }
}
